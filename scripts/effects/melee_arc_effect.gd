class_name MeleeArcEffect
extends Node2D

var _duration: float = 0.12
var _elapsed: float = 0.0
var _radius: float = 72.0
var _arc_radians: float = 1.35
var _line_width: float = 8.0
var _center_angle: float = 0.0
var _tint: Color = Color(0.9, 0.98, 1.0, 0.95)
var _style: String = "sweep"
var _intensity: float = 1.0
var _glitch_phase: float = 0.0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_PAUSABLE
    _glitch_phase = randf_range(0.0, TAU)
    set_process(true)
    queue_redraw()

func configure(
    center_angle: float,
    radius: float,
    arc_radians: float,
    line_width: float,
    tint: Color,
    duration: float,
    style: String = "sweep",
    intensity: float = 1.0
) -> void:
    _center_angle = center_angle
    _radius = max(10.0, radius)
    _arc_radians = clampf(arc_radians, 0.2, PI * 1.4)
    _line_width = max(2.0, line_width)
    _tint = tint
    _duration = max(0.04, duration)
    _style = style
    _intensity = max(0.35, intensity)
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
    var alpha: float = (1.0 - ratio) * _tint.a
    var color: Color = Color(_tint.r, _tint.g, _tint.b, alpha * _intensity)
    var start_angle: float = _center_angle - _arc_radians * 0.5
    var end_angle: float = _center_angle + _arc_radians * 0.5
    match _style:
        "thrust":
            _draw_thrust_effect(ratio, color)
        "heavy":
            _draw_heavy_effect(ratio, start_angle, end_angle, color)
        _:
            _draw_sweep_effect(ratio, start_angle, end_angle, color)

func _draw_sweep_effect(ratio: float, start_angle: float, end_angle: float, color: Color) -> void:
    var width: float = _line_width * lerpf(1.22, 0.78, ratio)
    var ghost_shift: float = (_arc_radians * 0.08 + 0.02) * (1.0 - ratio)
    var shadow_color: Color = Color(color.r * 0.26, color.g * 0.7, color.b * 0.92, color.a * 0.38)
    var ghost_color: Color = Color(color.r * 0.88, min(1.0, color.g * 1.05), min(1.0, color.b * 1.08), color.a * 0.32)
    draw_arc(Vector2.ZERO, _radius * 1.04, start_angle, end_angle, 22, shadow_color, width * 1.28, true)
    draw_arc(Vector2.ZERO, _radius * 0.92, start_angle - ghost_shift, end_angle - ghost_shift, 18, ghost_color, max(1.5, width * 0.74), true)
    draw_arc(Vector2.ZERO, _radius, start_angle, end_angle, 24, color, width, true)
    draw_arc(Vector2.ZERO, _radius * 0.82, start_angle, end_angle, 18, Color(color.r, color.g, color.b, color.a * 0.42), max(1.5, width * 0.46), true)
    var tip_angle: float = lerp_angle(start_angle, end_angle, clampf(0.78 + 0.08 * sin(_glitch_phase + _elapsed * 18.0), 0.0, 1.0))
    var tip_pos: Vector2 = Vector2.RIGHT.rotated(tip_angle) * _radius
    draw_circle(tip_pos, max(2.0, _line_width * 0.34), Color(0.98, 1.0, 1.0, color.a * 0.5))
    _draw_glitch_sliver(tip_pos, Vector2.RIGHT.rotated(tip_angle), max(6.0, _line_width * 1.4), color, ratio)

func _draw_thrust_effect(ratio: float, color: Color) -> void:
    var forward: Vector2 = Vector2.RIGHT.rotated(_center_angle)
    var side: Vector2 = forward.orthogonal()
    var reach: float = _radius * lerpf(0.56, 1.24, 1.0 - ratio * 0.6)
    var width: float = max(2.0, _line_width * lerpf(1.0, 0.48, ratio))
    var tail: Vector2 = -forward * (_radius * 0.18)
    var tip: Vector2 = forward * reach
    var shadow_offset: Vector2 = side * (_line_width * 0.22 * sin(_elapsed * 46.0 + _glitch_phase))
    draw_colored_polygon(
        PackedVector2Array([
            tip + shadow_offset,
            tail + side * width * 1.4 + shadow_offset,
            tail - side * width * 1.4 + shadow_offset,
        ]),
        Color(color.r * 0.24, color.g * 0.7, color.b * 0.95, color.a * 0.34)
    )
    draw_colored_polygon(
        PackedVector2Array([
            tip,
            tail + side * width,
            tail - side * width,
        ]),
        color
    )
    draw_colored_polygon(
        PackedVector2Array([
            tip * 0.94,
            tail + side * (width * 0.42),
            tail - side * (width * 0.42),
        ]),
        Color(0.98, 1.0, 1.0, color.a * 0.55)
    )
    draw_line(Vector2.ZERO, forward * (_radius * 0.9), Color(color.r, color.g, color.b, color.a * 0.46), max(1.5, width * 0.58), true)
    _draw_glitch_sliver(forward * (_radius * 0.54), forward, max(5.0, _line_width * 1.15), color, ratio)

func _draw_heavy_effect(ratio: float, start_angle: float, end_angle: float, color: Color) -> void:
    var width: float = _line_width * lerpf(1.88, 0.96, ratio)
    var shadow_color: Color = Color(color.r * 0.24, color.g * 0.66, color.b * 0.9, color.a * 0.44)
    draw_arc(Vector2.ZERO, _radius * 1.03, start_angle, end_angle, 24, shadow_color, width * 1.32, true)
    draw_arc(Vector2.ZERO, _radius * 0.9, start_angle - _arc_radians * 0.08, end_angle - _arc_radians * 0.08, 20, Color(color.r, color.g, color.b, color.a * 0.32), width * 0.7, true)
    draw_arc(Vector2.ZERO, _radius, start_angle, end_angle, 24, color, width, true)
    var impact_dir: Vector2 = Vector2.RIGHT.rotated(lerp_angle(start_angle, end_angle, 0.82))
    var impact_center: Vector2 = impact_dir * _radius
    draw_circle(impact_center, _line_width * lerpf(1.46, 0.74, ratio), Color(color.r, color.g, color.b, color.a * 0.46))
    draw_circle(impact_center, _line_width * lerpf(0.82, 0.4, ratio), Color(0.98, 1.0, 1.0, color.a * 0.52))
    draw_arc(Vector2.ZERO, _radius * 0.76, start_angle, end_angle, 18, Color(color.r, color.g, color.b, color.a * 0.28), max(1.5, width * 0.35), true)
    _draw_glitch_sliver(impact_center, impact_dir, max(8.0, _line_width * 1.85), color, ratio)
    _draw_glitch_sliver(impact_center + impact_dir.orthogonal() * (_line_width * 0.26), impact_dir.rotated(0.24), max(6.0, _line_width * 1.35), color, ratio)

func _draw_glitch_sliver(origin: Vector2, forward: Vector2, length: float, color: Color, ratio: float) -> void:
    var side: Vector2 = forward.orthogonal()
    var jitter: Vector2 = side * (_line_width * 0.16 * sin(_elapsed * 52.0 + _glitch_phase))
    var half_width: float = max(1.5, _line_width * 0.2 * (1.0 - ratio * 0.35))
    draw_colored_polygon(
        PackedVector2Array([
            origin + jitter + forward * length,
            origin + jitter + side * half_width,
            origin + jitter - forward * (length * 0.34),
            origin + jitter - side * half_width,
        ]),
        Color(0.98, 1.0, 1.0, color.a * 0.42)
    )
