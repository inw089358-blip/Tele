class_name MeleeHitEffect
extends Node2D

var _duration: float = 0.12
var _elapsed: float = 0.0
var _family: String = "sweep"
var _forward: Vector2 = Vector2.RIGHT
var _primary: bool = true
var _intensity: float = 1.0
var _impact_scale: float = 1.0
var _outer_tint: Color = Color(0.05, 0.26, 0.42, 0.72)
var _main_tint: Color = Color(0.48, 0.95, 1.0, 1.0)
var _core_tint: Color = Color(0.98, 1.0, 1.0, 1.0)
var _glitch_phase: float = 0.0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_PAUSABLE
    _glitch_phase = randf_range(0.0, TAU)
    set_process(true)
    queue_redraw()

func configure(
    family: String,
    forward: Vector2,
    primary: bool,
    intensity: float,
    impact_scale: float,
    outer_tint: Color = Color(0.05, 0.26, 0.42, 0.72),
    main_tint: Color = Color(0.48, 0.95, 1.0, 1.0),
    core_tint: Color = Color(0.98, 1.0, 1.0, 1.0)
) -> void:
    _family = family
    _forward = forward.normalized() if forward.length_squared() > 0.0001 else Vector2.RIGHT
    _primary = primary
    _intensity = max(0.35, intensity)
    _impact_scale = max(0.5, impact_scale)
    _outer_tint = outer_tint
    _main_tint = main_tint
    _core_tint = core_tint
    match _family:
        "thrust":
            _duration = 0.09 if _primary else 0.07
        "heavy":
            _duration = 0.16 if _primary else 0.11
        _:
            _duration = 0.12 if _primary else 0.085
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
    var forward: Vector2 = _forward
    var side: Vector2 = forward.orthogonal()
    match _family:
        "thrust":
            _draw_thrust_hit(ratio, fade, forward, side)
        "heavy":
            _draw_heavy_hit(ratio, fade, forward, side)
        _:
            _draw_sweep_hit(ratio, fade, forward, side)

func _draw_sweep_hit(ratio: float, fade: float, forward: Vector2, side: Vector2) -> void:
    var slash_len: float = 18.0 * _impact_scale * lerpf(1.08, 0.7, ratio)
    var slash_width: float = 7.0 * _impact_scale * lerpf(1.2, 0.7, ratio)
    var ring_radius: float = 8.0 * _impact_scale * lerpf(0.7, 1.5, ratio)
    var ring_color: Color = Color(_main_tint.r, _main_tint.g, _main_tint.b, 0.42 * fade * _intensity)
    draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 18, ring_color, max(1.5, 3.2 * _impact_scale * (1.0 - ratio * 0.45)), true)
    _draw_diamond(Vector2.ZERO, forward.rotated(0.16), side, slash_len, slash_width, Color(_main_tint.r, _main_tint.g, _main_tint.b, 0.74 * fade * _intensity))
    _draw_diamond(forward * (2.0 * _impact_scale), forward.rotated(-0.22), side, slash_len * 0.76, slash_width * 0.58, Color(_core_tint.r, _core_tint.g, _core_tint.b, 0.46 * fade * _intensity))
    draw_circle(Vector2.ZERO, 4.2 * _impact_scale * lerpf(1.0, 0.56, ratio), Color(_outer_tint.r, _outer_tint.g, _outer_tint.b, 0.26 * fade * _intensity))
    _draw_shard(forward * (6.0 * _impact_scale), forward.rotated(0.24), 8.0 * _impact_scale, 2.0 * _impact_scale, fade)
    _draw_shard(-forward * (2.0 * _impact_scale), forward.rotated(-0.38), 5.2 * _impact_scale, 1.6 * _impact_scale, fade)

func _draw_thrust_hit(ratio: float, fade: float, forward: Vector2, side: Vector2) -> void:
    var length: float = 24.0 * _impact_scale * lerpf(1.18, 0.76, ratio)
    var width: float = 5.2 * _impact_scale * lerpf(1.08, 0.65, ratio)
    var offset: Vector2 = forward * (4.0 * _impact_scale)
    _draw_diamond(offset, forward, side, length, width, Color(_main_tint.r, _main_tint.g, _main_tint.b, 0.82 * fade * _intensity))
    _draw_diamond(offset + forward * (2.0 * _impact_scale), forward, side, length * 0.62, width * 0.42, Color(_core_tint.r, _core_tint.g, _core_tint.b, 0.62 * fade * _intensity))
    draw_line(-forward * (6.0 * _impact_scale), forward * (14.0 * _impact_scale), Color(_main_tint.r, _main_tint.g, _main_tint.b, 0.36 * fade * _intensity), max(1.5, 2.8 * _impact_scale), true)
    draw_circle(offset, 3.2 * _impact_scale * lerpf(1.0, 0.65, ratio), Color(_outer_tint.r, _outer_tint.g, _outer_tint.b, 0.24 * fade * _intensity))
    _draw_shard(offset + forward * (8.0 * _impact_scale), forward.rotated(0.12), 6.4 * _impact_scale, 1.6 * _impact_scale, fade)

func _draw_heavy_hit(ratio: float, fade: float, forward: Vector2, side: Vector2) -> void:
    var bloom_radius: float = 9.0 * _impact_scale * lerpf(0.78, 1.9, ratio)
    var bloom_color: Color = Color(_outer_tint.r, _outer_tint.g, _outer_tint.b, 0.34 * fade * _intensity)
    var ring_color: Color = Color(_main_tint.r, _main_tint.g, _main_tint.b, 0.56 * fade * _intensity)
    draw_circle(Vector2.ZERO, bloom_radius, bloom_color)
    draw_arc(Vector2.ZERO, bloom_radius * 1.08, 0.0, TAU, 22, ring_color, max(2.0, 4.2 * _impact_scale * (1.0 - ratio * 0.35)), true)
    _draw_diamond(forward * (2.5 * _impact_scale), forward, side, 18.0 * _impact_scale, 9.0 * _impact_scale, Color(_main_tint.r, _main_tint.g, _main_tint.b, 0.68 * fade * _intensity))
    _draw_diamond(forward * (2.5 * _impact_scale), forward, side, 10.0 * _impact_scale, 4.6 * _impact_scale, Color(_core_tint.r, _core_tint.g, _core_tint.b, 0.58 * fade * _intensity))
    _draw_shard(forward * (10.0 * _impact_scale), forward.rotated(0.14), 10.0 * _impact_scale, 2.8 * _impact_scale, fade)
    _draw_shard(side * (4.0 * _impact_scale), forward.rotated(0.72), 7.0 * _impact_scale, 2.0 * _impact_scale, fade)
    _draw_shard(-side * (4.0 * _impact_scale), forward.rotated(-0.72), 7.0 * _impact_scale, 2.0 * _impact_scale, fade)

func _draw_diamond(origin: Vector2, forward: Vector2, side: Vector2, length: float, width: float, color: Color) -> void:
    draw_colored_polygon(
        PackedVector2Array([
            origin + forward * length,
            origin + side * width,
            origin - forward * (length * 0.32),
            origin - side * width,
        ]),
        color
    )

func _draw_shard(origin: Vector2, forward: Vector2, length: float, width: float, fade: float) -> void:
    var side: Vector2 = forward.orthogonal()
    var glitch_offset: Vector2 = side * (sin(_elapsed * 58.0 + _glitch_phase) * width * 0.35)
    draw_colored_polygon(
        PackedVector2Array([
            origin + glitch_offset + forward * length,
            origin + glitch_offset + side * width,
            origin + glitch_offset - forward * (length * 0.28),
            origin + glitch_offset - side * width,
        ]),
        Color(_core_tint.r, _core_tint.g, _core_tint.b, 0.46 * fade * _intensity)
    )
