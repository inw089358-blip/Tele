class_name ExperienceOrb
extends Node2D

@export var xp_value: int = 5
@export var gold_value: int = 0
@export var magnet_radius: float = 120.0
@export var magnet_speed: float = 480.0
@export var collect_radius: float = 12.0

var _collected: bool = false
var _age: float = 0.0
var _spawn_velocity: Vector2 = Vector2.ZERO
var _magnet_velocity: Vector2 = Vector2.ZERO
var _settle_timer: float = 0.16
var _is_attracting: bool = false

func _ready() -> void :
    process_mode = Node.PROCESS_MODE_PAUSABLE
    z_index = 6
    set_process(true)
    queue_redraw()

func _process(delta: float) -> void:
    _age += delta
    queue_redraw()

func setup(xp_amount: int, gold_amount: int = 0) -> void :
    xp_value = max(0, xp_amount)
    gold_value = max(0, gold_amount)

func set_spawn_impulse(velocity: Vector2) -> void:
    _spawn_velocity = velocity
    _settle_timer = 0.18

func tick_collect(player_position: Vector2, pickup_radius: float, delta: float) -> bool:
    if _collected:
        return false

    var attract_radius: float = max(magnet_radius, pickup_radius)
    var to_player: Vector2 = player_position - global_position
    var distance_sq: float = to_player.length_squared()
    var collect_dist_sq: float = collect_radius * collect_radius
    if distance_sq <= collect_dist_sq:
        _collected = true
        return true

    var attract_dist_sq: float = attract_radius * attract_radius
    _is_attracting = distance_sq <= attract_dist_sq and distance_sq > 0.0001

    if _settle_timer > 0.0:
        _settle_timer = max(0.0, _settle_timer - delta)
        global_position += _spawn_velocity * delta
        _spawn_velocity = _spawn_velocity.move_toward(Vector2.ZERO, 620.0 * delta)
        _magnet_velocity = Vector2.ZERO
        return false

    if _is_attracting:
        var distance: float = sqrt(distance_sq)
        var direction: Vector2 = to_player / distance
        var distance_ratio: float = 1.0 - clampf(distance / attract_radius, 0.0, 1.0)
        var target_speed: float = magnet_speed * lerpf(0.35, 1.35, distance_ratio)
        _magnet_velocity = _magnet_velocity.move_toward(direction * target_speed, magnet_speed * 4.0 * delta)
        var travel: Vector2 = _magnet_velocity * delta
        if travel.length_squared() > distance_sq:
            global_position = player_position
        else:
            global_position += travel
    else:
        _magnet_velocity = _magnet_velocity.move_toward(Vector2.ZERO, magnet_speed * 3.0 * delta)

    return false

func is_collected() -> bool:
    return _collected

func _draw() -> void :
    var bob: float = sin(_age * 5.4) * 1.2
    var pulse: float = 0.5 + 0.5 * sin(_age * 7.0)
    var attract_flash: float = 1.0 if _is_attracting else 0.0
    var origin: Vector2 = Vector2(0.0, bob)
    var core_color: Color = Color(0.0, 0.88, 1.0, 0.9 + pulse * 0.1)
    var edge_color: Color = Color(0.08, 0.16, 0.28, 0.96)
    var glow_color: Color = Color(0.0, 1.0, 1.0, 0.16 + pulse * 0.12 + attract_flash * 0.08)

    draw_circle(origin, 11.0 + pulse * 1.5 + attract_flash * 2.0, glow_color)
    draw_colored_polygon(
        PackedVector2Array([
            origin + Vector2(0.0, -8.0),
            origin + Vector2(6.0, -3.0),
            origin + Vector2(4.0, 5.0),
            origin + Vector2(-1.0, 9.0),
            origin + Vector2(-7.0, 2.0),
            origin + Vector2(-5.0, -5.0),
        ]),
        edge_color
    )
    draw_colored_polygon(
        PackedVector2Array([
            origin + Vector2(0.0, -5.5),
            origin + Vector2(4.0, -2.0),
            origin + Vector2(2.5, 3.5),
            origin + Vector2(-0.5, 6.0),
            origin + Vector2(-4.5, 1.2),
            origin + Vector2(-3.0, -3.5),
        ]),
        core_color
    )
    draw_rect(Rect2(origin + Vector2(-1.0, -5.0), Vector2(2.0, 10.0)), Color(0.82, 1.0, 1.0, 0.45), true)
    draw_rect(Rect2(origin + Vector2(-4.0, -1.0), Vector2(8.0, 2.0)), Color(0.82, 1.0, 1.0, 0.38), true)

    if gold_value > 0:
        var gold_pulse: float = 0.55 + pulse * 0.45
        var gold: Color = Color(1.0, 0.66, 0.0, 0.8 + gold_pulse * 0.18)
        draw_arc(origin, 9.5, -0.35, PI * 1.52, 16, gold, 1.6)
        draw_rect(Rect2(origin + Vector2(4.0, -8.0), Vector2(3.0, 3.0)), Color(1.0, 0.86, 0.28, 0.9), true)
        draw_rect(Rect2(origin + Vector2(-7.0, 5.0), Vector2(3.0, 2.0)), Color(1.0, 0.58, 0.0, 0.8), true)

    var glitch_phase: int = int(_age * 12.0) % 5
    if glitch_phase == 0 or _is_attracting:
        var glitch_alpha: float = 0.28 + attract_flash * 0.2
        draw_rect(Rect2(origin + Vector2(-8.0, -2.0), Vector2(7.0, 1.5)), Color(0.0, 1.0, 0.25, glitch_alpha), true)
        draw_rect(Rect2(origin + Vector2(1.0, 4.0), Vector2(8.0, 1.5)), Color(1.0, 0.0, 0.25, glitch_alpha * 0.85), true)
