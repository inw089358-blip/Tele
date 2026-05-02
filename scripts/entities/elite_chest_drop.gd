class_name EliteChestDrop
extends Node2D

var _age: float = 0.0
var _velocity: Vector2 = Vector2.ZERO
var _fly_target: Vector2 = Vector2.ZERO
var _fly_delay: float = 0.45
var _fly_time: float = 0.0
var _fly_duration: float = 0.7
var _start_position: Vector2 = Vector2.ZERO
var _flying: bool = false

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_PAUSABLE
    z_index = 12
    queue_redraw()

func setup(spawn_velocity: Vector2, fly_target: Vector2) -> void:
    _velocity = spawn_velocity
    _fly_target = fly_target
    _start_position = global_position

func _process(delta: float) -> void:
    _age += delta
    if not _flying:
        _fly_delay -= delta
        global_position += _velocity * delta
        _velocity = _velocity.move_toward(Vector2.ZERO, 720.0 * delta)
        if _fly_delay <= 0.0:
            _flying = true
            _fly_time = 0.0
            _start_position = global_position
    else:
        _fly_time += delta
        var t: float = clampf(_fly_time / max(0.01, _fly_duration), 0.0, 1.0)
        var eased: float = 1.0 - pow(1.0 - t, 3.0)
        global_position = _start_position.lerp(_fly_target, eased)
        scale = Vector2.ONE.lerp(Vector2(0.25, 0.25), eased)
        modulate.a = 1.0 - max(0.0, t - 0.72) / 0.28
        if t >= 1.0:
            queue_free()
    queue_redraw()

func _draw() -> void:
    var pulse: float = 0.5 + 0.5 * sin(_age * 7.0)
    var glitch_on: bool = int(_age * 12.0) % 5 == 0
    var origin: Vector2 = Vector2(0.0, sin(_age * 5.0) * 1.2)
    draw_circle(origin, 18.0 + pulse * 2.0, Color(0.0, 0.95, 1.0, 0.14 + pulse * 0.09))
    draw_rect(Rect2(origin + Vector2(-12.0, -6.0), Vector2(24.0, 17.0)), Color(0.04, 0.09, 0.18, 0.96), true)
    draw_rect(Rect2(origin + Vector2(-10.0, -4.0), Vector2(20.0, 13.0)), Color(0.09, 0.16, 0.28, 0.96), true)
    draw_rect(Rect2(origin + Vector2(-13.0, -10.0), Vector2(26.0, 7.0)), Color(0.035, 0.07, 0.15, 0.98), true)
    draw_rect(Rect2(origin + Vector2(-10.0, -9.0), Vector2(20.0, 4.0)), Color(0.11, 0.2, 0.34, 0.95), true)
    draw_rect(Rect2(origin + Vector2(-11.0, -2.0), Vector2(22.0, 2.0)), Color(0.0, 1.0, 1.0, 0.7 + pulse * 0.25), true)
    draw_rect(Rect2(origin + Vector2(-1.0, -8.0), Vector2(2.0, 17.0)), Color(0.0, 0.72, 1.0, 0.42), true)
    draw_rect(Rect2(origin + Vector2(-3.0, -2.0), Vector2(6.0, 7.0)), Color(1.0, 0.63, 0.0, 0.95), true)
    draw_rect(Rect2(origin + Vector2(-1.0, 0.0), Vector2(2.0, 3.0)), Color(1.0, 0.92, 0.32, 0.9), true)
    draw_rect(Rect2(origin + Vector2(-13.0, 8.0), Vector2(26.0, 2.0)), Color(0.0, 0.0, 0.0, 0.28), true)
    if glitch_on:
        draw_rect(Rect2(origin + Vector2(-15.0, -6.0), Vector2(8.0, 2.0)), Color(1.0, 0.0, 0.25, 0.42), true)
        draw_rect(Rect2(origin + Vector2(5.0, 4.0), Vector2(11.0, 2.0)), Color(0.72, 0.32, 1.0, 0.42), true)
