# 项目更新日志

## 2025-12-20

### ✅ 配置文件重组织

**移动Prompt配置文件到专用文件夹**

- 创建了 `prompt/` 文件夹用于存放所有提示词相关配置
- 移动 `system_prompt.txt` 从 `addons/llama_cpp/` 到 `prompt/`
- 移动 `cat_response.gbnf` 从 `addons/llama_cpp/` 到 `prompt/`
- 更新C++代码中的文件路径引用
- 创建 `prompt/README.md` 说明文档

**优点：**
- 配置文件更容易找到和修改
- 与插件代码分离，结构更清晰
- 方便用户自定义猫咪性格和行为
- 无需深入 `addons/` 目录即可调整提示词

### ✅ 修复JSON Schema字段不一致

- 将 `cat_response.gbnf` 中的 `time` 字段改为 `count`
- 现在与 `system_prompt.txt` 中的字段定义完全一致
- 格式：`{"destination":"xxx", "event":"xxx", "count":数字, "reply":"xxx"}`

### ✅ 增加窗口默认高度

**修改 `project.godot` 显示设置**

- 窗口宽度：1280px
- 窗口高度：900px（从默认的720px增加）
- 启用窗口大小可调整

**解决问题：**
- 测试界面内容不再超出窗口范围
- 所有UI元素都能完整显示
- 更好的测试体验

### 📁 当前项目结构

```
project-naughty/
├── addons/
│   └── llama_cpp/          # GDExtension C++代码
│       ├── src/
│       ├── bin/
│       └── ...
├── models/                  # AI模型文件
│   ├── gemma-3-1b-it-q4_0.gguf (默认)
│   ├── Qwen2.5-1.5B-Instruct.Q4_0.gguf
│   └── qwen3-0.6b-q4_k_m.gguf
├── prompt/                  # 🆕 Prompt配置文件
│   ├── system_prompt.txt   # 系统提示词
│   ├── cat_response.gbnf   # JSON格式约束
│   └── README.md           # 使用说明
├── scenes/                  # Godot场景
│   ├── test_gdextension.tscn
│   └── test_gdextension.gd
└── project.godot           # 项目配置
```

### 🔄 需要的操作

**已完成编译**
- GDExtension已重新编译，新的路径已生效
- 可以直接在Godot中测试

**测试步骤**
1. 打开Godot编辑器
2. 运行测试场景（会自动加载Gemma 3 1B模型）
3. 窗口应该显示完整的UI（900px高度）
4. 测试推理功能，验证prompt文件正确加载

### 📝 后续可以做的

- 自定义 `prompt/system_prompt.txt` 调整猫咪性格
- 修改 `prompt/cat_response.gbnf` 添加/删除JSON字段
- 测试不同模型对新prompt的响应
- 开始实现游戏中的猫咪行为系统

---

**所有修改都已应用，可以开始测试！** 🚀

