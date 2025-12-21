extends CharacterBody3D
class_name Cat3D
## 3D猫咪控制器 - 处理移动和导航

@export var move_speed: float = 3.0
@export var rotation_speed: float = 10.0

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

signal movement_completed
signal movement_started

var is_moving: bool = false
var target_position: Vector3


func _ready():
	# 等待第一帧后再配置导航代理
	call_deferred("_setup_navigation")


func _setup_navigation():
	"""配置导航代理"""
	# 等待导航地图同步完成
	await get_tree().physics_frame
	
	# Godot 4.x中，avoidance需要手动启用
	navigation_agent.avoidance_enabled = false  # 暂时禁用避障，简化问题
	navigation_agent.velocity_computed.connect(_on_velocity_computed)
	navigation_agent.path_desired_distance = 0.5
	navigation_agent.target_desired_distance = 0.5
	
	print("✓ 猫咪导航系统初始化完成")


func _physics_process(delta):
	if not is_moving:
		return
	
	if navigation_agent.is_navigation_finished():
		is_moving = false
		velocity = Vector3.ZERO
		print("✓ 猫咪到达目标位置: ", global_position)
		emit_signal("movement_completed")
		return
	
	# 获取下一个路径点
	var next_path_position = navigation_agent.get_next_path_position()
	var direction = (next_path_position - global_position).normalized()
	
	# 调试信息（每60帧打印一次）
	if Engine.get_physics_frames() % 60 == 0:
		print("  移动中... 当前: ", global_position, " 目标: ", target_position, " 距离: ", global_position.distance_to(target_position))
		print("    下一个路径点: ", next_path_position, " 方向: ", direction)
	
	# 直接设置velocity并移动（不使用avoidance）
	if navigation_agent.avoidance_enabled:
		# 使用avoidance
		var desired_velocity = direction * move_speed
		navigation_agent.set_velocity(desired_velocity)
	else:
		# 直接移动（更简单，更可靠）
		velocity = direction * move_speed
		move_and_slide()
	
	# 旋转朝向移动方向
	if direction.length() > 0.01:
		var target_rotation = atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, rotation_speed * delta)


func _on_velocity_computed(safe_velocity: Vector3):
	"""导航代理计算出安全速度后调用"""
	velocity = safe_velocity
	move_and_slide()


func move_to(target: Vector3):
	"""移动到目标位置"""
	if is_moving:
		print("⚠ 猫咪正在移动中，取消当前移动")
	
	# 等待导航准备好
	if not navigation_agent.is_navigation_finished():
		await get_tree().physics_frame
	
	target_position = target
	navigation_agent.target_position = target
	is_moving = true
	emit_signal("movement_started")
	
	print("🐱 猫咪开始移动到: ", target)
	print("  当前位置: ", global_position)
	print("  导航就绪: ", navigation_agent.is_target_reachable())


func stop_movement():
	"""停止移动"""
	is_moving = false
	velocity = Vector3.ZERO
	navigation_agent.set_velocity(Vector3.ZERO)

