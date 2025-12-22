extends Node
class_name AIController3D
## AI控制器 - 连接LlamaInference与3D猫咪行为

var llama = null  # LlamaInference实例（动态创建）
@onready var cat: Cat3D = get_parent().get_node("Cat")

signal command_processing(command: String)
signal command_completed(response: Dictionary)
signal command_failed(error: String)

var ai_is_processing: bool = false  # 重命名避免shadowing Node.is_processing()
var locations_map = {
	"house": Vector3(6, 0.5, 6),
	"garden": Vector3(-6, 0.5, -6),
	"center": Vector3(0, 0.5, 0)
}

# AI配置 - System Prompt
const SYSTEM_PROMPT = """你是一只可爱的猫咪AI助手。用户会给你指令，你要理解意图并返回严格的JSON格式。

**必须输出的JSON格式：**
{
  "location": "house",
  "action": "play",
  "meow": "喵~"
}

**字段说明：**
- location: 目标位置，可选值："house"(小屋), "garden"(花园), "center"(中心)
- action: 要执行的动作，可选值："move"(移动), "play"(玩耍), "sleep"(睡觉), "idle"(待机)
- meow: 你的喵叫回复，必须是喵类声音（如：喵~、喵喵、喵呜...）

**指令示例：**
- 用户说"去小屋" → {"location": "house", "action": "move", "meow": "喵~好的！"}
- 用户说"去花园玩" → {"location": "garden", "action": "play", "meow": "喵喵~去玩咯！"}
- 用户说"睡觉" → {"location": "house", "action": "sleep", "meow": "喵呜...困了"}

**重要规则：**
1. 只输出JSON，不要有其他文字
2. 所有字段都必须有值
3. meow必须包含"喵"字
4. 完成JSON后立即结束
"""

# AI配置 - JSON Grammar (GBNF格式)
# 注意：GDScript三引号字符串中，反斜杠不需要转义（除非要输出\\\\）
const JSON_GRAMMAR = """# 猫咪回复的JSON Schema - 3D场景专用
# 要求输出固定格式：{"location":"xxx", "action":"xxx", "meow":"xxx"}

root ::= cat-response

cat-response ::= "{" ws
  "\"location\"" ws ":" ws location-value ws "," ws
  "\"action\"" ws ":" ws action-value ws "," ws
  "\"meow\"" ws ":" ws string ws
"}" ws

# 位置值：限定可选值
location-value ::= "\"house\"" | "\"garden\"" | "\"center\"" | "\"\""

# 动作值：限定可选值
action-value ::= "\"move\"" | "\"play\"" | "\"sleep\"" | "\"idle\""

# 字符串：双引号包裹的任意字符（允许转义）
string ::= "\"" ([^"\\] | "\\" .)* "\""

# 可选的空白字符（空格、制表符、换行）
ws ::= [ \t\n\r]*
"""


func _ready():
	# 只在父节点启用AI模式时才初始化
	var parent = get_parent()
	if parent and "use_ai" in parent and not parent.use_ai:
		# AI模式未启用，不初始化
		print("ℹ️ AI模式未启用，跳过LlamaInference初始化")
		return
	
	# 显示加载提示
	_show_loading_status("正在初始化AI引擎...")
	
	# 动态创建LlamaInference实例
	if ClassDB.class_exists("LlamaInference"):
		llama = ClassDB.instantiate("LlamaInference")
		add_child(llama)
		
		# 连接信号
		if llama.has_signal("inference_completed"):
			llama.inference_completed.connect(_on_inference_completed)
		if llama.has_signal("inference_failed"):
			llama.inference_failed.connect(_on_inference_failed)
		
		# 设置GPU layers
		llama.set("gpu_layers", -1)
		
		# 🎯 配置System Prompt和Grammar
		print("📝 配置AI提示词和Grammar...")
		llama.call("set_system_prompt", SYSTEM_PROMPT)
		llama.call("set_grammar_content", JSON_GRAMMAR)
		print("✓ AI配置完成")
		
		# 加载模型（这个过程可能需要几秒）
		_show_loading_status("正在加载AI模型... (这可能需要5-10秒)")
		var model_path = "res://models/Qwen2.5-1.5B-Instruct.Q4_0.gguf"
		
		# 使用call_deferred避免阻塞
		await get_tree().process_frame
		
		if llama.call("load_model", model_path):
			var device_info = llama.call("get_device_info")
			print("✓ AI模型加载成功: ", device_info)
			_show_loading_status("AI就绪 - " + device_info)
		else:
			push_error("✗ AI模型加载失败")
			_show_loading_status("AI模型加载失败")
	else:
		push_error("✗ LlamaInference类未找到，请先编译GDExtension")
		push_error("  请查看 addons/llama_cpp/SETUP.md")
		_show_loading_status("错误: LlamaInference未找到")


func _show_loading_status(message: String):
	## 显示加载状态（如果有UI的话）
	var parent = get_parent()
	if parent and "status_label" in parent and parent.status_label:
		parent.status_label.text = "状态: " + message


func process_command(command: String) -> void:
	## 处理用户命令
	if ai_is_processing:
		push_warning("正在处理命令，请稍候...")
		return
	
	if not llama:
		emit_signal("command_failed", "LlamaInference未初始化")
		return
	
	if not llama.call("is_model_loaded"):
		emit_signal("command_failed", "AI模型未加载")
		return
	
	ai_is_processing = true
	emit_signal("command_processing", command)
	
	print("🔍 发送指令: ", command)

	# 构建提示词
	llama.call("infer", command)


func _on_inference_completed(result: String) -> void:
	## AI推理完成
	print("🤖 原始AI响应: ", result)
	
	# 🎯 使用正则提取JSON（防御性编程：处理LLM抽风）
	var json_pattern = RegEx.new()
	json_pattern.compile("\\{[^{}]*\\}")  # 匹配 {...} 
	
	var json_match = json_pattern.search(result)
	var json_string = ""
	
	if json_match:
		json_string = json_match.get_string()
		print("✓ 提取到JSON: ", json_string)
	else:
		# 如果没有匹配到，尝试直接使用（可能已经是纯JSON）
		json_string = result.strip_edges()
		print("⚠ 未匹配到JSON模式，使用原始响应")
	
	# 解析JSON
	var json = JSON.parse_string(json_string)
	
	if json == null or not json is Dictionary:
		push_error("JSON解析失败: ", json_string)
		_use_fallback()
		return
	
	# 提取字段（支持完整的location, action, meow）
	var location_key = json.get("location", "")
	var action = json.get("action", "move")
	var meow = json.get("meow", "喵...")
	
	# 验证JSON格式
	if not _validate_json_response(json):
		push_warning("JSON格式不完整，使用默认值")
	
	var response = {
		"location": location_key,
		"action": action,
		"meow": meow
	}
	
	print("📋 解析结果: location=%s, action=%s, meow=%s" % [location_key, action, meow])
	
	# 执行对应的动作
	_execute_action(location_key, action)
	
	emit_signal("command_completed", response)
	ai_is_processing = false


func _validate_json_response(json: Dictionary) -> bool:
	## 验证JSON响应格式是否完整
	var required_fields = ["location", "action", "meow"]
	for field in required_fields:
		if field not in json:
			push_warning("缺少字段: " + field)
			return false
	return true


func _execute_action(location_key: String, action: String) -> void:
	## 根据location和action执行对应的行为
	
	# 1. 处理移动
	if location_key in locations_map:
		var target_pos = locations_map[location_key]
		cat.move_to(target_pos)
		print("🐱 猫咪移动到: ", location_key)
	elif location_key != "":
		push_warning("未知位置: " + location_key)
	
	# 2. 处理动作（到达目标后执行）
	match action:
		"move":
			print("🚶 动作: 移动")
			# 移动已在上面处理
		"play":
			print("🎮 动作: 玩耍")
			# TODO: 播放玩耍动画
			_trigger_play_animation()
		"sleep":
			print("😴 动作: 睡觉")
			# TODO: 播放睡觉动画
			_trigger_sleep_animation()
		"idle":
			print("🧍 动作: 待机")
			# 不做特殊处理
		_:
			push_warning("未知动作: " + action)


func _trigger_play_animation() -> void:
	## 触发玩耍动画（示例）
	# 等待移动完成
	if cat.is_moving:
		await cat.movement_completed
	
	print("  💫 播放玩耍动画")
	cat.play_action()


func _trigger_sleep_animation() -> void:
	## 触发睡觉动画（示例）
	# 等待移动完成
	if cat.is_moving:
		await cat.movement_completed
	
	# TODO: 播放动画
	print("  💤 播放睡觉动画")
	# 示例：让猫咪趴下
	# cat.play_animation("sleep")


func _on_inference_failed(error: String) -> void:
	## AI推理失败
	push_error("AI推理失败: ", error)
	_use_fallback()


func _use_fallback() -> void:
	## 使用后备行为
	var response = {
		"location": "",
		"action": "idle",
		"meow": "喵... (不太明白)"
	}
	emit_signal("command_completed", response)
	ai_is_processing = false
