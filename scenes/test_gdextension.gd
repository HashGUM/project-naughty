extends Node2D

## 测试场景：GDExtension LlamaInference集成

# 注意：需要先编译GDExtension才能运行此场景
# 编译后会自动识别LlamaInference类

@onready var ui_container = $UI/MarginContainer/VBoxContainer
var llama_node: Node = null

# 可用模型列表
var models = {
	0: {
		"name": "Gemma 3 1B",
		"path": "res://models/gemma-3-1b-it-q4_0.gguf"
	},
	1: {
		"name": "Qwen2.5 1.5B",
		"path": "res://models/Qwen2.5-1.5B-Instruct.Q4_0.gguf"
	},
	2: {
		"name": "Qwen3 0.6B",
		"path": "res://models/qwen3-0.6b-q4_k_m.gguf"
	}
}

var current_model_id = 0  # 默认选择Gemma 3 1B

func _ready():
	print("=== GDExtension LlamaInference Test Scene ===")
	
	# 尝试创建LlamaInference实例
	if ClassDB.class_exists("LlamaInference"):
		llama_node = ClassDB.instantiate("LlamaInference")
		add_child(llama_node)
		
		$UI/MarginContainer/VBoxContainer/StatusLabel.text = "LlamaInference loaded successfully!"
		$UI/MarginContainer/VBoxContainer/StatusLabel.add_theme_color_override("font_color", Color.GREEN)
		
		# 连接信号
		if llama_node.has_signal("inference_completed"):
			llama_node.inference_completed.connect(_on_inference_completed)
		if llama_node.has_signal("inference_failed"):
			llama_node.inference_failed.connect(_on_inference_failed)
		
		# 打印可用方法
		print("Available methods:", llama_node.get_method_list().map(func(m): return m["name"]))
	else:
		$UI/MarginContainer/VBoxContainer/StatusLabel.text = "LlamaInference not found - Please compile GDExtension first"
		$UI/MarginContainer/VBoxContainer/StatusLabel.add_theme_color_override("font_color", Color.RED)
		$UI/MarginContainer/VBoxContainer/SendButton.disabled = true
		
		print("Error: LlamaInference class not registered")
		print("Please follow instructions in addons/llama_cpp/SETUP.md")
	
	# 连接按钮信号
	$UI/MarginContainer/VBoxContainer/SendButton.pressed.connect(_on_send_pressed)
	$UI/MarginContainer/VBoxContainer/LoadModelButton.pressed.connect(_on_load_model_pressed)
	$UI/MarginContainer/VBoxContainer/ModelSelector.item_selected.connect(_on_model_selected)
	
	# 自动加载默认模型 (Gemma 3 1B)
	if llama_node != null:
		_on_load_model_pressed()

func _on_model_selected(index: int):
	current_model_id = index
	print("Selected model: ", models[index]["name"])
	
	# 选择模型后自动加载
	if llama_node != null:
		_on_load_model_pressed()

func _on_load_model_pressed():
	if llama_node == null:
		return
	
	# 从models字典获取选中的模型路径
	var model_info = models[current_model_id]
	var model_path = model_info["path"]
	
	$UI/MarginContainer/VBoxContainer/StatusLabel.text = "Loading " + model_info["name"] + "..."
	$UI/MarginContainer/VBoxContainer/StatusLabel.add_theme_color_override("font_color", Color.WHITE)
	
	# 如果之前加载了模型，先卸载
	if llama_node.call("is_model_loaded"):
		llama_node.call("unload_model")
	
	# 设置GPU layers（-1表示全部）
	llama_node.set("gpu_layers", -1)
	
	# 调用load_model方法
	var success = llama_node.call("load_model", model_path)
	
	if success:
		var device_info = llama_node.call("get_device_info")
		$UI/MarginContainer/VBoxContainer/StatusLabel.text = model_info["name"] + " loaded - " + device_info
		$UI/MarginContainer/VBoxContainer/StatusLabel.add_theme_color_override("font_color", Color.GREEN)
	else:
		$UI/MarginContainer/VBoxContainer/StatusLabel.text = "Failed to load " + model_info["name"]
		$UI/MarginContainer/VBoxContainer/StatusLabel.add_theme_color_override("font_color", Color.RED)

func _on_send_pressed():
	if llama_node == null:
		return
	
	var prompt = $UI/MarginContainer/VBoxContainer/InputField.text.strip_edges()
	
	if prompt.is_empty():
		$UI/MarginContainer/VBoxContainer/StatusLabel.text = "Please enter a prompt"
		return
	
	if llama_node.call("is_inferring"):
		$UI/MarginContainer/VBoxContainer/StatusLabel.text = "Inference in progress..."
		return
	
	# 清空输出
	$UI/MarginContainer/VBoxContainer/OutputDisplay.text = "Inferring...\n"
	$UI/MarginContainer/VBoxContainer/StatusLabel.text = "Calling LlamaInference..."
	
	# 调用推理
	var result = llama_node.call("infer", prompt)
	
	# 显示结果
	$UI/MarginContainer/VBoxContainer/OutputDisplay.text += "\nReceived response:\n" + result

func _on_inference_completed(result: String):
	print("Inference completed signal received")
	$UI/MarginContainer/VBoxContainer/StatusLabel.text = "Inference completed"
	$UI/MarginContainer/VBoxContainer/StatusLabel.add_theme_color_override("font_color", Color.GREEN)

func _on_inference_failed(error: String):
	print("Inference failed: ", error)
	$UI/MarginContainer/VBoxContainer/OutputDisplay.text = "Error: " + error
	$UI/MarginContainer/VBoxContainer/StatusLabel.text = "Inference failed"
	$UI/MarginContainer/VBoxContainer/StatusLabel.add_theme_color_override("font_color", Color.RED)

