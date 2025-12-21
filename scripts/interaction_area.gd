extends Area3D
class_name InteractionArea
## 交互区域 - 检测猫咪进入特定区域

@export var interaction_name: String = "未命名区域"
@export var interaction_type: String = "generic"

signal cat_entered(area_name: String, area_type: String)
signal cat_exited(area_name: String, area_type: String)

var cat_inside: bool = false


func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node3D):
	if body is Cat3D:
		cat_inside = true
		emit_signal("cat_entered", interaction_name, interaction_type)
		print("🐱 猫咪进入: ", interaction_name)


func _on_body_exited(body: Node3D):
	if body is Cat3D:
		cat_inside = false
		emit_signal("cat_exited", interaction_name, interaction_type)
		print("🐱 猫咪离开: ", interaction_name)

