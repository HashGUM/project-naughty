# 🐱 3D白盒原型场景使用指南

## 📁 文件结构

```
scenes/3d_world/
└── main_3d.tscn          # 主3D场景

scripts/
├── main_3d.gd            # 主场景控制器
├── cat_3d.gd             # 3D猫咪移动控制器
├── camera_3d.gd          # 相机控制器
├── interaction_area.gd   # 交互区域检测
└── ai_controller_3d.gd   # AI控制器（可选）
```

## 🎮 如何使用

### 1. 打开场景
在Godot编辑器中打开 `scenes/3d_world/main_3d.tscn`

### 2. 场景内容
- **灰色地面**：20x20米的平面
- **橙色方块**：小屋（位于 x:6, z:6）
- **绿色方块**：花园（位于 x:-6, z:-6）
- **米色方块**：猫咪（可移动）

### 3. 控制方式

#### 相机控制
- **鼠标中键拖拽**：旋转相机
- **鼠标滚轮**：缩放视角

#### 命令输入
在左上角面板输入命令：
- `去小屋` / `去房子` / `去家`
- `去花园` / `去garden`
- `回中心` / `回中间`

### 4. 两种运行模式

#### 模式1：简单规则匹配（默认）
- 不需要加载AI模型
- 关键词匹配
- 快速响应
- 适合测试基础功能

**设置方法**：
在场景根节点 `Main3D` 的属性面板中，`use_ai` 设为 `false`

#### 模式2：AI智能理解
- 使用llama.cpp推理
- 自然语言理解
- 更灵活的交互
- 需要加载模型

**设置方法**：
1. 确保 `models/qwen3-0.6b-q4_k_m.gguf` 存在
2. 在场景根节点 `Main3D` 的属性面板中，`use_ai` 设为 `true`

## 🔧 技术实现

### 导航系统
使用Godot的 `NavigationRegion3D` + `NavigationAgent3D`：
- 自动寻路避障
- 平滑移动
- 支持动态障碍物（未来扩展）

### 交互系统
使用 `Area3D` 检测猫咪进入特定区域：
- 触发事件
- 显示反馈
- 可扩展更多交互

### AI集成
通过GDExtension调用llama.cpp：
- 异步推理
- JSON响应解析
- 后备机制

## 📝 扩展建议

### 1. 添加更多位置
在 `main_3d.gd` 中添加：
```gdscript
var locations = {
    "house": Vector3(6, 0.5, 6),
    "garden": Vector3(-6, 0.5, -6),
    "center": Vector3(0, 0.5, 0),
    "pond": Vector3(8, 0.5, -8),  # 新增池塘
}
```

### 2. 添加动画
替换 `Cat` 节点的Mesh为AnimatedSprite3D或模型，在 `cat_3d.gd` 中添加动画播放

### 3. 添加更多交互
在交互区域添加：
- 吃饭
- 喝水
- 玩耍
- 睡觉

### 4. 改进AI提示词
在 `ai_controller_3d.gd` 的 `build_prompt()` 中优化提示词格式

## 🐛 常见问题

### Q: 猫咪不移动？
A: 检查：
1. NavigationRegion3D是否已烘焙导航网格
2. Cat节点是否有NavigationAgent3D
3. 目标位置是否在导航网格内

### Q: 相机不跟随？
A: 确保Camera3D脚本的target设置正确，默认自动查找Cat节点

### Q: AI模式无响应？
A: 检查：
1. 模型文件路径是否正确
2. 控制台是否有加载错误
3. LlamaInference节点是否存在

## 🎯 下一步开发

参考 `docs/NEXT_PHASE_PLAN.md` 中的：
- [ ] 添加更多猫咪动作（跳跃、伸懒腰、舔毛）
- [ ] 实现动作队列系统
- [ ] 添加猫咪状态机（饥饿、疲劳、快乐）
- [ ] 数据收集与模型微调
- [ ] 优化AI提示词和响应格式

## 📚 参考资料

- [Godot 3D导航文档](https://docs.godotengine.org/en/stable/tutorials/navigation/navigation_introduction_3d.html)
- [NavigationAgent3D API](https://docs.godotengine.org/en/stable/classes/class_navigationagent3d.html)
- [项目主README](../../README.md)

