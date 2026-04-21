class_name MeleeArcEffect
extends Node2D

var _duration: float = 0.12
var _elapsed: float = 0.0
var _radius: float = 72.0
var _arc_radians: float = 1.35
var _line_width: float = 8.0
var _center_angle: float = 0.0
var _tint: Color = Color(0.9, 0.98, 1.0, 0.95)

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_PAUSABLE
    set_process(true)
    queue_redraw()

func configure(center_angle: float, radius: float, arc_radians: float, line_width: float, tint: Color, duration: float) -> void:
    _center_angle = center_angle
    _radius = max(10.0, radius)
    _arc_radians = clampf(arc_radians, 0.2, PI * 1.4)
    _line_width = max(2.0, line_width)
    _tint = tint
    _duration = max(0.04, duration)
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
    var color: Color = Color(_tint.r, _tint.g, _tint.b, alpha)
    var start_angle: float = _center_angle - _arc_radians * 0.5
    var end_angle: float = _center_angle + _arc_radians * 0.5
    draw_arc(Vector2.ZERO, _radius, start_angle, end_angle, 18, color, _line_width, true)
