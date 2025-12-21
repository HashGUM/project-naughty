extends Node3D
## 3D场景主控制器

@onready var cat = $Cat
@onready var navigation_region = $NavigationRegion3D
@onready var status_label = $UI/Panel/VBoxContainer/StatusLabel
@onready var response_label = $UI/Panel/VBoxContainer/ResponseLabel
@onready var input_field = $UI/Panel/VBoxContainer/HBoxContainer/InputField
@onready var send_button = $UI/Panel/VBoxContainer/HBoxContainer/SendButton
@onready var house_area = $NavigationRegion3D/House/InteractionArea
@onready var garden_area = $NavigationRegion3D/Garden/InteractionArea
@onready var ai_controller = $AIController

@export var use_ai: bool = false  ## 是否使用AI（false=简单规则匹配）

# 场景中的重要位置
var locations = {
	"house": Vector3(6, 0.5, 6),
	"garden": Vector3(-6, 0.5, -6),
	"center": Vector3(0, 0.5, 0)
}

var location_names = {
	"小屋": "house",
	"房子": "house",
	"家": "house",
	"花园": "garden",
	"garden": "garden",
	"中心": "center",
	"中间": "center"
}

func _ready():
	# 连接UI信号
	send_button.pressed.connect(_on_send_pressed)
	input_field.text_submitted.connect(_on_text_submitted)
	
	# 连接交互区域信号
	house_area.cat_entered.connect(_on_area_entered)
	garden_area.cat_entered.connect(_on_area_entered)
	
	# 连接AI控制器信号（如果使用AI）
	if use_ai and ai_controller:
		ai_controller.command_processing.connect(_on_ai_processing)
		ai_controller.command_completed.connect(_on_ai_completed)
		ai_controller.command_failed.connect(_on_ai_failed)
	
	# 等待导航网格烘焙完成
	await get_tree().process_frame
	_setup_navigation()
	
	var mode = "AI模式" if use_ai else "规则模式"
	print("✓ 3D场景初始化完成 - ", mode)
	status_label.text = "状态: 准备就绪 [%s]" % mode
	response_label.text = "欢迎！输入命令让猫咪移动"


func _setup_navigation():
	"""设置导航网格"""
	# 这里可以程序化生成导航网格
	# 或者在编辑器中手动设置
	pass


func _on_send_pressed():
	var command = input_field.text.strip_edges()
	if command.is_empty():
		return
	
	input_field.text = ""
	
	# 根据模式选择处理方式
	if use_ai and ai_controller:
		ai_controller.process_command(command)
	else:
		process_simple_command(command)


func _on_text_submitted(text: String):
	_on_send_pressed()


func process_simple_command(command: String):
	"""处理简单的命令（不使用AI）"""
	status_label.text = "状态: 处理命令 - " + command
	
	# 简单的关键词匹配
	var target_location = null
	var location_key = null
	
	for name in location_names.keys():
		if name in command:
			location_key = location_names[name]
			target_location = locations[location_key]
			break
	
	if target_location:
		status_label.text = "状态: 前往" + location_key
		cat.move_to(target_location)
		await cat.movement_completed
		status_label.text = "状态: 到达" + location_key
		
		# 触发位置事件
		trigger_location_event(location_key)
	else:
		status_label.text = "状态: 不理解命令 - " + command


func trigger_location_event(location_key: String):
	"""触发位置相关的事件"""
	match location_key:
		"house":
			status_label.text = "状态: 到达小屋"
			response_label.text = "🏠 猫咪: 喵~ (这里好温暖)"
			print("🏠 猫咪到达小屋")
		"garden":
			status_label.text = "状态: 到达花园"
			response_label.text = "🌸 猫咪: 喵喵! (好多花花！)"
			print("🌸 猫咪到达花园")
		"center":
			status_label.text = "状态: 回到中心"
			response_label.text = "⭕ 猫咪: 喵... (回家了)"
			print("⭕ 猫咪回到中心")


func _on_area_entered(area_name: String, area_type: String):
	"""当猫咪进入交互区域时触发"""
	trigger_location_event(area_type)


# === AI控制器回调 ===

func _on_ai_processing(command: String):
	status_label.text = "状态: AI思考中..."
	response_label.text = "用户: " + command


func _on_ai_completed(response: Dictionary):
	status_label.text = "状态: 执行完成"
	response_label.text = "🐱 " + response.get("meow", "喵...")


func _on_ai_failed(error: String):
	status_label.text = "状态: AI失败"
	response_label.text = "❌ " + error

