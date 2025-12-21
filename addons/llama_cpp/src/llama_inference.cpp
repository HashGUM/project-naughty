#include "llama_inference.h"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/classes/project_settings.hpp>
#include "../include/llama.h"
#include <fstream>
#include <sstream>

using namespace godot;

LlamaInference::LlamaInference() {
    model = nullptr;
    context = nullptr;
    sampler = nullptr;
    initialized = false;
    is_busy = false;
    
    // GPU/CPU状态
    use_gpu = false;
    gpu_available = false;
    gpu_layers = -1;  // 默认全部层卸载到GPU
    
    // 默认参数
    context_size = 2048;
    max_tokens = 256;
    temperature = 0.7f;
    threads = 4;
    
    // 自定义配置
    custom_system_prompt = "";
    custom_grammar_content = "";
    use_custom_config = false;
    
    // 初始化llama backend
    llama_backend_init();
}

LlamaInference::~LlamaInference() {
    unload_model();
    llama_backend_free();
}

void LlamaInference::_bind_methods() {
    // 绑定方法
    ClassDB::bind_method(D_METHOD("load_model", "path"), &LlamaInference::load_model);
    ClassDB::bind_method(D_METHOD("infer", "prompt"), &LlamaInference::infer);
    ClassDB::bind_method(D_METHOD("is_model_loaded"), &LlamaInference::is_model_loaded);
    ClassDB::bind_method(D_METHOD("is_inferring"), &LlamaInference::is_inferring);
    ClassDB::bind_method(D_METHOD("unload_model"), &LlamaInference::unload_model);
    
    // 配置属性
    ClassDB::bind_method(D_METHOD("set_context_size", "size"), &LlamaInference::set_context_size);
    ClassDB::bind_method(D_METHOD("get_context_size"), &LlamaInference::get_context_size);
    ClassDB::add_property("LlamaInference", PropertyInfo(Variant::INT, "context_size"), "set_context_size", "get_context_size");
    
    ClassDB::bind_method(D_METHOD("set_max_tokens", "tokens"), &LlamaInference::set_max_tokens);
    ClassDB::bind_method(D_METHOD("get_max_tokens"), &LlamaInference::get_max_tokens);
    ClassDB::add_property("LlamaInference", PropertyInfo(Variant::INT, "max_tokens"), "set_max_tokens", "get_max_tokens");
    
    ClassDB::bind_method(D_METHOD("set_temperature", "temp"), &LlamaInference::set_temperature);
    ClassDB::bind_method(D_METHOD("get_temperature"), &LlamaInference::get_temperature);
    ClassDB::add_property("LlamaInference", PropertyInfo(Variant::FLOAT, "temperature"), "set_temperature", "get_temperature");
    
    ClassDB::bind_method(D_METHOD("set_threads", "count"), &LlamaInference::set_threads);
    ClassDB::bind_method(D_METHOD("get_threads"), &LlamaInference::get_threads);
    ClassDB::add_property("LlamaInference", PropertyInfo(Variant::INT, "threads"), "set_threads", "get_threads");
    
    // GPU相关方法
    ClassDB::bind_method(D_METHOD("set_gpu_layers", "layers"), &LlamaInference::set_gpu_layers);
    ClassDB::bind_method(D_METHOD("get_gpu_layers"), &LlamaInference::get_gpu_layers);
    ClassDB::add_property("LlamaInference", PropertyInfo(Variant::INT, "gpu_layers"), "set_gpu_layers", "get_gpu_layers");
    
    ClassDB::bind_method(D_METHOD("is_using_gpu"), &LlamaInference::is_using_gpu);
    ClassDB::bind_method(D_METHOD("get_device_info"), &LlamaInference::get_device_info);
    
    // 信号
    ADD_SIGNAL(MethodInfo("inference_completed", PropertyInfo(Variant::STRING, "result")));
    ADD_SIGNAL(MethodInfo("inference_failed", PropertyInfo(Variant::STRING, "error")));
    
    // 自定义配置方法（混合模式）
    ClassDB::bind_method(D_METHOD("set_system_prompt", "prompt"), &LlamaInference::set_system_prompt);
    ClassDB::bind_method(D_METHOD("get_system_prompt"), &LlamaInference::get_system_prompt);
    
    ClassDB::bind_method(D_METHOD("set_grammar_content", "grammar"), &LlamaInference::set_grammar_content);
    ClassDB::bind_method(D_METHOD("get_grammar_content"), &LlamaInference::get_grammar_content);
    
    ClassDB::bind_method(D_METHOD("clear_custom_config"), &LlamaInference::clear_custom_config);
}

// GPU检测
bool LlamaInference::detect_gpu() {
    // 尝试检测CUDA设备
    // 注意：llama.cpp当前版本可能没有直接的GPU检测函数
    // 我们通过尝试加载模型到GPU来检测
    return true;  // 假设可用，实际在try_load_gpu中验证
}

// 加载grammar内容（混合模式）
std::string LlamaInference::load_grammar_content() {
    // 1. 如果设置了自定义grammar，优先使用
    if (!custom_grammar_content.is_empty()) {
        UtilityFunctions::print(String::utf8("✓ 使用自定义Grammar配置"));
        return std::string(custom_grammar_content.utf8().get_data());
    }
    
    // 2. 否则从默认文件读取
    String grammar_path = ProjectSettings::get_singleton()->globalize_path("res://prompt/cat_response.gbnf");
    std::string grammar_path_str = grammar_path.utf8().get_data();
    
    std::ifstream grammar_file(grammar_path_str);
    if (grammar_file.is_open()) {
        std::stringstream buffer;
        buffer << grammar_file.rdbuf();
        std::string content = buffer.str();
        grammar_file.close();
        
        UtilityFunctions::print(String::utf8("✓ Grammar文件加载成功: ") + grammar_path);
        return content;
    }
    
    UtilityFunctions::push_warning(String::utf8("⚠ 无法读取Grammar文件: ") + grammar_path);
    return "";
}

// GPU模型加载
bool LlamaInference::try_load_gpu(const char* path) {
    llama_model_params model_params = llama_model_default_params();
    model_params.n_gpu_layers = gpu_layers;  // 卸载层数到GPU
    
    model = llama_load_model_from_file(path, model_params);
    if (!model) {
        UtilityFunctions::push_warning("GPU model loading failed");
        return false;
    }
    
    llama_context_params ctx_params = llama_context_default_params();
    ctx_params.n_ctx = context_size;
    ctx_params.n_threads = threads;
    ctx_params.n_batch = 512;
    
    context = llama_new_context_with_model(model, ctx_params);
    if (!context) {
        llama_free_model(model);
        model = nullptr;
        UtilityFunctions::push_warning("GPU context creation failed");
        return false;
    }
    
    // 创建采样器链
    sampler = llama_sampler_chain_init(llama_sampler_chain_default_params());
    
    // 1. 先添加常规采样器（重要：必须在grammar之前）
    llama_sampler_chain_add(sampler, llama_sampler_init_temp(temperature));
    llama_sampler_chain_add(sampler, llama_sampler_init_top_k(40));
    llama_sampler_chain_add(sampler, llama_sampler_init_top_p(0.9, 1));
    
    // 2. 再添加Grammar约束（混合模式：自定义或文件）
    std::string json_grammar = load_grammar_content();
    
    if (!json_grammar.empty()) {
        // 初始化grammar sampler
        const llama_vocab* vocab = llama_model_get_vocab(model);
        struct llama_sampler* grammar_sampler = llama_sampler_init_grammar(vocab, json_grammar.c_str(), "root");
        
        if (grammar_sampler) {
            llama_sampler_chain_add(sampler, grammar_sampler);
            UtilityFunctions::print(String::utf8("✓ JSON Grammar约束已启用"));
        } else {
            UtilityFunctions::push_warning(String::utf8("⚠ JSON Grammar初始化失败，将不使用格式约束"));
        }
    } else {
        UtilityFunctions::push_warning(String::utf8("⚠ Grammar内容为空，将不使用格式约束"));
    }
    
    // 3. 最后添加分布采样器
    llama_sampler_chain_add(sampler, llama_sampler_init_dist(0));
    
    UtilityFunctions::print(String::utf8("✓ GPU模型加载成功"));
    return true;
}

// CPU模型加载
bool LlamaInference::try_load_cpu(const char* path) {
    llama_model_params model_params = llama_model_default_params();
    model_params.n_gpu_layers = 0;  // 强制CPU
    
    model = llama_load_model_from_file(path, model_params);
    if (!model) {
        UtilityFunctions::push_error("CPU model loading failed");
        return false;
    }
    
    llama_context_params ctx_params = llama_context_default_params();
    ctx_params.n_ctx = context_size;
    ctx_params.n_threads = threads;
    ctx_params.n_batch = 512;
    
    context = llama_new_context_with_model(model, ctx_params);
    if (!context) {
        llama_free_model(model);
        model = nullptr;
        UtilityFunctions::push_error("CPU context creation failed");
        return false;
    }
    
    // 创建采样器链
    sampler = llama_sampler_chain_init(llama_sampler_chain_default_params());
    
    // 1. 先添加常规采样器（重要：必须在grammar之前）
    llama_sampler_chain_add(sampler, llama_sampler_init_temp(temperature));
    llama_sampler_chain_add(sampler, llama_sampler_init_top_k(40));
    llama_sampler_chain_add(sampler, llama_sampler_init_top_p(0.9, 1));
    
    // 2. 再添加Grammar约束（混合模式：自定义或文件）
    std::string json_grammar = load_grammar_content();
    
    if (!json_grammar.empty()) {
        // 初始化grammar sampler
        const llama_vocab* vocab = llama_model_get_vocab(model);
        struct llama_sampler* grammar_sampler = llama_sampler_init_grammar(vocab, json_grammar.c_str(), "root");
        
        if (grammar_sampler) {
            llama_sampler_chain_add(sampler, grammar_sampler);
            UtilityFunctions::print(String::utf8("✓ JSON Grammar约束已启用"));
        } else {
            UtilityFunctions::push_warning(String::utf8("⚠ JSON Grammar初始化失败，将不使用格式约束"));
        }
    } else {
        UtilityFunctions::push_warning(String::utf8("⚠ Grammar内容为空，将不使用格式约束"));
    }
    
    // 3. 最后添加分布采样器
    llama_sampler_chain_add(sampler, llama_sampler_init_dist(0));
    
    UtilityFunctions::print(String::utf8("✓ CPU模型加载成功"));
    return true;
}

bool LlamaInference::load_model(const String& path) {
    if (initialized) {
        UtilityFunctions::push_warning("Model already loaded");
        return false;
    }
    
    model_path = path;
    
    // 转换路径
    String abs_path = ProjectSettings::get_singleton()->globalize_path(path);
    std::string path_str = abs_path.utf8().get_data();
    
    UtilityFunctions::print(String::utf8("LlamaInference: 加载模型 - ") + abs_path);
    
    // 1. 尝试GPU加载（如果gpu_layers > 0）
    if (gpu_layers != 0) {
        gpu_available = detect_gpu();
        if (gpu_available) {
            UtilityFunctions::print(String::utf8("尝试GPU推理..."));
            if (try_load_gpu(path_str.c_str())) {
                use_gpu = true;
                initialized = true;
                return true;
            }
            UtilityFunctions::push_warning(String::utf8("GPU加载失败，降级到CPU"));
        }
    }
    
    // 2. 降级到CPU或用户强制CPU模式
    UtilityFunctions::print(String::utf8("使用CPU推理..."));
    if (try_load_cpu(path_str.c_str())) {
        use_gpu = false;
        initialized = true;
        return true;
    }
    
    UtilityFunctions::push_error("Model loading failed");
    return false;
}

// 文本生成核心函数
std::string LlamaInference::generate_text(const std::string& prompt) {
    // 获取vocab
    const llama_vocab* vocab = llama_model_get_vocab(model);
    
    // Token化输入
    std::vector<llama_token> tokens;
    tokens.resize(prompt.size() + 1);
    int n_tokens = llama_tokenize(vocab, prompt.c_str(), prompt.size(), tokens.data(), tokens.size(), true, false);
    tokens.resize(n_tokens);
    
    if (n_tokens < 0) {
        UtilityFunctions::push_error(String::utf8("Token化失败"));
        return "";
    }
    
    UtilityFunctions::print(String::utf8("Token化成功，token数: ") + String::num_int64(n_tokens));
    
    // 创建批处理
    llama_batch batch = llama_batch_get_one(tokens.data(), tokens.size());
    
    // 评估prompt
    if (llama_decode(context, batch) != 0) {
        UtilityFunctions::push_error(String::utf8("模型解码失败"));
        return "";
    }
    
    UtilityFunctions::print(String::utf8("Prompt评估完成，开始生成..."));
    
    // 生成循环
    std::string result;
    int n_cur = tokens.size();
    int n_gen = 0;
    
    // 停止符（纯文本格式）
    const std::vector<std::string> stop_strings = {
        "\n用户:",
        "\nUser:",
        "\n\n",
        "</s>",
        "<|endoftext|>"
    };
    
    while (n_gen < max_tokens) {
        // 采样下一个token
        llama_token new_token = llama_sampler_sample(sampler, context, -1);
        
        // 🔍 先检查是否是EOG token（在解码之前）
        if (llama_token_is_eog(vocab, new_token)) {
            UtilityFunctions::print(String::utf8("遇到EOG token (ID: ") + String::num_int64(new_token) + String::utf8(")，停止生成"));
            break;
        }
        
        // 解码token为文本
        char buf[256];
        int n = llama_token_to_piece(vocab, new_token, buf, sizeof(buf), 0, false);
        if (n > 0) {
            result.append(buf, n);
        }
        
        // 检查是否包含停止符（字符串层面检查）
        bool should_stop = false;
        for (const auto& stop_str : stop_strings) {
            size_t pos = result.find(stop_str);
            if (pos != std::string::npos) {
                // 找到停止符，移除它并停止生成
                UtilityFunctions::print(String::utf8("遇到停止符: ") + String::utf8(stop_str.c_str()));
                result = result.substr(0, pos);
                should_stop = true;
                break;
            }
        }
        
        if (should_stop) {
            break;
        }
        
        // 继续生成
        batch = llama_batch_get_one(&new_token, 1);
        if (llama_decode(context, batch) != 0) {
            UtilityFunctions::push_error(String::utf8("生成过程中解码失败"));
            break;
        }
        
        n_gen++;
    }
    
    UtilityFunctions::print(String::utf8("生成完成，生成了 ") + String::num_int64(n_gen) + String::utf8(" 个token"));
    UtilityFunctions::print(String::utf8("原始生成内容: [") + String::utf8(result.c_str()) + String::utf8("]"));
    UtilityFunctions::print(String::utf8("内容长度: ") + String::num_int64(result.length()));
    
    return result;
}

String LlamaInference::infer(const String& prompt) {
    if (!initialized) {
        UtilityFunctions::push_error("Model not loaded");
        emit_signal("inference_failed", String::utf8("模型未加载"));
        return "";
    }
    
    if (is_busy) {
        UtilityFunctions::push_warning("Inference already in progress");
        return "";
    }
    
    is_busy = true;
    
    // 转换prompt
    std::string prompt_str = prompt.utf8().get_data();
    
    // 获取system prompt（混合模式）
    std::string system_prompt;
    
    if (!custom_system_prompt.is_empty()) {
        // 使用自定义system prompt
        system_prompt = std::string(custom_system_prompt.utf8().get_data());
        UtilityFunctions::print(String::utf8("✓ 使用自定义System Prompt"));
    } else {
        // 从文件读取system prompt
        String system_prompt_path = ProjectSettings::get_singleton()->globalize_path("res://prompt/system_prompt.txt");
        std::string system_prompt_str = system_prompt_path.utf8().get_data();
        
        std::ifstream system_file(system_prompt_str);
        system_prompt = "你是一只猫。请用JSON格式回复。";  // 默认值
        
        if (system_file.is_open()) {
            std::stringstream buffer;
            buffer << system_file.rdbuf();
            system_prompt = buffer.str();
            system_file.close();
            UtilityFunctions::print(String::utf8("✓ 从文件读取System Prompt"));
        } else {
            UtilityFunctions::push_warning(String::utf8("⚠ 无法读取System Prompt文件，使用默认值"));
        }
    }
    
    // 构建完整prompt
    std::string full_prompt = system_prompt + "\n用户: " + prompt_str + "\n回答:";
    
    UtilityFunctions::print(String::utf8("推理中..."));
    UtilityFunctions::print(String::utf8("Prompt长度: ") + String::num_int64(full_prompt.length()));
    UtilityFunctions::print(String::utf8("=== 完整Prompt ==="));
    UtilityFunctions::print(String::utf8(full_prompt.c_str()));
    UtilityFunctions::print(String::utf8("=== Prompt结束 ==="));
    
    // 调用llama.cpp生成
    std::string result = generate_text(full_prompt);
    
    is_busy = false;
    
    // 检查生成结果
    if (result.empty()) {
        UtilityFunctions::push_warning(String::utf8("模型生成了空回复"));
        String empty_msg = String::utf8("{}");
        emit_signal("inference_completed", empty_msg);
        return empty_msg;
    }
    
    // ========== 清理结果 ==========
    std::string cleaned_result = result;
    
    // 1. 移除所有停止符和特殊标记
    const std::vector<std::string> cleanup_strings = {
        "</s>",
        "<|endoftext|>",
        "<|end|>",
        "<|im_end|>",
        "<|im_start|>assistant",
        "<|im_start|>",
        "\n用户:",
        "\nUser:",
        "\n助手:",
        "\nAssistant:"
    };
    
    for (const auto& cleanup_str : cleanup_strings) {
        size_t pos = 0;
        while ((pos = cleaned_result.find(cleanup_str, pos)) != std::string::npos) {
            cleaned_result.erase(pos, cleanup_str.length());
        }
    }
    
    // 2. 移除开头的空白和多余符号
    while (!cleaned_result.empty() && 
           (cleaned_result[0] == ' ' || cleaned_result[0] == '\n' || 
            cleaned_result[0] == '\r' || cleaned_result[0] == '\t' ||
            cleaned_result[0] == '[')) {
        cleaned_result.erase(0, 1);
    }
    
    // 3. 移除结尾的空白和多余符号
    while (!cleaned_result.empty() && 
           (cleaned_result.back() == ' ' || cleaned_result.back() == '\n' || 
            cleaned_result.back() == '\r' || cleaned_result.back() == '\t' ||
            cleaned_result.back() == ']')) {
        cleaned_result.pop_back();
    }
    
    // 4. 验证结果不为空
    if (cleaned_result.empty()) {
        UtilityFunctions::push_warning(String::utf8("清理后结果为空"));
        String empty_msg = String::utf8("{}");
        emit_signal("inference_completed", empty_msg);
        return empty_msg;
    }
    
    String godot_result = String::utf8(cleaned_result.c_str());
    emit_signal("inference_completed", godot_result);
    
    UtilityFunctions::print(String::utf8("✓ 推理完成，清理后长度: ") + String::num_int64(cleaned_result.length()));
    
    return godot_result;
}

bool LlamaInference::is_model_loaded() const {
    return initialized;
}

bool LlamaInference::is_inferring() const {
    return is_busy;
}

void LlamaInference::unload_model() {
    if (!initialized) return;
    
    UtilityFunctions::print(String::utf8("LlamaInference: 卸载模型"));
    
    // 释放资源
    if (sampler) {
        llama_sampler_free(sampler);
        sampler = nullptr;
    }
    if (context) {
        llama_free(context);
        context = nullptr;
    }
    if (model) {
        llama_free_model(model);
        model = nullptr;
    }
    
    initialized = false;
    is_busy = false;
    use_gpu = false;
}

// 配置方法实现
void LlamaInference::set_context_size(int size) {
    context_size = size;
}

int LlamaInference::get_context_size() const {
    return context_size;
}

void LlamaInference::set_max_tokens(int tokens) {
    max_tokens = tokens;
}

int LlamaInference::get_max_tokens() const {
    return max_tokens;
}

void LlamaInference::set_temperature(float temp) {
    temperature = temp;
}

float LlamaInference::get_temperature() const {
    return temperature;
}

void LlamaInference::set_threads(int count) {
    threads = count;
}

int LlamaInference::get_threads() const {
    return threads;
}

// GPU相关方法实现
void LlamaInference::set_gpu_layers(int layers) {
    if (initialized) {
        UtilityFunctions::push_warning("Cannot change GPU layers while model is loaded");
        return;
    }
    gpu_layers = layers;
}

int LlamaInference::get_gpu_layers() const {
    return gpu_layers;
}

bool LlamaInference::is_using_gpu() const {
    return use_gpu;
}

String LlamaInference::get_device_info() const {
    if (!initialized) {
        return String::utf8("模型未加载");
    }
    
    if (use_gpu) {
        return String::utf8("GPU (") + String::num(gpu_layers) + String::utf8(" 层)");
    } else {
        return String::utf8("CPU (") + String::num(threads) + String::utf8(" 线程)");
    }
}

// 自定义配置方法实现（混合模式）
void LlamaInference::set_system_prompt(const String& prompt) {
    custom_system_prompt = prompt;
    use_custom_config = !prompt.is_empty() || !custom_grammar_content.is_empty();
    
    if (!prompt.is_empty()) {
        UtilityFunctions::print(String::utf8("✓ 自定义System Prompt已设置"));
    }
}

String LlamaInference::get_system_prompt() const {
    return custom_system_prompt;
}

void LlamaInference::set_grammar_content(const String& grammar) {
    custom_grammar_content = grammar;
    use_custom_config = !custom_system_prompt.is_empty() || !grammar.is_empty();
    
    if (!grammar.is_empty()) {
        UtilityFunctions::print(String::utf8("✓ 自定义Grammar已设置"));
    }
    
    // 如果模型已加载，需要提示重新加载
    if (initialized) {
        UtilityFunctions::push_warning(String::utf8("⚠ Grammar已更改，需要重新加载模型才能生效"));
    }
}

String LlamaInference::get_grammar_content() const {
    return custom_grammar_content;
}

void LlamaInference::clear_custom_config() {
    custom_system_prompt = "";
    custom_grammar_content = "";
    use_custom_config = false;
    
    UtilityFunctions::print(String::utf8("✓ 已清除自定义配置，将使用默认文件"));
    
    if (initialized) {
        UtilityFunctions::push_warning(String::utf8("⚠ 配置已清除，需要重新加载模型才能生效"));
    }
}

