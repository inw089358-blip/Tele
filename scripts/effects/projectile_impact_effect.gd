class_name ProjectileImpactEffect
extends Node2D

var _duration: float = 0.12
var _elapsed: float = 0.0
var _radius: float = 10.0
var _forward: Vector2 = Vector2.RIGHT
var _outer_tint: Color = Color(0.08, 0.28, 0.42, 0.78)
var _main_tint: Color = Color(0.48, 0.95, 1.0, 1.0)
var _core_tint: Color = Color(0.98, 1.0, 1.0, 1.0)
var _intensity: float = 1.0
var _ring_thickness: float = 3.0
var _spike_length: float = 1.0
var _style: String = "player_hit"

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_PAUSABLE
    queue_redraw()

func configure(
    style: String,
    radius: float,
    forward: Vector2,
    duration: float,
    outer_tint: Color,
    main_tint: Color,
    core_tint: Color,
    intensity: float = 1.0
) -> void:
    _style = style
    _radius = max(4.0, radius)
    _forward = forward.normalized() if forward.length_squared() > 0.0001 else Vector2.RIGHT
    _duration = max(0.05, duration)
    _outer_tint = outer_tint
    _main_tint = main_tint
    _core_tint = core_tint
    _intensity = max(0.35, intensity)
    match _style:
        "player_fade":
            _ring_thickness = 2.0
            _spike_length = 0.6
        "enemy_hit":
            _ring_thickness = 3.4
            _spike_length = 0.92
        "enemy_fade":
            _ring_thickness = 2.2
            _spike_length = 0.56
        _:
            _ring_thickness = 3.0
            _spike_length = 1.0
    _elapsed = 0.0
    queue_redraw()

func _process(delta: float) -> void:
    _elapsed += delta
    if _elapsed >= _duration:
        queue_free()
        return
    queue_redraw()

func _draw() -> void:
    var ratio: float = clampf(_elapsed / _duration, 0.0, 1.0)
    var fade: float = 1.0 - ratio
    var side: Vector2 = _forward.orthogonal()
    var ring_radius: float = _radius * lerpf(0.65, 1.28, ratio)
    var ring_alpha: float = 0.52 * fade * _intensity
    var ring_color: Color = Color(_main_tint.r, _main_tint.g, _main_tint.b, ring_alpha)
    draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 20, ring_color, _ring_thickness, true)

    var flash_radius: float = _radius * lerpf(0.45, 0.9, ratio)
    var flash_color: Color = Color(_core_tint.r, _core_tint.g, _core_tint.b, 0.34 * fade * _intensity)
    draw_circle(Vector2.ZERO, flash_radius, flash_color)

    var shadow_radius: float = _radius * lerpf(0.75, 1.35, ratio)
    var shadow_color: Color = Color(_outer_tint.r, _outer_tint.g, _outer_tint.b, 0.18 * fade * _intensity)
    draw_circle(Vector2.ZERO, shadow_radius, shadow_color)

    var spike_front_len: float = _radius * (1.1 + _spike_length * (1.0 - ratio))
    var spike_back_len: float = _radius * (0.58 + _spike_length * 0.22 * (1.0 - ratio))
    var spike_width: float = max(2.0, _radius * 0.32 * (1.0 - ratio * 0.35))
    var spike_color: Color = Color(_main_tint.r, _main_tint.g, _main_tint.b, 0.72 * fade * _intensity)
    draw_colored_polygon(
        PackedVector2Array([
            _forward * spike_front_len,
            side * spike_width,
            -_forward * spike_back_len,
            -side * spike_width,
        ]),
        spike_color
    )

    var glitch_offset: Vector2 = side * (_radius * 0.12 * sin(_elapsed * 54.0))
    var shard_color: Color = Color(_core_tint.r, _core_tint.g, _core_tint.b, 0.5 * fade * _intensity)
    draw_colored_polygon(
        PackedVector2Array([
            glitch_offset + _forward * (_radius * 0.58),
            glitch_offset + side * (_radius * 0.18),
            glitch_offset - _forward * (_radius * 0.12),
            glitch_offset - side * (_radius * 0.18),
        ]),
        shard_color
    )
