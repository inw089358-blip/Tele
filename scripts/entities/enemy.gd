class_name Enemy
extends CharacterBody2D

enum EnemyType {
    MELEE,
    RANGED,
    ELITE_WARDEN,
    BARRAGE,
}

signal died(enemy: Enemy)
signal enemy_projectile_fired(
    origin: Vector2,
    direction: Vector2,
    speed: float,
    damage: int,
    hit_radius: float,
    life_time: float,
    tint: Color
)

@export var move_speed: float = 120.0
@export var max_hp: int = 30
@export var body_radius: float = 8.0
@export var xp_drop_amount: int = 5
@export var enemy_type: EnemyType = EnemyType.MELEE
@export var is_elite: bool = false

var current_hp: int = max_hp
var damage_reduction_ratio: float = 0.0
var _target: Node2D
var _is_dead: bool = false

func _ready() -> void :
    _apply_profile_from_balance()
    process_mode = Node.PROCESS_MODE_PAUSABLE
    current_hp = max_hp
    add_to_group("enemies")
    queue_redraw()

func _apply_profile_from_balance() -> void:
    var profile: Dictionary = BalanceService.get_enemy_profile("melee")
    move_speed = float(profile.get("move_speed", move_speed))
    max_hp = int(profile.get("max_hp", max_hp))
    xp_drop_amount = int(profile.get("xp_drop", xp_drop_amount))

func _physics_process(delta: float) -> void :
    if GameManager.current_state != GameManager.GameState.PLAYING:
        return
    if _target == null:
        return
    tick_ai(delta)
    move_and_slide()

func tick_ai(_delta: float) -> void :
    var direction: Vector2 = (_target.global_position - global_position).normalized()
    velocity = direction * move_speed

func set_target(target: Node2D) -> void :
    _target = target

func get_display_name() -> String:
    return "Enemy"

func try_fire_projectile(
    direction: Vector2,
    speed: float,
    damage: int,
    hit_radius: float,
    life_time: float,
    tint: Color = Color(1.0, 0.36, 0.3, 1.0)
) -> void :
    if _is_dead:
        return
    if direction.length_squared() <= 0.0001:
        return
    enemy_projectile_fired.emit(global_position, direction.normalized(), speed, damage, hit_radius, life_time, tint)

func take_damage(amount: int) -> int:
    if _is_dead:
        return 0
    if amount <= 0:
        return 0
    var reduced_ratio: float = clampf(damage_reduction_ratio, 0.0, 0.95)
    var final_damage: int = int(round(float(amount) * (1.0 - reduced_ratio)))
    final_damage = max(1, final_damage)

    current_hp = max(0, current_hp - final_damage)
    queue_redraw()
    if current_hp <= 0:
        _is_dead = true
        died.emit(self)
        queue_free()
    return final_damage

func _draw() -> void :
    draw_circle(Vector2.ZERO, body_radius + 2.0, Color(0.18, 0.04, 0.05, 0.9))
    draw_circle(Vector2.ZERO, body_radius, Color(0.92, 0.28, 0.26, 1.0))
    if not _should_draw_health_bar():
        return
    var hp_ratio: float = float(current_hp) / float(max(max_hp, 1))
    var bar_width: float = 22.0
    var bar_height: float = 4.0
    var bar_pos: Vector2 = Vector2( - bar_width * 0.5, body_radius + 7.0)
    draw_rect(Rect2(bar_pos, Vector2(bar_width, bar_height)), Color(0.18, 0.1, 0.1, 0.9), true)
    draw_rect(Rect2(bar_pos, Vector2(bar_width * hp_ratio, bar_height)), Color(0.95, 0.22, 0.24, 1.0), true)

func _should_draw_health_bar() -> bool:
    return is_elite or enemy_type == EnemyType.ELITE_WARDEN
