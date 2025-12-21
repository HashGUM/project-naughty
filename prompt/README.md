# Prompt 配置文件夹

此文件夹包含AI猫咪的提示词配置文件。

## 📁 文件说明

### `system_prompt.txt`
**系统提示词** - 定义AI猫咪的基本性格和行为规则

- 描述猫咪的性格特征
- 定义输出JSON格式要求
- 设置猫咪的回复规则和限制

**修改此文件后无需重新编译GDExtension**，直接重启Godot或重新加载模型即可生效。

### `cat_response.gbnf`
**JSON Schema语法定义（GBNF格式）** - 强制约束模型输出格式

定义的JSON格式：
```json
{
  "destination": "字符串 - 猫咪认为消息想发往的地方",
  "event": "字符串 - 猫咪觉得发生的事情",
  "count": "数字 - 事件的数量/强度/猫咪计数",
  "reply": "字符串 - 只能是各种形式的'喵'"
}
```

**修改此文件后无需重新编译GDExtension**，直接重启Godot或重新加载模型即可生效。

## 🎨 自定义指南

### 调整猫咪性格

编辑 `system_prompt.txt`，修改第2行的性格描述：

```
你的性格是典型的猫：可以听话，也可以不听话，但永远是猫咪的方式来回应。
```

例如改为：
```
你的性格是非常高冷的猫：经常不听话，喜欢独来独往，偶尔会撒娇。
```

### 修改JSON输出格式

1. 修改 `system_prompt.txt` 中的字段描述
2. 同步修改 `cat_response.gbnf` 中的语法定义
3. 两个文件必须保持一致，否则模型输出可能不符合预期

### 添加新字段示例

假设要添加 `mood` 字段表示猫咪心情：

**在 `system_prompt.txt` 中：**
```
{"destination":"xxx", "event":"xxx", "count":数字, "mood":"xxx", "reply":"xxx"}

字段要求：
...
• mood: 猫咪当前的心情，可以是"开心"、"生气"、"慵懒"等。
```

**在 `cat_response.gbnf` 中：**
```gbnf
cat-response ::= "{" ws
  "\"destination\"" ws ":" ws string ws "," ws
  "\"event\"" ws ":" ws string ws "," ws
  "\"count\"" ws ":" ws number ws "," ws
  "\"mood\"" ws ":" ws string ws "," ws
  "\"reply\"" ws ":" ws string ws
"}" ws
```

## ⚠️ 注意事项

1. **字段顺序必须固定**：GBNF语法要求严格的字段顺序
2. **终止符**：`system_prompt.txt` 中提到的 `</s>` 终止符会由C++代码自动处理
3. **中文支持**：两个文件都使用UTF-8编码，完全支持中文
4. **实时生效**：修改后重新加载模型即可，无需重新编译

## 🔧 技术细节

这两个文件由 `addons/llama_cpp/src/llama_inference.cpp` 在运行时读取：

```cpp
// 读取System Prompt
String system_prompt_path = ProjectSettings::get_singleton()->globalize_path("res://prompt/system_prompt.txt");

// 读取JSON Grammar
String grammar_path = ProjectSettings::get_singleton()->globalize_path("res://prompt/cat_response.gbnf");
```

使用 `res://` 路径保证在导出游戏时也能正确打包这些文件。

