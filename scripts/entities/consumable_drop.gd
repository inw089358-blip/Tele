class_name ConsumableDrop
extends Node2D

@export var heal_amount: int = 3
@export var magnet_radius: float = 140.0
@export var magnet_speed: float = 520.0
@export var collect_radius: float = 14.0

var _collected: bool = false
var _age: float = 0.0
var _spawn_velocity: Vector2 = Vector2.ZERO
var _magnet_velocity: Vector2 = Vector2.ZERO
var _settle_timer: float = 0.2
var _is_attracting: bool = false

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_PAUSABLE
    z_index = 7
    set_process(true)
    queue_redraw()

func _process(delta: float) -> void:
    _age += delta
    queue_redraw()

func set_spawn_impulse(velocity: Vector2) -> void:
    _spawn_velocity = velocity
    _settle_timer = 0.22

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
        _spawn_velocity = _spawn_velocity.move_toward(Vector2.ZERO, 700.0 * delta)
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

func _draw() -> void:
    var pulse: float = 0.5 + 0.5 * sin(_age * 5.8)
    var flicker: float = 0.5 + 0.5 * sin(_age * 17.0)
    var attract_flash: float = 1.0 if _is_attracting else 0.0
    var origin: Vector2 = Vector2(0.0, sin(_age * 4.4) * 0.9)
    var stretch: float = 1.0 + attract_flash * 0.12

    draw_circle(origin, 12.0 + pulse * 1.2, Color(1.0, 0.0, 0.25, 0.16 + pulse * 0.08))
    draw_rect(Rect2(origin + Vector2(-7.0 * stretch, -7.0), Vector2(14.0 * stretch, 14.0)), Color(0.08, 0.13, 0.24, 0.96), true)
    draw_rect(Rect2(origin + Vector2(-5.0 * stretch, -5.0), Vector2(10.0 * stretch, 10.0)), Color(0.86, 0.04, 0.18, 0.92), true)

    var heart_color: Color = Color(1.0, 0.25 + flicker * 0.18, 0.42, 0.96)
    draw_colored_polygon(
        PackedVector2Array([
            origin + Vector2(0.0, 5.5),
            origin + Vector2(-5.0, 0.0),
            origin + Vector2(-4.0, -4.0),
            origin + Vector2(-1.0, -5.5),
            origin + Vector2(0.0, -3.2),
            origin + Vector2(1.0, -5.5),
            origin + Vector2(4.0, -4.0),
            origin + Vector2(5.0, 0.0),
        ]),
        heart_color
    )

    var cross_color: Color = Color(0.0, 1.0, 0.25, 0.82 + pulse * 0.18)
    draw_rect(Rect2(origin + Vector2(-4.0, -1.0), Vector2(8.0, 2.0)), cross_color, true)
    draw_rect(Rect2(origin + Vector2(-1.0, -4.0), Vector2(2.0, 8.0)), cross_color, true)
    draw_rect(Rect2(origin + Vector2(3.0, -7.0), Vector2(3.0, 2.0)), Color(1.0, 0.68, 0.78, 0.75), true)

    if int(_age * 10.0) % 4 == 0 or _is_attracting:
        draw_rect(Rect2(origin + Vector2(-8.0, -3.0), Vector2(5.0, 1.5)), Color(0.0, 1.0, 1.0, 0.22 + attract_flash * 0.16), true)
        draw_rect(Rect2(origin + Vector2(3.0, 4.0), Vector2(6.0, 1.5)), Color(1.0, 0.0, 0.25, 0.24 + attract_flash * 0.14), true)
