class_name EnemyWarningZone
extends Node2D

enum ZoneShape {
    CIRCLE,
    LINE,
}

var _shape: ZoneShape = ZoneShape.CIRCLE
var _duration: float = 1.0
var _elapsed: float = 0.0
var _radius: float = 48.0
var _length: float = 600.0
var _width: float = 48.0
var _tint: Color = Color(1.0, 0.22, 0.28, 1.0)

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_PAUSABLE
    z_index = 4
    queue_redraw()

func setup_circle(radius: float, duration: float, tint: Color = Color(1.0, 0.22, 0.28, 1.0)) -> void:
    _shape = ZoneShape.CIRCLE
    _radius = max(4.0, radius)
    _duration = max(0.05, duration)
    _elapsed = 0.0
    _tint = tint
    queue_redraw()

func setup_line(length: float, width: float, duration: float, angle: float, tint: Color = Color(1.0, 0.22, 0.28, 1.0)) -> void:
    _shape = ZoneShape.LINE
    _length = max(16.0, length)
    _width = max(4.0, width)
    _duration = max(0.05, duration)
    _elapsed = 0.0
    _tint = tint
    rotation = angle
    queue_redraw()

func _process(delta: float) -> void:
    _elapsed += delta
    if _elapsed >= _duration:
        queue_free()
        return
    queue_redraw()

func _draw() -> void:
    var ratio: float = clampf(_elapsed / _duration, 0.0, 1.0)
    var pulse: float = 0.5 + 0.5 * sin(_elapsed * 26.0)
    var fill_alpha: float = lerpf(0.10, 0.24, ratio) + pulse * 0.035
    var line_alpha: float = lerpf(0.38, 0.9, ratio)
    var fill_color: Color = Color(_tint.r, _tint.g, _tint.b, fill_alpha)
    var edge_color: Color = Color(_tint.r, min(1.0, _tint.g + 0.2), min(1.0, _tint.b + 0.18), line_alpha)
    match _shape:
        ZoneShape.LINE:
            _draw_line_zone(ratio, fill_color, edge_color)
        _:
            _draw_circle_zone(ratio, fill_color, edge_color)

func _draw_circle_zone(ratio: float, fill_color: Color, edge_color: Color) -> void:
    draw_circle(Vector2.ZERO, _radius, fill_color)
    draw_arc(Vector2.ZERO, _radius, 0.0, TAU, 64, edge_color, 3.0, true)
    draw_arc(Vector2.ZERO, _radius * ratio, 0.0, TAU, 48, Color(edge_color.r, edge_color.g, edge_color.b, edge_color.a * 0.75), 2.0, true)

func _draw_line_zone(ratio: float, fill_color: Color, edge_color: Color) -> void:
    var half_length: float = _length * 0.5
    var half_width: float = _width * 0.5
    var rect: Rect2 = Rect2(Vector2(-half_length, -half_width), Vector2(_length, _width))
    draw_rect(rect, fill_color, true)
    draw_rect(rect, edge_color, false, 3.0)
    var scan_x: float = lerpf(-half_length, half_length, ratio)
    draw_line(Vector2(scan_x, -half_width), Vector2(scan_x, half_width), Color(1.0, 0.95, 0.86, edge_color.a), 3.0)
