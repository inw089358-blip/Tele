# ⚙️ Godot 4.6 开发规范文档

> **版本**: v1.0 | **引擎**: Godot 4.6 | **语言**: GDScript
> 本文档基于 Godot 官方文档浓缩，结合 **TeleTaRot** 项目需求定制。

---

## 一、项目目录结构规范

### 1.1 标准目录树

```
Project/
├── project.godot                  # 项目配置文件 (不手动编辑)
├── .editorconfig                  # 编辑器配置
├── .gitignore                     # Git忽略规则
├── icon.svg                       # 项目图标
│
├── scenes/                        # 场景文件 (.tscn)
│   ├── main.tscn                  #   主菜单场景
│   ├── game.tscn                  #   战斗主场景
│   ├── character_select.tscn      #   角色选择场景
│   ├── stage_select.tscn          #   关卡选择场景
│   ├── reward_screen.tscn         #   奖励选择场景
│   ├── game_over.tscn             #   结算画面
│   │
│   ├── entities/                  #   实体场景
│   │   ├── player.tscn            #     玩家(基类)
│   │   ├── enemy.tscn             #     敌人(基类)
│   │   └── projectile.tscn        #     弹幕(基类)
│   │
│   ├── enemies/                   #   敌人具体场景
│   │   ├── glitch_blob.tscn       #     故障史莱姆
│   │   ├── static_sprite.tscn     #     静电精灵
│   │   ├── pixel_stalker.tscn     #     像素潜行者
│   │   ├── data_corrupter.tscn    #     数据腐蚀者
│   │   └── signal_jammer.tscn     #     信号干扰器
│   │
│   ├── bosses/                    #   BOSS场景
│   │   └── dream_watcher.tscn     #     梦境守望者
│   │
│   └── ui/                        #   UI组件场景
│       ├── hud.tscn               #     战斗HUD
│       ├── health_bar.tscn        #     血条
│       ├── xp_bar.tscn            #     经验条
│       ├── reward_card.tscn       #     奖励卡片
│       └── damage_number.tscn     #     伤害数字
│
├── scripts/                       # 脚本文件 (.gd)
│   ├── autoload/                  #   自动加载(全局单例)
│   │   ├── game_manager.gd        #     游戏流程管理器
│   │   ├── event_bus.gd           #     全局事件总线
│   │   ├── audio_manager.gd       #     音频管理器
│   │   └── save_system.gd         #     存档系统
│   │
│   ├── entities/                  #   实体脚本
│   │   ├── player.gd              #     玩家基类
│   │   ├── enemy.gd               #     敌人基类
│   │   └── projectile.gd          #     弹幕基类
│   │
│   ├── characters/                #   角色脚本
│   │   ├── the_fool.gd            #     愚者
│   │   ├── the_chariot.gd         #     战车
│   │   └── the_hanged_man.gd      #     倒吊人
│   │
│   ├── enemies/                   #   敌人脚本
│   │   ├── glitch_blob.gd         #     故障史莱姆
│   │   ├── static_sprite.gd       #     静电精灵
│   │   ├── pixel_stalker.gd       #     像素潜行者
│   │   ├── data_corrupter.gd      #     数据腐蚀者
│   │   └── signal_jammer.gd       #     信号干扰器
│   │
│   ├── systems/                   #   系统脚本
│   │   ├── combat_system.gd       #     战斗系统
│   │   ├── wave_manager.gd        #     波次管理器
│   │   ├── upgrade_system.gd      #     升级系统
│   │   ├── spawn_manager.gd       #   生成管理器
│   │   ├── damage_number_spawner.gd # 伤害数字生成
│   │   └── experience_manager.gd  #     经验管理
│   │
│   ├── components/                #   组件脚本(可复用行为)
│   │   ├── health_component.gd    #     血量组件
│   │   ├── knockback_component.gd #     击退组件
│   │   ├── state_machine.gd       #     状态机组件
│   │   └── pool_component.gd      #     对象池组件
│   │
│   └── ui/                        #   UI脚本
│       ├── hud.gd                 #     HUD逻辑
│       ├── health_bar.gd          #     血条逻辑
│       ├── reward_screen.gd       #     奖励选择逻辑
│       ├── main_menu.gd           #     主菜单逻辑
│       └── crt_effect.gd          #     CRT后处理效果
│
├── resources/                     # 资源数据 (.tres/.tres)
│   ├── characters/                #   角色数据资源
│   │   ├── fool_data.tres         #     愚者属性数据
│   │   ├── chariot_data.tres      #     战车属性数据
│   │   └── hanged_man_data.tres   #     倒吊人属性数据
│   │
│   ├── enemies/                   #   敌人数据资源
│   │   ├── glitch_blob_data.tres  #     史莱姆数据
│   │   └── ...                    #     (其他敌人)
│   │
│   ├── upgrades/                  #   升级数据资源
│   │   ├── atk_up.tres            #     攻击强化
│   │   └── ...
│   │
│   └── stages/                    #   关卡配置资源
│       ├── stage_001.tres         #     第1关配置
│       └── ...
│
├── assets/                        # 艺术资产
│   ├── sprites/                   #   精灵图
│   │   ├── characters/            #     角色精灵
│   │   ├── enemies/               #     敌人精灵
│   │   ├── effects/               #     特效精灵
│   │   └── ui/                    #     UI精灵
│   │
│   ├── audio/                     #   音频
│   │   ├── bgm/                   #     背景音乐(.ogg/.mp3)
│   │   └── sfx/                   #     音效(.wav/.ogg)
│   │
│   └── fonts/                     #   字体
│       ├── press_start_2p.ttf     #     像素字体
│       └── ...
│
├── shaders/                       # 着色器 (.gdshader / .tres)
│   ├── crt_effect.gdshader        #   CRT后处理着色器
│   └── glitch_effect.gdshader     #   故障效果着色器
│
├── docs/                          # 设计文档
│   ├── GDD_游戏设计文档.md
│   ├── UI与视觉风格规范.md
│   ├── 角色系统设计.md
│   ├── 关卡与流程设计.md
│   ├── 数值模型设计.md
│   └── godot_开发规范.md          # ← 本文档
│
└── UI/                            # AI美术提示词
```

### 1.2 文件命名规则

```
类型          │ 规则                    │ 示例
──────────────┼─────────────────────────┼──────────────────────
场景文件      │ snake_case              │ player.tscn
脚本文件      │ snake_case              │ player.gd
类名(class_name)│ PascalCase              │ class_name Player
节点名        │ PascalCase              │ Player, HealthBar
函数名        │ snake_case              │ func take_damage()
变量名        │ snake_case              │ var current_health
私有变量      │ _前缀 + snake_case      │ var _cooldown_timer
信号名        │ snake_case + 过去式      │ signal died, signal hp_changed
常量          │ CONSTANT_CASE           │ const MAX_HP = 100
枚举类型      │ PascalCase              │ enum ElementType
枚举成员      │ CONSTANT_CASE           │ {FIRE, ICE, POISON}
资源文件       │ snake_case             │ fool_data.tres
```

---

## 二、GDScript 编码规范

### 2.1 格式化规则

```
═══════════════════════════════════════════════════════════
  基于 Godot 官方 GDScript Style Guide (Godot 4.x)
═══════════════════════════════════════════════════════════

缩进: Tab (1个Tab = 1层缩进，编辑器默认设置)
行宽: ≤ 100字符 (尽量≤80字符)
换行: LF (Unix风格)
编码: UTF-8 无BOM
文件结尾: 恰好1个空行
```

#### 缩进示例

```gdscript
# ✅ 正确 - 标准缩进
for i in range(10):
	print("hello")

# ❌ 错误 - 使用了空格代替Tab
for i in range(10):
	print("hello")
```

#### 续行缩进（2个Tab级别）

```gdscript
# ✅ 正确 - 续行使用2级缩进区分
effect.interpolate_property(sprite, "transform/scale",
		sprite.get_scale(), Vector2(2.0, 2.0), 0.3,
		Tween.TRANS_QUAD, Tween.EASE_OUT)

# ❌ 错误 - 续行只用了1级缩进
effect.interpolate_property(sprite, "transform/scale",
	sprite.get_scale(), Vector2(2.0, 2.0), 0.3,
	Tween.TRANS_QUAD, Tween.EASE_OUT)
```

#### 数组/字典/枚举的尾逗号

```gdscript
# ✅ 正确 - 有尾逗号（便于diff和添加新元素）
var party = [
	"Godot",
	"Godette",
	"Steve",
]

var character_dict = {
	"Name": "Bob",
	"Age": 27,
}

enum Tile {
	BRICK,
	FLOOR,
	SPIKE,
}

# ❌ 错误 - 缺少尾逗号
var party = [
	"Godot",
	"Godette"
]
```

### 2.2 运算符和空格

```gdscript
# ✅ 正确
position.x = 5
position.y = target_position.y + 10
dict["key"] = value
my_array = [4, 5, 6]
if is_colliding():
	queue_free()

# ❌ 错误
position.x=5
position.y = mpos.y+10
dict ["key"] = value
if (is_colliding()):  # 不必要的括号
	queue_free()
```

#### 布尔运算符 — 使用英文单词

```gdscript
# ✅ 正确 - 使用 and/or/not
if (foo and bar) or not baz:
	print("condition is true")

# ❌ 错误 - 不使用 && / || / !
if foo && bar || !baz:
	print("condition is true")
```

#### 引号 — 默认双引号

```gdscript
# ✅ 正确
print("hello world")
print('hello "world"')  # 仅当可减少转义时用单引号

# 浮点数不要省略前导/尾随零
var float_val = 0.234   # ✅
var other_float = 13.0   # ✅
# var bad = .234         # ❌
# var bad = 13.          # ❌

# 大数字使用下划线分隔
var large_num = 1_234_567_890  # ✅
```

### 2.3 类型标注（静态类型）

```gdscript
# 推荐使用 := 进行类型推断（类型明确时）
var direction := Vector3(1, 2, 3)  # ✅ 明确推断为Vector3

# 类型模糊时必须显式声明
var health: int = 0                 # ✅ 可能是int或float
# var health := 0                   # ❌ 歧义

# get_node()返回值需要显式类型或as转换
@onready var health_bar: ProgressBar = $UI/LifeBar  # ✅ 显式类型
# @onready var health_bar := $UI/LifeBar           # ❌ 推断为Node

# 函数返回类型声明
func heal(amount: int) -> void:
	health += amount

func calculate_damage() -> float:
	return base_damage * multiplier
```

### 2.4 代码组织顺序（Code Order）

每个 GDScript 文件**严格按以下顺序**组织：

```
01. @tool / @icon / @static_unload        (注解)
02. class_name                              (类名注册)
03. extends                                 (继承)
04. ## 文档注释                             (docstring)

05. signal                                  (信号声明)
06. enum                                    (枚举)
07. const                                   (常量)
08. static var                              (静态变量)
09. @export var                             (导出变量/检查器可见)
10. var                                     (普通成员变量)
11. @onready var                            (就绪时初始化变量)

12. _static_init()                          (静态初始化)
13. static func                             (静态方法)

14. 内置虚方法回调 (按顺序):                 (引擎生命周期)
	 _init()
	 _enter_tree()
	 _ready()
	 _process()
	 _physics_process()
	 (其他虚方法...)

15. 公共方法                                (public methods)
16. 私有方法                                (private methods, _前缀)
17. 内部类                                  (inner classes)
```

#### 完整模板示例

```gdscript
## 玩家角色基类。
##
## 处理移动、攻击、升级等核心游戏逻辑。
## 所有具体角色(愚者/战车/倒吊人)继承此类。
class_name Player
extends CharacterBody2D

signal hp_changed(old_value: int, new_value: int)
signal level_changed(new_level: int)
signal died
signal experience_gained(amount: int)

enum State { IDLE, MOVING, ATTACKING, DEAD }

const BASE_SPEED: float = 200.0
const INVINCIBLE_DURATION: float = 0.5

@export_group("基础属性")
@export var max_hp: float = 100.0
@export var move_speed: float = 200.0
@export var base_damage: float = 10.0

@export_group("攻击属性")
@export var attack_speed: float = 1.0
@export var attack_range: float = 150.0
@export var projectile_count: int = 1

var current_hp: float:
	set(value):
		var old := current_hp
		current_hp = clamp(value, 0.0, max_hp)
		hp_changed.emit(old, current_hp)
		if current_hp <= 0:
			died.emit()

var current_level: int = 1
var current_xp: float = 0.0
var _is_invincible: bool = false
var _direction: Vector2 = Vector2.ZERO

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var attack_timer: Timer = $AttackTimer


func _init():
	add_to_group("player")


func _ready():
	current_hp = max_hp
	attack_timer.timeout.connect(_on_attack_timeout)


func _physics_process(delta: float):
	_handle_movement(delta)
	_handle_auto_attack()


func _handle_movement(delta: float) -> void:
	var input := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	if input.length() > 0.1:
		_direction = input.normalized()
	velocity = _direction * move_speed
		move_and_slide()


func take_damage(amount: float) -> void:
	if _is_invincible:
		return
	current_hp -= amount
	_start_invincibility()


func gain_experience(amount: float) -> void:
	current_xp += amount
	experience_gained.emit(amount)
	_check_level_up()


func _check_level_up() -> void:
	var required := GameManager.get_xp_for_level(current_level + 1)
	while current_xp >= required:
		current_xp -= required
		current_level += 1
		level_changed.emit(current_level)
		required = GameManager.get_xp_for_level(current_level + 1)


func _start_invincibility() -> void:
	_is_invincible = true
	await get_tree().create_timer(INVINCIBLE_DURATION).timeout
	_is_invincible = false


func _on_attack_timeout() -> void:
	CombatSystem.fire_projectiles(self)
```

---

## 三、场景与节点架构规范

### 3.1 场景优先组合原则（Scene-First Composition）

> **核心理念**: Godot 的场景(Scene)是其最强大的特性。优先使用场景组合而非深层继承。
> 参考: Godot官方文档 "Node Composition vs Inheritance"

```
❌ 反模式 - 深层继承链:
BaseEntity → LivingEntity → Character → Player → TheFool
										→ Enemy → GlitchBlob

✅ 推荐模式 - 场景组合:
Player (Area2D 场景)
├── Sprite (AnimatedSprite2D)
├── Collision (CollisionShape2D)
├── AttackTimer (Timer)
└── Scripts: player.gd → 具体角色覆盖属性即可
```

### 3.2 根节点选择指南

| 功能需求     | 推荐根节点                         | 说明            |
| ------------ | ---------------------------------- | --------------- |
| 玩家角色     | `CharacterBody2D`                  | 内置移动/碰撞   |
| 敌人(有物理) | `CharacterBody2D` 或 `RigidBody2D` | 需要碰撞响应    |
| 敌人(简单)   | `Area2D`                           | 只需重叠检测    |
| 弹幕/投射物  | `Area2D`                           | 高频创建销毁    |
| UI容器       | `Control` / `CanvasLayer`          | UI层级管理      |
| 纯逻辑节点   | `Node`                             | 无渲染需求      |
| BOSS         | `CharacterBody2D`                  | 复杂行为+多阶段 |

### 3.3 标准玩家场景结构

```
Player (CharacterBody2D) ← player.gd
├── AnimatedSprite2D      ← 精灵动画
│   └── SpriteFrames      ← 动画帧资源
├── CollisionShape2D      ← 碰撞形状 (CapsuleShape2D)
├── Area2D (PickupRange)  ← 拾取范围检测
│   └── CollisionShape2D  ← 圆形拾取区域
├── Timer (AttackTimer)   ← 攻击冷却计时器
└── AudioStreamPlayer2D   ← 受伤音效
```

### 3.4 标准敌人场景结构

```
Enemy (CharacterBody2D) ← enemy.gd (基类)
├── AnimatedSprite2D      ← 敌人精灵
├── CollisionShape2D      ← 碰撞体
├── Area2D (HitBox)       ← 受击检测区域
│   └── CollisionShape2D
├── Timer (AI_Timer)      ← AI决策计时器
└── GPUParticles2D        ← 死亡特效
```

### 3.5 标准弹幕场景结构

```
Projectile (Area2D) ← projectile.gd
├── Sprite2D           ← 弹幕外观
├── CollisionShape2D   ← 命中判定
├── VisibilityNotifier2D ← 屏幕外自动回收
└── Timer (Lifetime)   ← 生存时间限制
```

### 3.6 组(Group)的使用规范

```gdscript
# 在 _init() 或 _ready() 中注册组
func _ready():
	add_to_group("player")        # 玩家组
	add_to_group("damageable")    # 可受伤对象组

# 全局查询
var enemies := get_tree().get_nodes_in_group("enemy")
var player := get_tree().get_first_node_in_group("player")

# 项目预定义组:
# "player"       - 玩家
# "enemy"        - 所有敌人
# "projectile"    - 所有弹幕
# "pickup"       - 可拾取物品
# "damageable"   - 可被伤害的对象
# "obstacle"     - 障碍物(阻挡视线/弹幕)
```

---

## 四、信号(Signal)通信规范

### 4.1 信号命名与定义

```gdscript
# 命名规则: snake_case + 过去式 (表示事件已发生)
signal hp_changed(old_value: int, new_value: int)
signal died
signal leveled_up(new_level: int)
signal upgrade_selected(upgrade_id: String)
signal wave_completed(wave_number: int)
signal boss_phase_changed(phase: int)

# 参数命名要有意义，调用者能理解语义
signal enemy_spawned(enemy: Enemy, position: Vector2)
signal damage_dealt(target: Node, amount: float, is_crit: bool)
```

### 4.2 连接方式选择

```
连接方式              │ 适用场景                      │ 解耦程度
─────────────────────┼──────────────────────────────┼──────────
编辑器Signals面板     │ 场景内固定连接(如Button→UI)    │ 低
_ready()代码连接      │ 同一脚本内的父子节点            │ 中
EventBus全局总线      │ 跨系统的松耦合通信              │ 高
```

#### 方式一: 编辑器连接（推荐用于UI）

在编辑器中选中节点 → Signals面板 → 双击信号 → 选择目标节点

```gdscript
# 编辑器自动生成的回调方法 (命名约定: _on_节点名_信号名)
func _on_button_pressed():
	_start_game()

func _on_player_hp_changed(old_value: int, new_value: int) -> void:
	health_bar.value = new_value
```

#### 方式二: 代码连接（推荐用于运行时动态连接）

```gdscript
func _ready():
	# Godot 4.x 新语法: 直接传递Callable
	player.hp_changed.connect(_on_player_hp_changed)
	player.died.connect(_on_player_died)

	# Lambda表达式 (一次性/简单逻辑)
	button.pressed.connect(func():
		_apply_upgrade(selected_upgrade)
	)

	# 单次触发连接
	boss.died.connect(_on_boss_defeated, CONNECT_ONE_SHOT)
```

#### 方式三: EventBus 全局事件总线（跨系统通信）

```gdscript
# event_bus.gd (Autoload)
extends Node

signal game_paused
signal game_resumed
signal scene_changing(target_scene: String)
signal player_took_damage(amount: float)
signal reward_selection_opened(choices: Array)
signal crt_intensity_changed(level: float)


# 使用方:
# 发送:
EventBus.player_took_damage.emit(15.0)

# 接收:
func _ready():
	EventBus.player_took_damage.connect(_show_damage_vignette)
```

### 4.3 信号生命周期管理

```gdscript
# ✅ 正确: 在_exit_tree中断开动态连接
extends Node
var _connections: Array[SignalConnection] = []

func _ready():
	_connections.append(some_signal.connect(_callback))

func _exit_tree():
	for conn in _connections:
		if conn.is_valid():
			conn.disconnect()
	_connections.clear()

# ⚠️ 注意: 编辑器中连接的信号由引擎管理生命周期
# 只有代码中 connect() 的才需要手动断开
```

### 4.4 信号反模式

```gdscript
# ❌ 不要在 _process 中高频发射信号
func _process(delta):
	some_signal.emit()  # 每帧发射! 性能灾难!

# ❌ 不要用字符串形式连接 (Godot 4已弃用)
connect("hp_changed", self, "_on_hp_changed")  # 旧语法

# ✅ 使用新的类型安全语法
hp_changed.connect(_on_hp_changed)
```

---

## 五、自动加载(Autoload)规范

### 5.1 Autoload 注册清单

本项目使用的Autoload列表:

```
顺序 │ 名称            │ 路径                           │ 用途
─────┼─────────────────┼───────────────────────────────┼──────────────────
  1   │ EventBus        │ res://scripts/autoload/event_bus.gd    │ 全局事件总线
  2   │ GameManager     │ res://scripts/autoload/game_manager.gd │ 游戏流程控制
  3   │ AudioManager    │ res://scripts/autoload/audio_manager.gd │ 音频统一管理
  4   │ SaveSystem       │ res://scripts/autoload/save_system.gd   │ 存档读写
```

### 5.2 各Autoload职责边界

```gdscript
# ═══════════════════════════════════════════════════
# EventBus.gd - 纯信号中继站
# 职责: 仅定义和转发信号，不含业务逻辑
# ═══════════════════════════════════════════════════
extends Node

signal game_state_changed(from: GameState, to: GameState)
signal player_spawned(player: Player)
signal player_died()
signal experience_gained(amount: float)
signal level_up(new_level: int)
signal wave_started(wave_id: int)
signal wave_cleared(wave_id: int)
signal boss_phase_entered(phase: int)
signal reward_offered(choices: Array[UpgradeData])
signal reward_selected(upgrade: UpgradeData)
signal stage_cleared(stage_id: String)
signal game_over(is_victory: bool)
signal crt_glitch_trigger(intensity: float)
```

```gdscript
# ═══════════════════════════════════════════════════
# GameManager.gd - 游戏状态机
# 职责: 管理游戏状态转换、当前关卡信息、暂停/恢复
# ═══════════════════════════════════════════════════
extends Node

enum GameState { MENU, CHARACTER_SELECT, STAGE_SELECT, PLAYING,
				 PAUSED, REWARD, STAGE_CLEAR, GAME_OVER, VICTORY }

var current_state: GameState = GameState.MENU:
	set(value):
		if current_state != value:
			var old := current_state
			current_state = value
			EventBus.game_state_changed.emit(old, value)
			_on_state_changed(old, value)

var current_stage_id: String = ""
var current_wave: int = 0
var selected_character: String = ""

func start_game(character_id: String) -> void:
	selected_character = character_id
	change_scene_to_file("res://scenes/game.tscn")
	current_state = GameState.PLAYING

func pause_game() -> void:
	get_tree().paused = true
	current_state = GameState.PAUSED

func resume_game() -> void:
	get_tree().paused = false
	current_state = GameState.PLAYING

func _on_state_changed(from: GameState, to: GameState) -> void:
	match to:
		GameState.PLAYING:
			get_tree().paused = false
		GameState.PAUSED:
			pass  # 由upgrade_system处理
		GameState.GAME_OVER:
			await get_tree().create_timer(1.5).timeout
			change_scene_to_file("res://scenes/game_over.tscn")
```

```gdscript
# ═══════════════════════════════════════════════════
# AudioManager.gd - 音频管理
# 职责: 统一播放音效/BGM，避免AudioStreamPlayer冲突
# ═══════════════════════════════════════════════════
extends Node

var _sfx_players: Array[AudioStreamPlayer2D] = []
var _bgm_player: AudioStreamPlayer
var _sfx_bus: StringName = &"SFX"
var _bgm_bus: StringName = &"BGM"

func _ready():
	_create_sfx_pool(16)
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = _bgm_bus
	add_child(_bgm_player)

func play_sfx(stream: AudioStream, volume_db: float = 0.0) -> void:
	var player := _get_available_player()
	player.stream = stream
	player.volume_db = volume_db
	player.play()

func play_bgm(stream: AudioStream) -> void:
	if _bgm_player.stream == stream and _bgm_player.playing:
		return
	_bgm_player.stream = stream
	_bgm_player.play()

func stop_bgm(fade_duration: float = 0.0) -> void:
	if fade_duration > 0:
		var tween := create_tween()
		tween.tween_property(_bgm_player, "volume_db", -40.0, fade_duration)
		tween.tween_callback(_bgm_player.stop)
	else:
		_bgm_player.stop()

func _create_sfx_pool(size: int) -> void:
	for i in size:
		var p := AudioStreamPlayer2D.new()
		p.bus = _sfx_bus
		add_child(p)
		_sfx_players.append(p)

func _get_available_player() -> AudioStreamPlayer2D:
	for p in _sfx_players:
		if not p.playing:
			return p
	return _sfx_players[0]  # 池满时复用第一个
```

### 5.3 Autoload 使用禁忌

```
⛔ 不要做的事:
· 不要在 Autoload 中 free()/queue_free() 节点 → 引擎崩溃
· 不要把所有逻辑都塞进 Autoload → 违背场景优先原则
· 不要在 Autoload 中持有对场景节点的硬引用 → 切场景后引用失效
· 不要滥用 Autoload 作为全局数据存储 → 应使用 Resource 或 EventBus

✅ 应该做的事:
· Autoload 仅用于真正需要全局访问的系统
· 优先考虑 class_name + static func 创建工具库
· 跨场景持久数据用 Resource 或 user:// 存储系统
```

---

## 六、状态机(State Machine)实现模式

### 6.1 基础FSM组件

```gdscript
# state_machine.gd - 可复用的有限状态机组件
class_name StateMachine extends Node

signal state_changed(previous: State, new: State)

@export var initial_state: State

var current_state: State
var states: Dictionary = {}


func _ready() -> void:
	for child in get_children():
		if child is State:
			states[child.name] = child
			child.state_machine = child.get_parent() if child.get_parent() is StateMachine else self
			child.transition_requested.connect(_on_transition_requested)
	if initial_state:
		current_state = initial_state
		current_state.enter()


func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_process(delta)


func _on_transition_requested(target_state_name: String, msg: Dictionary = {}) -> void:
	var target: State = states.get(target_state_name)
	if not target:
		push_warning("State not found: %s" % target_state_name)
		return
	var previous := current_state
	current_state.exit()
	current_state = target
	current_state.enter(msg)
	state_changed.emit(previous, current_state)
```

### 6.2 State 基类

```gdscript
# state.gd - 状态基类
class_name State extends Node

signal transition_requested(state_name: String, msg: Dictionary = {})

var state_machine: StateMachine


func enter(msg: Dictionary = {}) -> void:
	pass


func exit() -> void:
	pass


func physics_process(delta: float) -> void:
	pass


func unhandled_input(event: InputEvent) -> void:
	pass
```

### 6.3 应用示例：玩家状态机

```
PlayerStateMachine (StateMachine)
├── Idle (State)         - 待机
├── Move (State)         - 移动
├── Attack (State)       - 攻击
├── Hurt (State)         - 受伤(短暂无敌)
└── Dead (State)         - 死亡
```

```gdscript
# idle.gd - 待机状态
class_name IdleState extends State

func physics_process(delta: float) -> void:
	var input := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	if input.length() > 0.1:
		transition_requested.emit("Move")


# hurt.gd - 受伤状态
class_name HurtState extends State

var _timer: float = 0.0
const DURATION: float = 0.3

func enter(msg: Dictionary = {}) -> void:
	_timer = DURATION
	state_machine.owner.modulate = Color.RED  # 闪红效果

func exit() -> void:
	state_machine.owner.modulate = Color.WHITE

func physics_process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0:
		transition_requested.emit("Idle")
```

### 6.4 BOSS多阶段状态机

```gdscript
# boss_state_machine.gd - BOSS专用状态机(支持阶段切换)
class_name BossStateMachine extends StateMachine

var current_phase: int = 1
var total_phases: int = 3

func enter_phase(phase: int) -> void:
	current_phase = phase
	var state_name := "Phase%d" % phase
	if states.has(state_name):
		_transition_to(state_name)

func on_hp_threshold_reached(hp_percent: float) -> void:
	var new_phase: int
	if hp_percent > 0.66:
		new_phase = 1
	elif hp_percent > 0.33:
		new_phase = 2
	else:
		new_phase = 3
	if new_phase != current_phase:
		enter_phase(new_phase)
		EventBus.boss_phase_entered.emit(new_phase)
```

---

## 七、对象池(Object Pool)模式

### 7.1 为什么需要对象池

本项目高频创建/销毁弹幕和伤害数字，频繁实例化会导致：

- **内存抖动** (GC压力)
- **帧率 spikes**
- **碎片化**

### 7.2 通用对象池实现

```gdscript
# pool_component.gd - 通用对象池组件
class_name ObjectPool extends Node

@export var pooled_scene: PackedScene
@export var initial_size: int = 20
@export var max_size: int = 100

var _pool: Array[Node] = []
var _active_count: int = 0


func _ready() -> void:
	assert(pooled_scene, "Pooled scene must be assigned!")
	for i in initial_size:
		_create_instance()


func get_instance() -> Node:
	var instance: Node
	if _pool.size() > 0:
		instance = _pool.pop_back()
	elif _active_count < max_size:
		instance = _create_instance()
	else:
		push_warning("Pool exhausted for %s!" % pooled_scene.resource_path)
		return null

	instance.visible = true
	instance.process_mode = Node.PROCESS_MODE_INHERIT
	_active_count += 1
	return instance


func return_instance(instance: Node) -> void:
	if instance in _pool:
		return
	instance.visible = false
	instance.process_mode = Node.PROCESS_MODE_DISABLED
	if instance.has_method("reset"):
		instance.reset.call()
	_pool.append(instance)
	_active_count -= 1


func _create_instance() -> Node:
	var instance: Node = pooled_scene.instantiate()
	add_child(instance)
	instance.visible = false
	instance.process_mode = Node.PROCESS_MODE_DISABLED
	return instance


func get_active_count() -> int:
	return _active_count


func get_pool_size() -> int:
	return _pool.size()
```

### 7.3 弹幕池应用

```gdscript
# 在 CombatSystem 或独立的管理器中使用
@onready var projectile_pool: ObjectPool = $ProjectilePool

func fire_projectile(owner: Node, direction: Vector2, speed: float) -> void:
	var proj: Projectile = projectile_pool.get_instance() as Projectile
	if not proj:
		return
	proj.global_position = owner.global_position
	proj.setup(direction, speed, owner)
	proj.hit_target.connect(func(target):
		projectile_pool.return_instance(proj)
	)
	# 安全回收: 出屏或超时时归还
	proj.lifetime_timeout.connect(func():
		projectile_pool.return_instance(proj)
	)
```

---

## 八、战斗系统实现规范

### 8.1 伤害计算流程

```
攻击发起
	↓
CombatSystem.calculate_damage(attacker, defender)
	↓
┌─────────────────────────────────────────────┐
│ 1. 取出基础伤害 (attacker.base_damage)       │
│ 2. 应用技能倍率 (attacker.skill_mult)        │
│ 3. 判定暴击 (随机 < crit_chance?)            │
│    → 是: × (1 + crit_damage%)               │
│ 4. 计算护甲减伤 DR = armor/(armor+100)       │
│ 5. 最终 = Base × SM × CritMod × (1-DR)      │
│ 6. 施加随机浮动 [0.95, 1.05]                 │
│ 7. 应用阶段修正 (倒吊人低血加成等)           │
└─────────────────────────────────────────────┘
	↓
defender.take_damage(final_amount)
	↓
生成伤害数字(DamageNumberSpawner)
	↓
检查死亡: HP <= 0? → 触发死亡逻辑
```

### 8.2 CombatSystem 核心

```gdscript
# combat_system.gd
class_name CombatSystem extends Node

const RANDOM_VARIANCE_MIN: float = 0.95
const RANDOM_VARIANCE_MAX: float = 1.05

static func calculate_damage(attacker: Node, defender: Node) -> float:
	var bd: float = attacker.base_damage if "base_damage" in attacker else 0.0
	var sm: float = attacker.skill_multiplier if "skill_multiplier" in attacker else 1.0
	var crit_chance: float = attacker.crit_chance if "crit_chance" in attacker else 0.05
	var crit_dmg: float = attacker.crit_damage if "crit_damage" in attacker else 50.0
	var armor: float = defender.armor if "armor" in defender else 0.0

	var damage: float = bd * sm
	if randf() * 100.0 < crit_chance:
		damage *= (1.0 + crit_dmg / 100.0)

	var dr: float = armor / (armor + 100.0)
	damage *= (1.0 - dr)
	damage *= randf_range(RANDOM_VARIANCE_MIN, RANDOM_VARIANCE_MAX)
	return round(damage)


static func fire_projectiles(owner: Node) -> void:
	var count: int = owner.projectile_count if "projectile_count" in owner else 1
	var base_dir: Vector2 = _get_nearest_enemy_direction(owner)

	for i in count:
		var angle_offset: float = _get_spread_angle(i, count, owner)
		var dir: = base_dir.rotated(angle_offset)
		_spawn_single_projectile(owner, dir)


static func _get_nearest_enemy_direction(owner: Node) -> Vector2:
	var enemies := get_tree().get_nodes_in_group("enemy")
	var closest: Node = null
	var closest_dist: float = INF

	for e in enemies:
		var dist: float = owner.global_position.distance_squared_to(e.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest = e

	if closest:
		return (closest.global_position - owner.global_position).normalized()
	return Vector2.RIGHT


static func _get_spread_angle(index: int, total: int, owner: Node) -> float:
	if total <= 1:
		return 0.0
	var spread_range: float = owner.spread_degrees if "spread_degrees" in owner else 360.0
	return deg_to_rad(-spread_range / 2.0 + spread_range * index / (total - 1))


static func _spawn_single_projectile(owner: Node, direction: Vector2) -> void:
	var pool: ObjectPool = owner.projectile_pool if "projectile_pool" in owner else null
	var proj: Node
	if pool:
		proj = pool.get_instance()
	else:
		proj = owner.projectile_scene.instantiate()
		owner.get_parent().add_child(proj)

	proj.global_position = owner.global_position
	proj.setup(direction, owner.projectile_speed, owner)
```

### 8.3 自动攻击循环

```gdscript
# player.gd 中的自动攻击部分
func _on_attack_timeout() -> void:
	if not is_inside_tree():
		return
	CombatSystem.fire_projectiles(self)
	attack_timer.start(get_attack_interval())


func get_attack_interval() -> float:
	return base_attack_interval / attack_speed
```

---

## 九、波次管理系统

### 9.1 WaveManager 架构

```gdscript
# wave_manager.gd
class_name WaveManager extends Node

signal all_waves_complete
signal wave_started(wave_index: int)
signal wave_cleared(wave_index: int)

@export var stage_config: StageConfigResource

var _current_wave: int = 0
var _enemies_remaining: int = 0
var _spawn_queue: Array[Dictionary] = []
var _is_running: bool = false
var _spawn_timer: float = 0.0


func start_waves() -> void:
	_current_wave = 0
	_is_running = true
	_advance_to_next_wave()


func _process(delta: float) -> void:
	if not _is_running:
		return
	_process_spawn_queue(delta)
	_check_wave_completion()


func _advance_to_next_wave() -> void:
	if _current_wave >= stage_config.waves.size():
		_is_running = false
		all_waves_complete.emit()
		return

	_current_wave += 1
	var wave_data: WaveData = stage_config.waves[_current_wave - 1]
	_build_spawn_queue(wave_data)
	wave_started.emit(_current_wave)
	EventBus.wave_started.emit(_current_wave)


func _build_spawn_queue(wave: WaveData) -> void:
	_spawn_queue.clear()
	_enemies_remaining = 0
	var elapsed: float = 0.0

	for group in wave.enemy_groups:
		for i in group.count:
			_spawn_queue.append({
				"scene": group.enemy_scene,
				"delay": elapsed,
				"pattern": group.spawn_pattern,
			})
			elapsed += group.spawn_interval
		_enemies_remaining += group.count


func _process_spawn_queue(delta: float) -> void:
	_spawn_timer += delta
	while _spawn_queue.size() > 0 and _spawn_timer >= _spawn_queue.front()["delay"]:
		var entry: Dictionary = _spawn_queue.pop_front()
		_spawn_enemy(entry["scene"], entry["pattern"])
	if _spawn_queue.size() > 0:
		_spawn_timer = 0.0


func _spawn_enemy(scene: PackedScene, pattern: String) -> void:
	var pos: Vector2 = _get_spawn_position(pattern)
	var enemy: Enemy = SpawnManager.spawn(scene, pos)
	enemy.died.connect(_on_enemy_died)


func _on_enemy_died(_enemy: Enemy) -> void:
	_enemies_remaining -= 1


func _check_wave_completion() -> void:
	if _enemies_remaining <= 0 and _spawn_queue.size() == 0:
		wave_cleared.emit(_current_wave)
		EventBus.wave_cleared.emit(_current_wave)
		await get_tree().create_timer(2.0).timeout
		_advance_to_next_wave()


func _get_spawn_position(pattern: String) -> Vector2:
	var viewport := get_viewport_rect()
	match pattern:
		"random_edge":
			var side: int = randi() % 4
			match side:
				0: return Vector2(randf_range(0, viewport.size.x), viewport.size.y + 20)
				1: return Vector2(randf_range(0, viewport.size.x), -20)
				2: return Vector2(viewport.size.x + 20, randf_range(0, viewport.size.y))
				3: return Vector2(-20, randf_range(0, viewport.size.y))
		"random":
			return Vector2(
				randf_range(viewport.position.x, viewport.end.x),
				randf_range(viewport.position.y, viewport.end.y)
			)
		_:
			return viewport.size / 2 + Vector2(randf_range(-100, 100), randf_range(-100, 100))
```

---

## 十、性能优化最佳实践

### 10.1 性能优化清单

```
╔══════════════════════════════════════════════════════════════╗
║                   性能优化检查清单                         ║
╠════════════════════════════════════════════════════════════╣
║                                                           ║
║ ☑ 1. 对象池                                                ║
║    · 弹幕(Projectile) 必须使用对象池                        ║
║    · 伤害数字(DamageNumber) 必须使用对象池                   ║
║    · 拾取物(Pickup) 使用对象池                               ║
║    · 避免在 _process 中 instantiate/free                  ║
║                                                           ║
║ ☑ 2. 类型安全                                              ║
║    · 所有变量尽量使用类型标注 (:int, :float, :Vector2)      ║
║    · 函数参数和返回值全部类型标注                            ║
║    · 使用 as 操作符替代强制类型转换                          ║
║                                                           ║
║ ☑ 3. 物理vs渲染帧                                          ║
║    · 角色移动/碰撞检测 → _physics_process (60fps)          ║
║    · 纯视觉效果(CRT闪烁/粒子) → _process (不限帧率)        ║
║    · UI更新 → _process 即可                                 ║
║                                                           ║
║ ☑ 4. 避免每帧分配                                           ║
║    ❌ 不要: var arr = []  (每帧新建数组)                    ║
║    ✅ 改为: 类成员变量 _arr.clear() 后重用                   ║
║    ❌ 不要: str(...) 拼接 (每帧新字符串)                    ║
║    ✅ 改为: 使用 StringName 或缓存结果                      ║
║                                                           ║
║ ☑ 5. 节点查询缓存                                          ║
║    ❌ 不要: get_node("Path/To/Deep/Node") 在 _process 中   ║
║    ✅ 改为: @onready var node = $Path/To/Deep/Node         ║
║    ❌ 不要: get_tree().get_nodes_in_group() 每帧调用        ║
║    ✅ 改为: 缓存结果，变化时更新                             ║
║                                                           ║
║ ☑ 6. 视锥剔除                                              ║
║    · 使用 VisibilityNotifier2D 回收屏幕外物体              ║
║    · 弹幕超出屏幕范围自动回收入池                             ║
║    · 远处敌人降低AI更新频率                                  ║
║                                                           ║
║ ☑ 7. 批量操作                                              ║
║    · 多个敌人同时死亡 → 合并为一次特效+掉落                  ║
║    · 多个弹幕同帧命中 → 合并伤害数字显示                     ║
║    · CRT效果作为全屏后处理(Shader)而非逐物体                 ║
║                                                           ║
║ ☑ 8. Shader优化                                            ║
║    · CRT效果使用单个全屏Quad + Fragment Shader              ║
║    · 避免逐像素复杂计算                                      ║
║    · 使用 uniform 变量而非纹理采样做动态效果                  ║
║                                                           ║
╚════════════════════════════════════════════════════════════╝
```

### 10.2 目标性能指标

```
指标              │ 目标值        │ 监控方式
─────────────────┼──────────────┼──────────────────
帧率              │ 60 FPS 稳定   │ Debug→Monitor
同屏敌人上限      │ 200+         │ WaveManager限制
同屏弹幕上限      │ 500+         │ Pool大小限制
内存占用          │ < 512MB      │ OS任务管理器
CPU单帧时间       │ < 16.67ms    │ Debugger性能分析
Draw Call         │ 尽可能少      │ Debugger GPU profile
```

### 10.3 调试与监控

```gdscript
# 在项目设置中启用调试功能:
# Project Settings → Debug → Profilers

# 常用调试快捷键:
# F5          - 运行项目
# F11         - 逐步调试
# Shift+F5    - 停止运行
# F12         - 编辑器中打开场景
# Ctrl+Shift+F7 - 性能监控器(Monitor)
# Ctrl+Shift+F4 - 调试器(Debugger)

# 代码中性能测量:
func _process(delta: float) -> void:
	var start := Time.get_ticks_msec()
	# ... 要测量的代码 ...
	var elapsed := Time.get_ticks_msec() - start
	if elapsed > 5:  # 超过5ms打印警告
		push_warning("Slow frame operation: %dms" % elapsed)
```

---

## 十一、存档系统规范

### 11.1 存档数据结构

```gdscript
# save_system.gd (Autoload)
class_name SaveSystem extends Node

const SAVE_PATH: String = "user://save.dat"

var _save_data: Dictionary = {}

func _ready() -> void:
	load_game()


func save_game() -> void:
	_save_data = {
		"version": 1,
		"timestamp": Time.get_datetime_string_from_system(),
		"unlocked_characters": _get_unlocked_chars(),
		"unlocked_stages": _get_unlocked_stages(),
		"high_scores": _get_high_scores(),
		"total_kills": GameManager.total_kills,
		"total_play_time": GameManager.total_play_time,
		"settings": _get_settings(),
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_var(_save_data)
	file.close()


func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	_save_data = file.get_var() as Dictionary
	file.close()
	return _save_data.size() > 0


func get_value(key: String, default: Variant = null) -> Variant:
	return _save_data.get(key, default)


func set_value(key: String, value: Variant) -> void:
	_save_data[key] = value
	save_game()


func delete_save() -> void:
	if DirAccess.dir_exists_absolute("user://"):
		DirAccess.remove_absolute(SAVE_PATH)
	_save_data.clear()
```

### 11.2 Resource 数据资源使用

```gdscript
# character_data.gd - 角色数据资源定义
class_name CharacterData extends Resource

@export var character_id: String
@export var display_name: String
@export var description: String
@export var max_hp: float = 100.0
@export var move_speed: float = 200.0
@export var base_damage: float = 10.0
@export var attack_speed: float = 1.0
@export var attack_range: float = 150.0
@export var armor: float = 0.0
@export var pickup_radius: float = 50.0
@export var difficulty: int = 1
@export var scene_path: String  # 指向角色场景
```

---

## 十二、输入映射(Input Map)规范

### 12.1 项目输入动作清单

```
在 Project → Project Settings → Input Map 中注册以下动作:

动作名称              │ 设备  │ 默认按键        │ 用途
──────────────────────┼───────┼─────────────────┼──────────────
move_left             │ 键盘  │ A / Left Arrow  │ 向左移动
move_right            │ 键盘  │ D / Right Arrow │ 向右移动
move_up               │ 键盘  │ W / Up Arrow    │ 向上移动
move_down             │ 键盘  │ S / Down Arrow  │ 向下移动
skill                 │ 键盘  │ Space / RClick  │ 主动技能
pause                 │ 键盘  │ Escape          │ 暂停游戏
confirm               │ 键盘  │ Enter / Return  │ 确认选择
cancel                │ 键盘  │ Escape / Back   │ 取消/返回
debug_reload          │ 键盘  │ F5              │ 调试:快速重载
```

### 12.2 输入读取方式

```gdscript
# ✅ 推荐: 使用输入动作名称 (解耦按键绑定)
func _physics_process(delta: float) -> void:
	var input := Vector2(
		Input.get_action_raw_strength("move_right") - Input.get_action_raw_strength("move_left"),
		Input.get_action_raw_strength("move_down") - Input.get_action_raw_strength("move_up")
	)

# 技能释放
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("skill"):
		_use_skill()
	if event.is_action_pressed("pause"):
		GameManager.pause_game()
```

---

## 十三、EditorConfig 配置

确保项目根目录 `.editorconfig` 包含以下内容:

```ini
root = true

[*]
indent_style = tab
indent_size = 4
end_of_line = lf
charset = utf-8
insert_final_newline = true
trim_trailing_whitespace = true

[*.gd]
quote_style = double
spaces_around_operators = true

[*.{tscn,tre,cfg}]
indent_style = space
indent_size = 4
```

---

## 附录：快速参考卡

```
╔══════════════════════════════════════════════════════════════╗
║              **TeleTaRot** Godot 开发速查卡                    ║
╠══════════════════════════════════════════════════════════════╣
║                                                            ║
║  📁 文件命名: snake_case (文件/函数/变量)                  ║
║  📦 类名: PascalCase (class_name / 节点名)                  ║
║  🔒 私有: _前缀 (_timer, _cache)                           ║
║  📡 信号: 过去式 (died, hp_changed)                        ║
║  🔢 常量: CONSTANT_CASE (MAX_HP, BASE_SPEED)               ║
║                                                            ║
║  🔗 连接信号: signal_name.connect(callback)                ║
║  🔄 全局事件: EventBus.event_name.emit(args)               ║
║  📦 自动加载: GameManager.xxx / AudioManager.xxx           ║
║                                                            ║
║  ⚡ 物理逻辑 → _physics_process(delta)                     ║
║  🎨 视觉逻辑 → _process(delta)                             ║
║  🔧 初始化 → _ready() > _enter_tree() > _init()            ║
║                                                            ║
║  ♻️ 高频对象 → ObjectPool (弹幕/伤害数字/拾取物)           ║
║  🏷️ 类型标注 → var x: int = 0 / func f() -> void          ║
║  💾 存档 → user://save.dat (FileAccess.store_var)          ║
║                                                            ║
║  🎯 场景 > 继承                                             ║
║  🎯 组合 > 深层继承                                         ║
║  🎯 信号 > 直接引用                                         ║
║  🎯 EventBus > Autoload存数据                               ║
║                                                            ║
╚══════════════════════════════════════════════════════════════╝
```

---

_文档结束_
_基于 Godot 4.x 官方文档 + 社区最佳实践 + 项目定制_
_最后更新: 2026-04-11_
