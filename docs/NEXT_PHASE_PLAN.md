# 🐱 Godot AI猫项目 - 下一阶段开发计划

> 基于原始计划，llama.cpp推理引擎和3D白盒原型已完成，现在进入完善阶段

**当前状态：** ✅ 阶段3和阶段4已完成（C++推理引擎 + GDExtension集成）  
**当前状态：** ✅ 3D白盒原型已完成（导航寻路 + 交互系统 + AI集成）  
**下一目标：** 完善猫咪行为系统 + 美术资源替换

---

## 🎯 当前3D原型状态

### ✅ 已完成功能

**场景结构：**
- ✅ 20x20米白盒地面
- ✅ 橙色小屋方块
- ✅ 绿色花园方块
- ✅ 米色猫咪方块

**导航系统：**
- ✅ NavigationRegion3D自动寻路
- ✅ NavigationAgent3D路径规划
- ✅ 平滑移动和旋转
- ✅ 调试信息输出

**交互系统：**
- ✅ Area3D区域检测
- ✅ 进入/离开事件
- ✅ 小屋和花园交互点

**控制系统：**
- ✅ 简单规则模式（关键词匹配）
- ✅ AI智能模式（自然语言）
- ✅ 模式切换开关

**相机系统：**
- ✅ 鼠标中键旋转
- ✅ 滚轮缩放
- ✅ 自动跟随猫咪

**UI系统：**
- ✅ 命令输入框
- ✅ 状态显示
- ✅ 反馈显示
- ✅ 帮助提示

### 📊 技术实现

**脚本文件（共5个）：**
- `scripts/main_3d.gd` - 主场景控制器（~90行）
- `scripts/cat_3d.gd` - 猫咪移动控制（~90行）
- `scripts/camera_3d.gd` - 相机控制（~65行）
- `scripts/interaction_area.gd` - 交互检测（~35行）
- `scripts/ai_controller_3d.gd` - AI集成（~135行）

**关键技术点：**
- GDExtension动态实例化（ClassDB.instantiate）
- NavigationAgent3D寻路
- 信号驱动架构
- 双模式切换
- 异步AI加载

---

## 📋 总体时间线（原始计划）

```
✅ 第1周：环境搭建（已完成）
  ✓ Day1-3：Godot基础框架
  ✓ Day4：GDExtension集成

✅ 第2-3周：C++推理引擎（已完成）
  ✓ llama.cpp集成
  ✓ GPU/CPU推理
  ✓ UTF-8中文支持
  ✓ 异步推理架构

✅ 第4周：3D白盒原型（已完成）
  ✓ 3D场景和导航系统
  ✓ 猫咪移动控制
  ✓ 交互事件系统
  ✓ AI/规则双模式

🎯 接下来（推荐顺序）：
  
📍 第5周：完善猫咪系统
  → 添加更多动作和动画
  → 实现状态系统（饥饿、疲劳、心情）
  → 优化AI提示词
  → 美术资源替换

📍 第6周：数据准备与微调（可选）
  → 收集训练数据
  → LoRA微调训练
  → 集成微调模型

📍 第7周：优化与完善
  → 性能优化
  → 完整测试
  → 打包发布
```

---

## 🎯 阶段5：Godot行为控制器（4天）

### 优先级说明
根据原始计划建议："**先实现基于规则的版本**，然后集成推理，最后微调"。

这个顺序的好处：
1. 快速验证系统可行性
2. 独立测试各个模块
3. 即使模型不理想，游戏也能运行

---

### 模块5.1：猫咪基础行为系统（2天）

#### 任务1.1：创建猫咪场景和基础动画（0.5天）

**文件结构：**
```
scenes/
├── cat/
│   ├── cat.tscn              # 主猫咪场景
│   ├── cat.gd                # 猫咪控制脚本
│   └── animations/
│       ├── idle.tres
│       ├── walk.tres
│       ├── run.tres
│       ├── jump.tres
│       ├── sleep.tres
│       └── play.tres
```

**任务清单：**
- [ ] 创建猫咪Sprite节点（使用占位图或简单绘制）
- [ ] 配置AnimationPlayer节点
- [ ] 实现6个基础动画：idle, walk, run, jump, sleep, play
- [ ] 创建AnimationTree用于动画混合
- [ ] 测试动画播放流畅度

**示例代码：**
```gdscript
# scenes/cat/cat.gd
extends CharacterBody2D
class_name Cat

@onready var animation_player = $AnimationPlayer
@onready var animation_tree = $AnimationTree
@onready var sprite = $Sprite2D

enum AnimState {
    IDLE,
    WALKING,
    RUNNING,
    JUMPING,
    SLEEPING,
    PLAYING
}

var current_anim_state: AnimState = AnimState.IDLE

func play_animation(anim_name: String) -> void:
    if animation_player.has_animation(anim_name):
        animation_player.play(anim_name)

func _ready():
    play_animation("idle")
```

**测试方法：**
```gdscript
# test/test_cat_animations.gd
extends GutTest

func test_cat_has_all_animations():
    var cat = load("res://scenes/cat/cat.tscn").instantiate()
    add_child_autofree(cat)
    
    assert_true(cat.animation_player.has_animation("idle"))
    assert_true(cat.animation_player.has_animation("walk"))
    assert_true(cat.animation_player.has_animation("run"))
```

---

#### 任务1.2：实现动作队列系统（0.5天）

**创建ActionQueue类：**
```gdscript
# scripts/action_queue.gd
class_name ActionQueue
extends Node

signal action_started(action: Dictionary)
signal action_completed(action: Dictionary)
signal queue_empty()

var action_queue: Array[Dictionary] = []
var current_action: Dictionary = {}
var is_executing: bool = false

func add_actions(actions: Array) -> void:
    """添加一组动作到队列"""
    for action in actions:
        if validate_action(action):
            action_queue.append(action)
    
    if not is_executing:
        execute_next()

func validate_action(action: Dictionary) -> bool:
    """验证动作格式"""
    return action.has("action") and action.has("params")

func execute_next() -> void:
    """执行下一个动作"""
    if action_queue.is_empty():
        current_action = {}
        is_executing = false
        emit_signal("queue_empty")
        return
    
    current_action = action_queue.pop_front()
    is_executing = true
    emit_signal("action_started", current_action)
    
    # 执行动作
    await perform_action(current_action)
    
    emit_signal("action_completed", current_action)
    execute_next()

func perform_action(action: Dictionary) -> void:
    """执行单个动作"""
    var duration = action.get("duration", 1.0)
    
    # 这里会调用猫的实际行为
    match action.action:
        "walk_to":
            await get_parent().walk_to(action.params.target)
        "jump":
            await get_parent().jump(action.params.height)
        "sleep":
            await get_parent().sleep(duration)
        "play":
            await get_parent().play(duration)
        _:
            await get_tree().create_timer(duration).timeout

func clear_queue() -> void:
    """清空队列"""
    action_queue.clear()
    is_executing = false
```

**测试：**
```gdscript
# test/test_action_queue.gd
extends GutTest

func test_action_queue_basic():
    var queue = ActionQueue.new()
    add_child_autofree(queue)
    
    var actions = [
        {"action": "walk_to", "params": {"target": Vector2(100, 100)}, "duration": 1.0},
        {"action": "jump", "params": {"height": 50}, "duration": 0.5}
    ]
    
    queue.add_actions(actions)
    assert_eq(queue.action_queue.size(), 2)
```

---

#### 任务1.3：实现猫咪行为状态机（1天）

**创建CatBehavior类：**
```gdscript
# scripts/cat_behavior.gd
class_name CatBehavior
extends Node

enum State {
    IDLE,
    WALKING,
    RUNNING,
    JUMPING,
    SLEEPING,
    PLAYING,
    EATING,
    GROOMING
}

@export var move_speed: float = 100.0
@export var run_speed: float = 200.0
@export var jump_force: float = 400.0

var current_state: State = State.IDLE
var state_params: Dictionary = {}
var cat: Cat  # 引用父节点

signal state_changed(old_state: State, new_state: State)
signal behavior_completed()

func _ready():
    cat = get_parent() as Cat
    assert(cat != null, "CatBehavior必须是Cat节点的子节点")

func transition_to(new_state: State, params: Dictionary = {}) -> void:
    """状态转换"""
    var old_state = current_state
    
    # 退出当前状态
    exit_state(current_state)
    
    # 进入新状态
    current_state = new_state
    state_params = params
    
    emit_signal("state_changed", old_state, new_state)
    enter_state(new_state, params)

func enter_state(state: State, params: Dictionary) -> void:
    """进入状态"""
    match state:
        State.IDLE:
            cat.play_animation("idle")
        State.WALKING:
            cat.play_animation("walk")
        State.RUNNING:
            cat.play_animation("run")
        State.JUMPING:
            cat.play_animation("jump")
            await perform_jump(params.get("height", 50))
            emit_signal("behavior_completed")
        State.SLEEPING:
            cat.play_animation("sleep")
            await get_tree().create_timer(params.get("duration", 3.0)).timeout
            transition_to(State.IDLE)
            emit_signal("behavior_completed")
        State.PLAYING:
            cat.play_animation("play")
            await get_tree().create_timer(params.get("duration", 2.0)).timeout
            transition_to(State.IDLE)
            emit_signal("behavior_completed")

func exit_state(state: State) -> void:
    """退出状态清理"""
    match state:
        State.WALKING, State.RUNNING:
            cat.velocity = Vector2.ZERO

# 具体行为实现
func walk_to(target: Vector2) -> void:
    """走到目标位置"""
    transition_to(State.WALKING, {"target": target})
    
    while cat.global_position.distance_to(target) > 10:
        var direction = (target - cat.global_position).normalized()
        cat.velocity = direction * move_speed
        cat.move_and_slide()
        
        # 翻转sprite
        if direction.x != 0:
            cat.sprite.flip_h = direction.x < 0
        
        await get_tree().process_frame
    
    cat.velocity = Vector2.ZERO
    transition_to(State.IDLE)
    emit_signal("behavior_completed")

func run_to(target: Vector2) -> void:
    """跑到目标位置"""
    transition_to(State.RUNNING, {"target": target})
    
    while cat.global_position.distance_to(target) > 10:
        var direction = (target - cat.global_position).normalized()
        cat.velocity = direction * run_speed
        cat.move_and_slide()
        
        if direction.x != 0:
            cat.sprite.flip_h = direction.x < 0
        
        await get_tree().process_frame
    
    cat.velocity = Vector2.ZERO
    transition_to(State.IDLE)
    emit_signal("behavior_completed")

func perform_jump(height: float) -> void:
    """执行跳跃"""
    cat.velocity.y = -jump_force
    await get_tree().create_timer(0.5).timeout

func sleep(duration: float) -> void:
    """睡觉"""
    transition_to(State.SLEEPING, {"duration": duration})

func play(duration: float) -> void:
    """玩耍"""
    transition_to(State.PLAYING, {"duration": duration})
```

---

### 模块5.2：JSON行为解析器（1天）

#### 任务2.1：创建ActionParser类（0.5天）

**实现JSON到动作的映射：**
```gdscript
# scripts/action_parser.gd
class_name ActionParser
extends Node

static func parse_ai_response(response: Dictionary) -> Array[Dictionary]:
    """
    解析AI返回的JSON，转换为动作队列
    
    输入格式：
    {
        "interpretation": "用户想让我...",
        "actions": [
            {"action": "walk_to", "params": {"target": {"x": 100, "y": 100}}, "duration": 2.0},
            {"action": "jump", "params": {"height": 50}, "duration": 0.5}
        ],
        "meow_response": "喵！"
    }
    
    输出格式：
    [
        {"action": "walk_to", "params": {"target": Vector2(100, 100)}, "duration": 2.0},
        {"action": "jump", "params": {"height": 50}, "duration": 0.5}
    ]
    """
    var actions: Array[Dictionary] = []
    
    if not response.has("actions"):
        push_warning("AI响应缺少actions字段")
        return actions
    
    for action_data in response["actions"]:
        var parsed_action = parse_single_action(action_data)
        if parsed_action:
            actions.append(parsed_action)
    
    return actions

static func parse_single_action(action_data: Dictionary) -> Dictionary:
    """解析单个动作"""
    if not action_data.has("action"):
        push_warning("动作缺少action字段")
        return {}
    
    var action_name = action_data["action"]
    var params = action_data.get("params", {})
    var duration = action_data.get("duration", 1.0)
    
    # 类型转换和验证
    var parsed_params = convert_params(action_name, params)
    
    return {
        "action": action_name,
        "params": parsed_params,
        "duration": duration
    }

static func convert_params(action_name: String, params: Dictionary) -> Dictionary:
    """转换参数类型（JSON → Godot）"""
    var converted = params.duplicate()
    
    match action_name:
        "walk_to", "run_to":
            # 转换 {"x": 100, "y": 100} → Vector2(100, 100)
            if params.has("target"):
                var target = params["target"]
                if target is Dictionary:
                    converted["target"] = Vector2(
                        target.get("x", 0),
                        target.get("y", 0)
                    )
        
        "chase_target":
            # 目标名称验证
            if params.has("target_name"):
                converted["target_name"] = str(params["target_name"])
    
    return converted

static func create_fallback_action() -> Array[Dictionary]:
    """创建后备动作（当AI失败时）"""
    return [
        {
            "action": "idle",
            "params": {},
            "duration": 1.0
        }
    ]
```

**测试：**
```gdscript
# test/test_action_parser.gd
extends GutTest

func test_parse_walk_action():
    var response = {
        "interpretation": "去沙发",
        "actions": [
            {
                "action": "walk_to",
                "params": {"target": {"x": 100, "y": 100}},
                "duration": 2.0
            }
        ],
        "meow_response": "喵！"
    }
    
    var actions = ActionParser.parse_ai_response(response)
    assert_eq(actions.size(), 1)
    assert_eq(actions[0].action, "walk_to")
    assert_typeof(actions[0].params.target, TYPE_VECTOR2)
```

---

#### 任务2.2：集成AI推理与行为系统（0.5天）

**创建AIController类：**
```gdscript
# scripts/ai_controller.gd
class_name AIController
extends Node

@onready var llama: LlamaInference = $LlamaInference
@onready var action_queue: ActionQueue = $ActionQueue
@onready var cat_behavior: CatBehavior = $"../CatBehavior"

signal command_processing(command: String)
signal command_completed(response: String)
signal command_failed(error: String)

var is_processing: bool = false

func _ready():
    # 连接信号
    llama.inference_completed.connect(_on_inference_completed)
    llama.inference_failed.connect(_on_inference_failed)
    action_queue.queue_empty.connect(_on_actions_completed)
    
    # 加载模型
    var model_path = "res://models/qwen3-0.6b-q4_k_m.gguf"
    if llama.load_model(model_path):
        print("✓ AI模型加载成功: ", llama.get_device_info())
    else:
        push_error("✗ AI模型加载失败")

func process_command(command: String) -> void:
    """处理用户命令"""
    if is_processing:
        push_warning("正在处理命令，请稍候...")
        return
    
    if not llama.is_model_loaded():
        emit_signal("command_failed", "AI模型未加载")
        return
    
    is_processing = true
    emit_signal("command_processing", command)
    
    # 构建提示词
    var prompt = build_prompt(command)
    llama.infer(prompt)

func build_prompt(command: String) -> String:
    """构建AI提示词"""
    return """你是一只可爱的猫咪。用户说："%s"

请以JSON格式回复，包含：
{
  "interpretation": "你对指令的理解",
  "actions": [
    {"action": "walk_to", "params": {"target": {"x": 100, "y": 100}}, "duration": 2.0}
  ],
  "meow_response": "你的喵叫回复"
}

可用动作：walk_to, run_to, jump, sleep, play, idle
""" % command

func _on_inference_completed(result: String) -> void:
    """AI推理完成"""
    print("AI响应: ", result)
    
    # 解析JSON
    var json = JSON.parse_string(result)
    
    if json == null:
        push_error("JSON解析失败")
        _use_fallback()
        return
    
    # 显示喵叫回复
    if json.has("meow_response"):
        emit_signal("command_completed", json["meow_response"])
    
    # 解析并执行动作
    var actions = ActionParser.parse_ai_response(json)
    if actions.is_empty():
        actions = ActionParser.create_fallback_action()
    
    action_queue.add_actions(actions)

func _on_inference_failed(error: String) -> void:
    """AI推理失败"""
    push_error("AI推理失败: ", error)
    _use_fallback()

func _use_fallback() -> void:
    """使用后备行为"""
    emit_signal("command_completed", "喵... (不太明白)")
    action_queue.add_actions(ActionParser.create_fallback_action())

func _on_actions_completed() -> void:
    """所有动作执行完成"""
    is_processing = false
    print("✓ 所有动作执行完成")
```

---

### 模块5.3：主场景集成（1天）

#### 任务3.1：创建完整的游戏主场景（0.5天）

**场景结构：**
```
scenes/main.tscn
├── Cat (CharacterBody2D)
│   ├── Sprite2D
│   ├── AnimationPlayer
│   ├── CollisionShape2D
│   └── CatBehavior (script)
├── AIController (Node)
│   ├── LlamaInference (GDExtension)
│   └── ActionQueue (script)
├── UI (CanvasLayer)
│   ├── InputPanel
│   │   ├── InputField (TextEdit)
│   │   └── SendButton (Button)
│   └── OutputPanel
│       ├── ResponseLabel (RichTextLabel)
│       └── StatusLabel (Label)
└── Environment
    ├── Floor (StaticBody2D)
    ├── Furniture (obstacles)
    └── Background
```

**主场景脚本：**
```gdscript
# scenes/main.gd
extends Node2D

@onready var cat = $Cat
@onready var ai_controller = $AIController
@onready var input_field = $UI/InputPanel/InputField
@onready var send_button = $UI/InputPanel/SendButton
@onready var response_label = $UI/OutputPanel/ResponseLabel
@onready var status_label = $UI/OutputPanel/StatusLabel

func _ready():
    # 连接UI信号
    send_button.pressed.connect(_on_send_pressed)
    input_field.text_submitted.connect(_on_text_submitted)
    
    # 连接AI信号
    ai_controller.command_processing.connect(_on_command_processing)
    ai_controller.command_completed.connect(_on_command_completed)
    ai_controller.command_failed.connect(_on_command_failed)
    
    status_label.text = "✓ 准备就绪"

func _on_send_pressed():
    var command = input_field.text.strip_edges()
    if command.is_empty():
        return
    
    ai_controller.process_command(command)
    input_field.text = ""

func _on_text_submitted(text: String):
    _on_send_pressed()

func _on_command_processing(command: String):
    status_label.text = "⏳ AI思考中..."
    response_label.text = "用户: " + command

func _on_command_completed(response: String):
    status_label.text = "✓ 执行中..."
    response_label.text += "\n猫咪: " + response

func _on_command_failed(error: String):
    status_label.text = "✗ 失败: " + error
```

---

#### 任务3.2：测试与调试（0.5天）

**端到端测试场景：**
```gdscript
# test/test_full_integration.gd
extends GutTest

var main_scene: Node2D

func before_each():
    main_scene = load("res://scenes/main.tscn").instantiate()
    add_child_autofree(main_scene)

func test_simple_command():
    var ai_controller = main_scene.get_node("AIController")
    
    # 模拟输入
    ai_controller.process_command("走到沙发")
    
    # 等待AI响应
    await wait_for_signal(ai_controller.command_completed, 5)
    
    # 验证猫开始移动
    var cat_behavior = main_scene.get_node("Cat/CatBehavior")
    assert_ne(cat_behavior.current_state, cat_behavior.State.IDLE)

func test_fallback_on_invalid_json():
    var ai_controller = main_scene.get_node("AIController")
    
    # 模拟AI返回无效JSON
    ai_controller._on_inference_completed("invalid json")
    
    # 应该使用后备行为
    await wait_for_signal(ai_controller.command_completed, 1)
    assert_signal_emitted(ai_controller, "command_completed")
```

**手动测试清单：**
- [ ] 输入"走到那边"，观察猫是否移动
- [ ] 输入"跳一下"，观察猫是否跳跃
- [ ] 输入"去睡觉"，观察猫是否播放睡觉动画
- [ ] 输入无意义指令，观察后备行为
- [ ] 连续快速输入指令，观察队列处理
- [ ] 检查内存使用和帧率

---

## 📊 阶段5完成标准

### 功能标准
- [ ] 猫咪有完整的动画系统（至少6种动画）
- [ ] 动作队列正确执行多个动作
- [ ] 状态机正确转换状态
- [ ] AI响应能正确解析为动作
- [ ] 后备机制在AI失败时工作
- [ ] UI显示AI响应和状态

### 性能标准
- [ ] 60fps稳定运行
- [ ] AI响应时间<2秒
- [ ] 动作执行流畅无卡顿

### 代码质量
- [ ] 所有核心类有单元测试
- [ ] 端到端集成测试通过
- [ ] 代码有清晰的注释
- [ ] 遵循GDScript风格指南

---

## 🎯 阶段2：数据准备与模型微调（可选，4-5天）

> **注意：** 这是可选阶段。当前使用通用Qwen模型也能工作，微调后会更"猫化"。

### 模块2.1：训练数据生成（2天）

#### 数据格式设计
```json
{
  "instruction": "去抓蝴蝶",
  "response": {
    "interpretation": "用户想让我抓蝴蝶",
    "actions": [
      {
        "action": "run_to",
        "params": {"target": {"x": 200, "y": 100}},
        "duration": 2.0
      },
      {
        "action": "jump",
        "params": {"height": 60},
        "duration": 0.5
      }
    ],
    "meow_response": "喵！（蝴蝶在哪？）"
  }
}
```

#### 数据生成脚本
```python
# models/generate_training_data.py
import json
import random

# 基础指令模板
BASE_COMMANDS = [
    "走到{location}",
    "去{location}",
    "跑到{location}",
    "跳到{location}上",
    "睡觉",
    "玩耍",
    "抓{target}"
]

LOCATIONS = ["沙发", "窗台", "猫窝", "那边", "这里"]
TARGETS = ["蝴蝶", "老鼠", "玩具", "球"]

CAT_QUIRKS = [
    "突然舔毛",
    "打个滚",
    "伸懒腰",
    "完全无视"
]

def generate_standard_response(command):
    """生成标准响应"""
    # 根据命令类型生成动作
    # ...实现逻辑...
    pass

def add_cat_personality(response, ignore_chance=0.2):
    """添加猫的个性"""
    if random.random() < ignore_chance:
        # 20%概率无视指令
        response["actions"] = []
        response["interpretation"] = "（不想动）"
        response["meow_response"] = "喵...（懒得理你）"
    elif random.random() < 0.3:
        # 30%概率添加额外动作
        extra_action = {
            "action": random.choice(["groom", "stretch", "roll"]),
            "params": {},
            "duration": 1.0
        }
        response["actions"].append(extra_action)
    
    return response

def generate_dataset(size=500):
    """生成完整数据集"""
    dataset = []
    # ...生成逻辑...
    return dataset

if __name__ == "__main__":
    data = generate_dataset(500)
    with open("cat_training_data.json", "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
```

#### 任务清单
- [ ] 编写数据生成脚本
- [ ] 生成500条训练数据
- [ ] 验证JSON格式
- [ ] 人工审核样本质量
- [ ] 划分训练/验证集（90/10）

---

### 模块2.2：LoRA微调（2-3天）

#### 环境准备
```bash
# 安装依赖
pip install transformers peft datasets bitsandbytes

# 下载基础模型
huggingface-cli download Qwen/Qwen2.5-1.5B-Instruct
```

#### 训练脚本
```python
# models/train_lora.py
from transformers import AutoTokenizer, AutoModelForCausalLM, TrainingArguments
from peft import LoraConfig, get_peft_model, TaskType
from datasets import load_dataset

# 加载模型
model_name = "Qwen/Qwen2.5-1.5B-Instruct"
tokenizer = AutoTokenizer.from_pretrained(model_name)
model = AutoModelForCausalLM.from_pretrained(
    model_name,
    device_map="auto",
    load_in_8bit=True
)

# LoRA配置
lora_config = LoraConfig(
    r=16,
    lora_alpha=32,
    target_modules=["q_proj", "v_proj", "k_proj", "o_proj"],
    lora_dropout=0.05,
    bias="none",
    task_type=TaskType.CAUSAL_LM
)

model = get_peft_model(model, lora_config)

# 训练参数
training_args = TrainingArguments(
    output_dir="./cat-lora-output",
    num_train_epochs=3,
    per_device_train_batch_size=4,
    gradient_accumulation_steps=4,
    learning_rate=2e-4,
    fp16=True,
    logging_steps=10,
    save_steps=100,
    evaluation_strategy="steps",
    eval_steps=100,
)

# 开始训练
# ...
```

#### 导出为GGUF
```bash
# 转换为GGUF格式
python convert_hf_to_gguf.py \
    --model ./cat-lora-output \
    --outfile cat-qwen-1.5b.gguf \
    --outtype q4_k_m
```

---

## 📅 推荐时间表

### 第1周（4-5天）：核心行为系统
```
Day 1: 猫咪动画和基础场景
  ├── 上午：创建猫咪Sprite和动画
  └── 下午：配置AnimationPlayer和AnimationTree

Day 2: 动作队列和状态机
  ├── 上午：实现ActionQueue类
  └── 下午：实现CatBehavior状态机

Day 3: JSON解析器
  ├── 上午：实现ActionParser类
  └── 下午：实现AIController类

Day 4: 主场景集成
  ├── 上午：搭建完整主场景
  ├── 下午：UI和信号连接
  └── 晚上：端到端测试

Day 5（可选）：完善和优化
  └── 调试、优化、添加更多动作类型
```

### 第2周（可选）：数据与微调
```
Day 6-7: 数据准备
  └── 生成训练数据，人工审核

Day 8-9: 模型微调
  └── LoRA训练和导出

Day 10: 集成微调模型
  └── 测试微调模型效果
```

---

## 🎯 立即开始

### 今天可以做的事情：

1. **创建猫咪场景**
   ```bash
   # 创建目录
   mkdir -p scenes/cat
   mkdir -p scenes/cat/animations
   mkdir -p scripts
   mkdir -p test
   ```

2. **编写第一个脚本**
   - 创建 `scenes/cat/cat.gd`
   - 实现基础的Cat类

3. **测试现有AI**
   - 打开 `scenes/test_gdextension.tscn`
   - 测试不同的中文提示词
   - 观察AI的JSON输出格式

---

## 📚 参考资源

### Godot文档
- [CharacterBody2D](https://docs.godotengine.org/en/stable/classes/class_characterbody2d.html)
- [AnimationPlayer](https://docs.godotengine.org/en/stable/classes/class_animationplayer.html)
- [Signals](https://docs.godotengine.org/en/stable/getting_started/step_by_step/signals.html)

### 测试框架
- [GUT (Godot Unit Test)](https://github.com/bitwes/Gut) - 推荐用于单元测试

### LoRA微调
- [PEFT文档](https://huggingface.co/docs/peft)
- [Qwen2.5模型](https://huggingface.co/Qwen)

---

## 💡 关键提示

1. **先做简单的**：不要一开始就追求完美的AI，先让基础系统跑起来
2. **模块化开发**：每个类都应该可以独立测试
3. **频繁测试**：每完成一个小功能就测试一次
4. **提交代码**：每天结束时提交git（如果使用版本控制）
5. **记录问题**：遇到问题记录下来，方便后续优化

---

## 📝 进度追踪

可以在这里记录每天的进度：

```markdown
### Day 1 - 2025-12-XX
- [ ] 创建猫咪场景
- [ ] 实现基础动画
- [ ] 遇到的问题：...
- [ ] 解决方案：...

### Day 2 - 2025-12-XX
- [ ] ...
```

---

**准备好了吗？让我们开始构建AI猫咪的行为系统吧！** 🐱✨

有任何问题，随时查看 README.md 和 FEATURE_COMPLETE.md 获取llama.cpp的使用帮助。

