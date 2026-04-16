class_name Player
extends CharacterBody2D

@export var move_speed: float = 220.0
@export var max_hp: int = 100
@export var body_radius: float = 9.0
@export var pickup_radius: float = 92.0
@export var stamina_max: float = 100.0
@export var stamina_recover_per_sec: float = 26.0
@export var dash_cost: float = 28.0
@export var dash_duration: float = 0.18
@export var dash_speed_multiplier: float = 3.2
@export var base_target_range: float = 320.0

var current_hp: int = max_hp
var current_stamina: float = stamina_max
var bonus_target_range: float = 0.0
var bonus_attack_damage: int = 0

var _dash_timer: float = 0.0
var _last_move_direction: Vector2 = Vector2.RIGHT

func _ready() -> void :
    process_mode = Node.PROCESS_MODE_PAUSABLE
    _ensure_collision_shape()
    current_hp = max_hp
    current_stamina = stamina_max
    queue_redraw()

func _physics_process(delta: float) -> void :
    _try_start_dash()
    _dash_timer = max(0.0, _dash_timer - delta)
    if _dash_timer <= 0.0:
        current_stamina = min(stamina_max, current_stamina + stamina_recover_per_sec * delta)

    var movement: Vector2 = Vector2(
        Input.get_action_strength("move_right") - Input.get_action_strength("move_left"), 
        Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
    )
    if movement.length_squared() > 0.0:
        _last_move_direction = movement.normalized()

    var move_vector: Vector2 = movement
    if _dash_timer > 0.0 and move_vector.length_squared() == 0.0:
        move_vector = _last_move_direction

    var speed_scale: float = dash_speed_multiplier if _dash_timer > 0.0 else 1.0
    velocity = move_vector.normalized() * move_speed * speed_scale
    move_and_slide()

func take_damage(amount: int) -> void :
    current_hp = max(0, current_hp - amount)
    if current_hp <= 0:
        EventBus.player_died.emit()
        queue_free()

func _try_start_dash() -> void :
    if _dash_timer > 0.0:
        return
    if not Input.is_key_pressed(KEY_SPACE):
        return
    if not Input.is_action_just_pressed("skill"):
        return
    if current_stamina < dash_cost:
        return
    current_stamina = max(0.0, current_stamina - dash_cost)
    _dash_timer = dash_duration

func _draw() -> void :
    draw_circle(Vector2.ZERO, body_radius + 2.0, Color(0.15, 0.12, 0.08, 0.85))
    draw_circle(Vector2.ZERO, body_radius, Color(0.93, 0.86, 0.69, 1.0))

func get_current_target_range() -> float:
    return max(80.0, base_target_range + bonus_target_range)

func add_target_range(amount: float) -> void :
    bonus_target_range += amount

func add_attack_damage(amount: int) -> void :
    bonus_attack_damage += amount

func get_attack_damage_bonus() -> int:
    return bonus_attack_damage

func add_move_speed(amount: float) -> void :
    move_speed += amount

func _ensure_collision_shape() -> void:
    for child: Node in get_children():
        if child is CollisionShape2D:
            var existing_collision: CollisionShape2D = child
            if existing_collision.shape == null:
                var fallback_shape: CircleShape2D = CircleShape2D.new()
                fallback_shape.radius = max(1.0, body_radius)
                existing_collision.shape = fallback_shape
            return

    var collision_shape: CollisionShape2D = CollisionShape2D.new()
    collision_shape.name = "AutoCollisionShape2D"
    var circle_shape: CircleShape2D = CircleShape2D.new()
    circle_shape.radius = max(1.0, body_radius)
    collision_shape.shape = circle_shape
    add_child(collision_shape)
