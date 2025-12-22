extends Camera3D
## 简单的3D相机控制器 - 可用鼠标中键旋转，滚轮缩放

@export var target: Node3D
@export var distance: float = 8.0
@export var height: float = 6.0
@export var rotation_speed: float = 0.5
@export var zoom_speed: float = 1.0
@export var min_distance: float = 3.0
@export var max_distance: float = 20.0

var rotation_y: float = 0.0
var is_rotating: bool = false
var height_ratio: float = 0.75  # height/distance 比例，用于保持俯仰角


func _ready():
	if not target:
		target = get_parent().get_node_or_null("Cat")
	# 计算初始俯仰角比例
	height_ratio = height / distance if distance > 0 else 0.75
	update_camera_position()


func _process(delta):
	if target:
		update_camera_position()


func _input(event):
	# 鼠标中键拖拽旋转
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			is_rotating = event.pressed
		
		# 滚轮缩放 - 同时调整height保持俯仰角
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance = clamp(distance - zoom_speed, min_distance, max_distance)
			height = distance * height_ratio
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance = clamp(distance + zoom_speed, min_distance, max_distance)
			height = distance * height_ratio
	
	# 鼠标移动时旋转相机
	if event is InputEventMouseMotion and is_rotating:
		rotation_y += event.relative.x * rotation_speed * 0.01


func update_camera_position():
	"""更新相机位置"""
	if not target:
		return
	
	var target_pos = target.global_position
	var offset = Vector3(
		sin(rotation_y) * distance,
		height,
		cos(rotation_y) * distance
	)
	
	global_position = target_pos + offset
	look_at(target_pos, Vector3.UP)
