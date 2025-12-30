extends CharacterBody3D
class_name Cat3D
## 3D猫咪控制器 - 处理移动、导航和动画

@export var move_speed: float = 3.0
@export var rotation_speed: float = 10.0
@export var wander_speed: float = 2.0  # 闲逛速度（较慢）
@export var run_speed: float = 5.0     # 命令执行速度（较快）
@export var wander_interval_min: float = 5.0  # 闲逛间隔最小值（秒）
@export var wander_interval_max: float = 10.0 # 闲逛间隔最大值（秒）
@export var wander_radius: float = 5.0  # 闲逛范围半径（米）
@export var wander_posibility: float = 0.8  # 闲逛概率

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var animation_tree: AnimationTree = $CatModel/AnimationTree
@onready var cat_model = $CatModel

signal movement_completed
signal movement_started

var is_moving: bool = false
var target_position: Vector3
var playback: AnimationNodeStateMachinePlayback
var current_animation_state: String = ""  # 跟踪当前动画状态，避免重复切换
var is_playing_action: bool = false  # 是否正在播放动作动画（不应被打断）

# 闲逛相关变量
var is_wandering: bool = false          # 是否处于闲逛模式
var wander_enabled: bool = true         # 是否允许闲逛
var is_executing_command: bool = false  # 是否正在执行命令
var wander_timer: Timer = null          # 闲逛定时器


func _ready():
	# 等待第一帧后再配置导航代理
	call_deferred("_setup_navigation")
	
	# 初始化动画系统
	if animation_tree:
		playback = animation_tree.get("parameters/playback")
		animation_tree.active = true
		# 启动状态机，从Idle状态开始
		playback.start("Idle")
		current_animation_state = "Idle"
		print("✓ 猫咪动画系统初始化完成")
	
	# 初始化闲逛定时器
	wander_timer = Timer.new()
	add_child(wander_timer)
	wander_timer.one_shot = false
	wander_timer.timeout.connect(_on_wander_timer_timeout)
	print("✓ 猫咪闲逛系统初始化完成")


func _setup_navigation():
	# 配置导航代理
	# 等待导航地图同步完成
	await get_tree().physics_frame
	
	# Godot 4.x中，avoidance需要手动启用
	navigation_agent.avoidance_enabled = false  # 暂时禁用避障，简化问题
	navigation_agent.velocity_computed.connect(_on_velocity_computed)
	navigation_agent.path_desired_distance = 0.5
	navigation_agent.target_desired_distance = 0.5
	
	print("✓ 猫咪导航系统初始化完成")
	
	# 导航准备好后，启动闲逛
	start_wandering()


func _physics_process(delta):
	if not is_moving:
		# 空闲状态，只在状态改变时切换动画（但不打断动作动画）
		if playback and current_animation_state != "Idle" and not is_playing_action:
			playback.travel("Idle")
			current_animation_state = "Idle"
		return
	
	if navigation_agent.is_navigation_finished():
		is_moving = false
		is_wandering = false
		velocity = Vector3.ZERO
		# 切换到Idle动画
		if playback and current_animation_state != "Idle":
			playback.travel("Idle")
			current_animation_state = "Idle"
		print("✓ 猫咪到达目标位置: ", global_position)
		emit_signal("movement_completed")
		return
	
	# 获取下一个路径点
	var next_path_position = navigation_agent.get_next_path_position()
	var direction = (next_path_position - global_position).normalized()
	
	# 调试信息（每60帧打印一次）
	if Engine.get_physics_frames() % 60 == 0:
		var distance = global_position.distance_to(target_position)
		print("  移动中... 当前: ", global_position, " 目标: ", target_position)
		print("    距离: ", distance, " 下一个路径点: ", next_path_position)
	
	# 根据移动类型播放不同动画
	# 闲逛时使用Walk，执行命令时使用Run
	var target_animation = "Walk" if is_wandering else "Run"
	if playback and current_animation_state != target_animation:
		playback.travel(target_animation)
		current_animation_state = target_animation
	
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
	# 导航代理计算出安全速度后调用
	velocity = safe_velocity
	move_and_slide()


func move_to(target: Vector3, is_command: bool = true):
	# 移动到目标位置
	# is_command: true表示执行命令（使用Run动画+快速移动），false表示闲逛（使用Walk动画+慢速移动）
	if is_moving:
		print("⚠ 猫咪正在移动中，取消当前移动")
	
	# 等待导航准备好
	if not navigation_agent.is_navigation_finished():
		await get_tree().physics_frame
	
	target_position = target
	navigation_agent.target_position = target
	is_moving = true
	
	# 根据移动类型设置速度和状态
	if is_command:
		# 命令执行：快速移动（Run）
		move_speed = run_speed
		is_wandering = false
		is_executing_command = true
		print("🐱 猫咪执行命令移动到: ", target, " (Run)")
	else:
		# 闲逛：慢速移动（Walk）
		move_speed = wander_speed
		is_wandering = true
		print("🐱 猫咪闲逛到: ", target, " (Walk)")
	
	emit_signal("movement_started")
	
	print("  当前位置: ", global_position)
	print("  导航就绪: ", navigation_agent.is_target_reachable())


func stop_movement():
	# 停止移动
	is_moving = false
	velocity = Vector3.ZERO
	navigation_agent.set_velocity(Vector3.ZERO)


func play_action():
	# 播放操作动画（抓蝴蝶等）
	if playback:
		is_playing_action = true
		playback.travel("Operate")
		current_animation_state = "Operate"
		print("🐱 猫咪执行操作动画")
		
		# 等待动画播放完成（Operate动画大约2-3秒）
		await get_tree().create_timer(3.0).timeout
		
		# 动画结束，恢复到Idle
		is_playing_action = false
		if playback and not is_moving:
			playback.travel("Idle")
			current_animation_state = "Idle"
			print("✓ 操作动画播放完成")


func start_wandering():
	## 启动闲逛系统
	if not wander_enabled:
		return
	
	if wander_timer:
		# 设置随机间隔
		var interval = randf_range(wander_interval_min, wander_interval_max)
		wander_timer.wait_time = interval
		wander_timer.start()
		print("🌟 猫咪开始闲逛（间隔: %.1f秒）" % interval)


func stop_wandering():
	## 停止闲逛系统
	if wander_timer:
		wander_timer.stop()
	is_wandering = false
	print("🛑 猫咪停止闲逛")


func _on_wander_timer_timeout():
	## 定时器触发，执行随机闲逛
	# 如果正在执行命令或已经在移动，跳过本次闲逛
	if is_executing_command or is_moving:
		return
	
	_wander_randomly()
	
	# 设置下一次闲逛的随机间隔
	var interval = randf_range(wander_interval_min, wander_interval_max)
	wander_timer.wait_time = interval


func _wander_randomly():
	## 随机闲逛逻辑
	# 50%概率不动，保持Idle状态
	if randf() < 1 - wander_posibility:
		print("🐱 猫咪选择待机")
		return
	
	# 在当前位置附近随机选择目标点
	var random_offset = Vector3(
		randf_range(-wander_radius, wander_radius),
		0,
		randf_range(-wander_radius, wander_radius)
	)
	var target = global_position + random_offset
	
	# 确保y坐标合理（保持在地面上）
	target.y = global_position.y
	
	# 开始闲逛移动
	move_to(target, false)  # is_command=false 表示闲逛
