#ifndef LLAMA_INFERENCE_H
#define LLAMA_INFERENCE_H

#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <vector>
#include <string>
#include <memory>

// 前向声明llama.cpp类型
struct llama_model;
struct llama_context;
struct llama_model_params;
struct llama_context_params;
struct llama_sampler;
struct llama_batch;
typedef int32_t llama_token;

namespace godot {

class LlamaInference : public Node {
    GDCLASS(LlamaInference, Node)

private:
    // llama.cpp相关指针
    llama_model* model;
    llama_context* context;
    llama_sampler* sampler;
    
    bool initialized;
    bool is_busy;
    
    // GPU/CPU状态
    bool use_gpu;
    bool gpu_available;
    int gpu_layers;  // 卸载到GPU的层数，-1表示全部
    
    // 配置参数
    String model_path;
    int context_size;
    int max_tokens;
    float temperature;
    int threads;
    
    // 自定义提示词配置（混合模式）
    String custom_system_prompt;   // 如果设置了就用这个，否则从文件读取
    String custom_grammar_content; // 如果设置了就用这个，否则从文件读取
    bool use_custom_config;        // 标记是否使用自定义配置
    
    // 辅助方法
    bool detect_gpu();
    bool try_load_gpu(const char* path);
    bool try_load_cpu(const char* path);
    std::string generate_text(const std::string& prompt);
    std::string load_grammar_content();  // 加载grammar内容（文件或自定义）

protected:
    static void _bind_methods();

public:
    LlamaInference();
    ~LlamaInference();

    // Godot可调用方法
    bool load_model(const String& path);
    String infer(const String& prompt);
    bool is_model_loaded() const;
    bool is_inferring() const;
    void unload_model();
    
    // 配置方法
    void set_context_size(int size);
    int get_context_size() const;
    
    void set_max_tokens(int tokens);
    int get_max_tokens() const;
    
    void set_temperature(float temp);
    float get_temperature() const;
    
    void set_threads(int count);
    int get_threads() const;
    
    // GPU相关方法
    void set_gpu_layers(int layers);
    int get_gpu_layers() const;
    bool is_using_gpu() const;
    String get_device_info() const;
    
    // 自定义配置方法（混合模式）
    void set_system_prompt(const String& prompt);
    String get_system_prompt() const;
    
    void set_grammar_content(const String& grammar);
    String get_grammar_content() const;
    
    void clear_custom_config();  // 清除自定义配置，恢复使用文件
};

}

#endif // LLAMA_INFERENCE_H

