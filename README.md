# 🐱 Godot AI猫 - 基于llama.cpp的本地AI游戏

> 一个将本地LLM推理引擎无缝集成到Godot游戏引擎的完整示例项目

## ✨ 项目亮点

- 🚀 **真实AI推理**：使用llama.cpp在游戏内实时运行SLM
- 🎮 **零外部依赖**：无需Python、API或网络，纯Godot+GDExtension
- ⚡ **GPU加速**：支持CUDA加速，自动降级到CPU
- 🌏 **中文优化**：完整的UTF-8支持，针对中文场景优化
- 🎯 **游戏优化**：异步推理、设备检测、配置灵活

## 🎊 当前状态：3D白盒原型完成！

**llama.cpp GDExtension集成已完成并测试通过！**  
**3D白盒场景原型已完成并可运行！**  
**AI约束和输出优化已完成！**

✅ llama.cpp推理引擎集成完成
✅ GPU/CPU双模式运行
✅ 中文输入输出无乱码
✅ 3D导航寻路系统
✅ 交互事件系统
✅ AI/规则双模式切换
✅ 严格JSON Grammar约束（防止LLM多余输出）
✅ 双重保护机制（C++清理 + GDScript正则）

查看详细报告：[FEATURE_COMPLETE.md](docs/FEATURE_COMPLETED.md)

## 🚀 5分钟快速开始

### 方式1：测试AI推理引擎

1. **打开项目**
   - 使用 Godot 4.5+ 打开 `project.godot`
   - 打开测试场景：`scenes/test_gdextension.tscn`
   - 按 `F6` 运行场景

2. **测试推理**
   ```
   1. 点击"加载模型"
   2. 等待模型加载完成（5-10秒，显示GPU/CPU信息）
   3. 在输入框输入提示词，如："猫咪现在想做什么？"
   4. 点击"开始推理"
   5. 查看输出结果
   ```

### 方式2：体验3D白盒原型（推荐）

1. **打开3D场景**
   - 打开场景：`scenes/3d_world/main_3d.tscn`
   - 按 `F5` 运行

2. **控制猫咪移动**
   ```
   输入命令：
   - 去小屋
   - 去花园
   - 回中心
   
   相机操作：
   - 鼠标中键拖拽：旋转视角
   - 滚轮：缩放
   ```

3. **（可选）启用AI模式**
   - 选择场景根节点 `Main3D`
   - 在Inspector中勾选 `use_ai`
   - 重新运行（首次加载需5-10秒）
   - 可以使用自然语言命令

**就是这么简单！** 🎉

详细使用说明见：[scenes/3d_world/README.md](scenes/3d_world/README.md)

## 📦 项目结构

```
project-naughty/
├── addons/llama_cpp/              # 🔌 GDExtension核心
│   ├── src/                       # C++源代码
│   │   ├── llama_inference.h      # LlamaInference类定义
│   │   ├── llama_inference.cpp    # 推理引擎实现
│   │   └── register_types.*       # GDExtension注册
│   ├── bin/                       # DLL文件
│   │   ├── libllama_godot.*.dll   # GDExtension
│   │   └── llama*.dll, ggml*.dll  # llama.cpp依赖
│   ├── include/                   # llama.cpp头文件
│   ├── godot-cpp/                 # Godot C++绑定
│   ├── build.ps1                  # 一键构建脚本
│   ├── rebuild.ps1                # 快速重建脚本
│   └── SETUP.md                   # 详细编译指南
│
├── scenes/                        # 🎬 场景文件
│   ├── test_gdextension.tscn      # AI推理测试场景
│   ├── test_gdextension.gd        # 测试脚本
│   └── 3d_world/                  # 🎮 3D原型场景
│       ├── main_3d.tscn           # 主3D场景
│       └── README.md              # 3D场景使用说明
│
├── scripts/                       # 📜 GDScript脚本
│   ├── ai_controller_3d.gd        # AI控制器（含配置）
│   ├── main_3d.gd                 # 主场景控制器
│   ├── cat_3d.gd                  # 猫咪移动控制
│   ├── camera_3d.gd               # 相机控制
│   └── interaction_area.gd        # 交互区域
│
├── models/                        # 🧠 AI模型
│   └── qwen3-0.6b-q4_k_m.gguf     # 示例模型
│
├── docs/                          # 📚 文档
│   ├── FEATURE_COMPLETED.md       # 功能完成报告
│   ├── NEXT_PHASE_PLAN.md         # 下一阶段计划
│   └── DOCS_INDEX.md              # 文档索引
│
├── README.md                      # 📖 本文档
├── SLM_MODEL_RECOMMENDATIONS.md   # 📊 模型推荐
├── TEST_GUIDE.md                  # 🧪 测试指南
├── DISTRIBUTION_GUIDE.md          # 📦 分发指南
└── INTEGRATION_COMPLETE.md        # 🔧 技术集成细节
```

## 💻 核心API

### GDScript使用示例

```gdscript
extends Node

var llama: LlamaInference

func _ready():
    # 1. 创建推理节点
    llama = ClassDB.instantiate("LlamaInference")
    add_child(llama)
    
    # 2. 🎯 直接配置System Prompt和Grammar
    llama.call("set_system_prompt", SYSTEM_PROMPT)
    llama.call("set_grammar_content", JSON_GRAMMAR)
    
    # 3. 连接信号
    llama.inference_completed.connect(_on_inference_completed)
    llama.inference_failed.connect(_on_inference_failed)
    
    # 4. 配置GPU（可选）
    llama.set_gpu_layers(-1)  # -1=全GPU, 0=纯CPU
    
    # 5. 加载模型
    if llama.load_model("res://models/qwen3-0.6b-q4_k_m.gguf"):
        print("模型加载成功！")
        print("设备: ", llama.get_device_info())
        
        # 6. 开始推理
        llama.infer("猫咪想要玩耍")

func _on_inference_completed(result: String):
    print("AI回复: ", result)
    var data = JSON.parse_string(result)
    # 处理AI生成的JSON指令...

func _on_inference_failed(error: String):
    print("推理失败: ", error)
```

## 🎯 AI配置：简洁直接的提示词配置

### 配置方式

直接在`./scripts/ai_controller_3d.gd`处配置：

**直接配置（当前方式）**
```gdscript
# 在 scripts/ai_controller_3d.gd 中定义
const SYSTEM_PROMPT = """你的系统提示词..."""
const JSON_GRAMMAR = """root ::= cat-response
cat-response ::= "{"
  "\\"location\\"" ":" location-value ","
  "\\"action\\"" ":" action-value ","
  "\\"meow\\"" ":" meow-value
"}"
..."""

# 直接设置
llama.call("set_system_prompt", SYSTEM_PROMPT)
llama.call("set_grammar_content", JSON_GRAMMAR)
llama.call("load_model", model_path)
```

### Grammar约束优化

> 目前还是有不小概率出现思考输出，不过也不坏不是么，看着还行

**严格模式GBNF**（防止LLM生成额外内容）：
- ❌ 移除所有可选空白符 (`ws`)
- ✅ 严格的字段枚举值
- ✅ JSON结构完成后立即终止
- ✅ 配合正则fallback确保解析成功


**双重保护机制**：
1. **C++层**：采样器链优化 + 停止符检测
2. **GDScript层**：正则提取JSON，过滤多余文本

### 主要方法

| 方法 | 说明 |
|------|------|
| `load_model(path: String)` | 加载GGUF模型 |
| `infer(prompt: String)` | 执行推理（异步） |
| `unload_model()` | 卸载模型释放内存 |
| `is_model_loaded()` | 检查模型是否已加载 |
| `is_inferring()` | 检查是否正在推理 |
| `set_gpu_layers(layers: int)` | 设置GPU层数 |
| `get_device_info()` | 获取设备信息 |

### 可配置参数

```gdscript
llama.set_context_size(2048)      # 上下文窗口大小
llama.set_max_tokens(256)         # 最大生成token数
llama.set_temperature(0.7)        # 采样温度（0-1）
llama.set_threads(4)              # CPU线程数
llama.set_gpu_layers(-1)          # GPU层数（-1=全部）

# 系统提示词及GBNF配置
llama.call("set_system_prompt", "自定义提示词")
llama.call("set_grammar_content", "grammar内容")
llama.call("clear_custom_config")  # 清除自定义，恢复文件
```

### 信号

```gdscript
signal inference_completed(result: String)  # 推理完成
signal inference_failed(error: String)      # 推理失败
```

## 🏗️ 重新编译指南

如果你修改了C++源代码，需要重新编译GDExtension：

### 方法1：自动化脚本（推荐）

```powershell
# 1. 关闭Godot编辑器
# 2. 运行重建脚本
cd addons\llama_cpp
.\rebuild.ps1
# 3. 重新打开Godot测试
```

### 方法2：手动编译

```powershell
cd addons\llama_cpp
python -m SCons platform=windows target=template_debug
```

首次设置详见：[addons/llama_cpp/SETUP.md](addons/llama_cpp/SETUP.md)

## 🎮 技术架构

```
┌─────────────────────────────────┐
│   Godot GDScript 游戏逻辑      │  ← 你的游戏代码
│   (AI猫咪行为、UI等)           │
└─────────────────────────────────┘
           ↕ GDExtension API
┌─────────────────────────────────┐
│   LlamaInference C++ Class      │  ← GDExtension层
│   (异步推理、设备管理)         │
└─────────────────────────────────┘
           ↕ llama.cpp API
┌─────────────────────────────────┐
│     llama.cpp Library           │  ← 推理引擎
│  (GGUF模型、CUDA/CPU后端)      │
└─────────────────────────────────┘
           ↕ 硬件抽象
┌─────────────────────────────────┐
│      GPU (CUDA) / CPU           │  ← 硬件层
└─────────────────────────────────┘
```

**关键特性：**
- ⚡ GPU优先，CPU自动降级
- 🔄 异步推理，不阻塞游戏主循环
- 🌐 UTF-8中文完美支持
- 📦 单一DLL，无额外依赖

## 📚 文档导航

### 核心文档
| 文档 | 内容 |
|------|------|
| [docs/FEATURE_COMPLETED.md](docs/FEATURE_COMPLETED.md) | 完整feature报告、技术总结 |
| [docs/NEXT_PHASE_PLAN.md](docs/NEXT_PHASE_PLAN.md) | 下一阶段开发计划 |
| [scenes/3d_world/README.md](scenes/3d_world/README.md) | 3D场景使用说明 |
| [addons/llama_cpp/SETUP.md](addons/llama_cpp/SETUP.md) | 首次编译环境设置 |

## 🧪 测试结果

✅ **测试环境**
- OS: Windows 11
- GPU: NVIDIA GeForce RTX 5070 Ti
- Godot: 4.5.1 stable
- 编译器: MinGW-w64 (GCC)

✅ **测试通过**
- GPU推理正常
- CPU降级正常
- 中文输入输出无乱码
- 异步信号机制正常
- UI布局正确

典型输出：
```
LlamaInference: 加载模型 - E:/Godot/project-naughty/models/qwen3-0.6b-q4_k_m.gguf
尝试GPU推理...
✓ GPU模型加载成功
推理中...
推理完成，生成长度: 954
```

## 📦 游戏分发

导出游戏时需要包含以下文件：

**必需（所有平台）**：
```
game.exe
libllama_godot.*.dll
llama.dll
ggml-base.dll, ggml-cpu.dll, ggml.dll
mtmd.dll
models/*.gguf
```

**可选（GPU版本）**：
```
ggml-cuda.dll
cudart64_*.dll (CUDA运行时)
```

**分发策略**：
- 通用版：仅CPU DLL（适合所有用户）
- 性能版：包含GPU DLL（需要NVIDIA显卡）
- 智能版：同时包含，运行时自动选择

## 🎓 技术亮点与经验

### 解决的关键问题

1. **UTF-8编码**
   - 问题：C++ `std::string` → Godot `String` 中文乱码
   - 解决：使用 `String::utf8()` 显式转换
   ```cpp
   // ✅ 正确方式
   emit_signal("inference_completed", String::utf8(result.c_str()));
   ```

2. **DLL锁定**
   - 问题：Godot运行时锁定DLL，无法重新编译
   - 解决：提供自动化脚本检测进程并提示

3. **GPU降级**
   - 问题：GPU不可用时推理失败
   - 解决：GPU优先尝试，失败自动降级到CPU

4. **异步架构**
   - 问题：推理阻塞游戏主线程
   - 解决：使用Godot信号实现异步回调

### 性能优化

- **模型选择**：0.5B-1.5B模型适合实时游戏
- **量化策略**：Q4_K_M平衡质量和速度
- **GPU加速**：RTX系列GPU可显著提升推理速度
- **批处理**：llama.cpp内部优化，无需手动实现

## 🔮 下一步开发

推理引擎和3D原型已就绪，现在可以继续完善AI猫咪功能：

### 🎯 当前进度

```
✅ llama.cpp推理引擎完成
✅ 3D白盒原型完成
   ├── ✅ 导航寻路系统
   ├── ✅ 交互事件系统
   ├── ✅ 相机控制
   └── ✅ AI/规则双模式

🎯 下一步：完善猫咪行为
   ├── 添加更多动作类型
   ├── 实现状态系统
   ├── 优化AI提示词
   └── 数据收集与微调
```

### 📋 详细开发计划

查看：**[docs/NEXT_PHASE_PLAN.md](docs/NEXT_PHASE_PLAN.md)** ⭐

**核心模块：**

1. **猫咪动画系统**
   - 替换白盒为美术资源
   - 添加更多动画状态
   - 实现动画混合

2. **状态系统**
   - 饥饿度、疲劳度、心情
   - 自主行为逻辑
   - 状态影响AI回复

3. **AI优化**
   - 改进提示词工程
   - 添加记忆系统
   - 优化JSON解析

4. **（可选）LoRA微调**
   - 训练数据生成
   - 模型微调
   - "猫化"个性注入

### 🚀 立即可做的事情

1. **测试当前系统**
   ```bash
   # 运行3D场景
   打开 scenes/3d_world/main_3d.tscn
   输入命令测试移动
   ```

2. **添加新位置**
   ```gdscript
   # 在 scripts/main_3d.gd 中添加
   var locations = {
       "house": Vector3(6, 0.5, 6),
       "garden": Vector3(-6, 0.5, -6),
       "pond": Vector3(8, 0.5, -8),  # 新增池塘
   }
   ```

3. **调整AI提示词**
   ```gdscript
   # 在 scripts/ai_controller_3d.gd 中优化
   func build_prompt(command: String) -> String:
       # 改进提示词，让AI理解更准确
   ```

## 🆘 常见问题

### Q: 编译时找不到编译器
**A**: 需要安装MinGW-w64或Visual Studio，详见 `addons/llama_cpp/SETUP.md`

### Q: 模型加载失败
**A**: 
1. 确认模型是GGUF格式
2. 检查路径是否正确（使用 `res://` 或绝对路径）
3. 查看Godot输出面板的错误信息

### Q: GPU推理失败
**A**: 
1. 确认有NVIDIA GPU和CUDA驱动
2. 检查 `ggml-cuda.dll` 是否存在
3. 系统会自动降级到CPU，不影响使用

### Q: 中文显示乱码
**A**: 
1. 确认使用的是最新编译的DLL
2. 检查是否调用了 `rebuild.ps1` 重新编译
3. 确保Godot完全关闭后再编译

### Q: 推理速度慢
**A**: 
1. 检查是否使用GPU模式（`llama.get_device_info()`）
2. 尝试更小的模型（0.5B vs 1.5B）
3. 降低 `max_tokens` 参数
4. 增加 `threads` 数量（CPU模式）

## 🤝 贡献与致谢

**依赖项致谢：**
- [llama.cpp](https://github.com/ggerganov/llama.cpp) - 高性能LLM推理库
- [godot-cpp](https://github.com/godotengine/godot-cpp) - Godot C++绑定
- [Qwen](https://github.com/QwenLM/Qwen) - 阿里云通义千问模型

**开源许可：**
- llama.cpp: MIT License
- godot-cpp: MIT License
- Godot Engine: MIT License

## 📞 联系方式

- 项目Issues: [GitHub Issues](your-repo/issues)
- 讨论区: [GitHub Discussions](your-repo/discussions)

---

<div align="center">

### 🎊 恭喜！llama.cpp集成完成！

**现在可以开始构建你的AI驱动游戏了！** 🐱✨

[开始开发](FEATURE_COMPLETE.md) • [查看文档](addons/llama_cpp/SETUP.md) • [测试推理](TEST_GUIDE.md)

</div>
