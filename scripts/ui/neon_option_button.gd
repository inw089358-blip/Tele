class_name NeonOptionButton
extends Button

@export var color_normal: Color = Color(0.33, 0.95, 0.65, 0.92)
@export var color_hover: Color = Color(0.45, 1.0, 0.72, 1.0)
@export var color_pressed: Color = Color(0.62, 1.0, 0.8, 1.0)
@export var color_disabled: Color = Color(0.35, 0.45, 0.4, 0.5)
@export var scanline_speed: float = 110.0
@export var focus_sweep_duration: float = 0.22
@export var focus_sweep_width: float = 48.0

var _hovered: bool = false
var _held: bool = false
var _scanline_y: float = 0.0
var _pulse: float = 0.0
var _focus_sweep_t: float = -1.0

func _ready() -> void:
    flat = true
    mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    _scanline_y = size.y * 0.5

    var empty: StyleBoxEmpty = StyleBoxEmpty.new()
    add_theme_stylebox_override("normal", empty)
    add_theme_stylebox_override("hover", empty)
    add_theme_stylebox_override("pressed", empty)
    add_theme_stylebox_override("focus", empty)
    add_theme_stylebox_override("disabled", empty)

    add_theme_constant_override("h_separation", 0)
    add_theme_constant_override("outline_size", 0)
    add_theme_font_size_override("font_size", 24)
    _apply_font_color()

    mouse_entered.connect(_on_mouse_entered)
    mouse_exited.connect(_on_mouse_exited)
    button_down.connect(_on_button_down)
    button_up.connect(_on_button_up)
    focus_entered.connect(_on_focus_entered)
    focus_exited.connect(_on_focus_exited)
    resized.connect(_on_resized)

func _process(delta: float) -> void:
    var active_fx: bool = _hovered or has_focus() or _held
    if active_fx:
        _scanline_y += scanline_speed * delta
        if _scanline_y > size.y - 6.0:
            _scanline_y = 6.0
    if _focus_sweep_t >= 0.0:
        var duration: float = max(0.01, focus_sweep_duration)
        _focus_sweep_t += delta / duration
        if _focus_sweep_t >= 1.0:
            _focus_sweep_t = -1.0
    if _pulse > 0.0:
        _pulse = max(0.0, _pulse - delta * 3.2)
    if active_fx or _pulse > 0.0 or _focus_sweep_t >= 0.0:
        queue_redraw()

func _draw() -> void:
    var c: Color = _current_color()
    var w: float = size.x
    var h: float = size.y
    if w <= 8.0 or h <= 8.0:
        return

    # Core horizontal frame lines.
    draw_line(Vector2(18.0, 1.0), Vector2(w - 18.0, 1.0), c, 1.8)
    draw_line(Vector2(18.0, h - 1.0), Vector2(w - 18.0, h - 1.0), c, 1.8)

    # Vertical side line segments.
    draw_line(Vector2(18.0, 8.0), Vector2(18.0, h - 8.0), c, 1.8)
    draw_line(Vector2(w - 18.0, 8.0), Vector2(w - 18.0, h - 8.0), c, 1.8)

    # Bracket accents on both sides.
    _draw_bracket(8.0, h * 0.5, true, c)
    _draw_bracket(w - 8.0, h * 0.5, false, c)

    # Hover glow line.
    if _hovered and not _held and not disabled:
        var glow: Color = c
        glow.a = 0.35
        draw_line(Vector2(26.0, 0.0), Vector2(w - 26.0, 0.0), glow, 3.0)
        draw_line(Vector2(26.0, h), Vector2(w - 26.0, h), glow, 3.0)

    # Traveling scanline accent (hover/focus only).
    if (_hovered or has_focus()) and not _held and not disabled:
        var scan: Color = c
        scan.a = 0.26
        draw_line(Vector2(30.0, _scanline_y), Vector2(w - 30.0, _scanline_y), scan, 2.0)

    # Click pulse ring.
    if _pulse > 0.0 and not disabled:
        var p: float = 1.0 - _pulse
        var margin_x: float = 24.0 - p * 14.0
        var margin_y: float = 8.0 - p * 5.0
        var pulse_rect: Rect2 = Rect2(
            Vector2(margin_x, margin_y),
            Vector2(w - margin_x * 2.0, h - margin_y * 2.0)
        )
        var pulse_c: Color = color_pressed
        pulse_c.a = 0.45 * _pulse
        draw_rect(pulse_rect, pulse_c, false, 1.8)

    # Short focus/hover sweep from left to right.
    if _focus_sweep_t >= 0.0 and not disabled:
        var x0: float = 26.0
        var x1: float = w - 26.0
        var cx: float = lerpf(x0, x1, clampf(_focus_sweep_t, 0.0, 1.0))
        var band_w: float = min(focus_sweep_width, max(8.0, w - 52.0))
        var sweep_rect: Rect2 = Rect2(
            Vector2(cx - band_w * 0.5, 6.0),
            Vector2(band_w, max(2.0, h - 12.0))
        )
        var sweep_c: Color = color_hover
        sweep_c.a = 0.15 * (1.0 - absf(_focus_sweep_t - 0.5) * 2.0)
        draw_rect(sweep_rect, sweep_c, true)

func _draw_bracket(x: float, center_y: float, is_left: bool, c: Color) -> void:
    var half: float = 16.0
    var inner_x: float = x + (8.0 if is_left else -8.0)
    var arm: float = 12.0
    draw_line(Vector2(x, center_y - half), Vector2(x, center_y + half), c, 2.0)
    if is_left:
        draw_line(Vector2(x, center_y - half), Vector2(inner_x, center_y - half), c, 2.0)
        draw_line(Vector2(x, center_y + half), Vector2(inner_x, center_y + half), c, 2.0)
        draw_line(Vector2(inner_x, center_y), Vector2(inner_x + arm, center_y), c, 1.4)
    else:
        draw_line(Vector2(x, center_y - half), Vector2(inner_x, center_y - half), c, 2.0)
        draw_line(Vector2(x, center_y + half), Vector2(inner_x, center_y + half), c, 2.0)
        draw_line(Vector2(inner_x, center_y), Vector2(inner_x - arm, center_y), c, 1.4)

func _current_color() -> Color:
    if disabled:
        return color_disabled
    if _held:
        return color_pressed
    if _hovered or has_focus():
        return color_hover
    return color_normal

func refresh_interaction_state() -> void:
    if disabled or not is_visible_in_tree():
        _hovered = false
        _held = false
    else:
        var local_mouse_pos: Vector2 = get_local_mouse_position()
        _hovered = Rect2(Vector2.ZERO, size).has_point(local_mouse_pos)
        _held = false
        if _hovered:
            _scanline_y = 8.0
            _trigger_focus_sweep()
    _apply_font_color()
    queue_redraw()

func _apply_font_color() -> void:
    var c: Color = _current_color()
    add_theme_color_override("font_color", c)
    var pressed_color: Color = color_pressed
    add_theme_color_override("font_pressed_color", pressed_color)
    add_theme_color_override("font_hover_color", color_hover)
    add_theme_color_override("font_focus_color", color_hover)
    add_theme_color_override("font_disabled_color", color_disabled)

func _on_mouse_entered() -> void:
    _hovered = true
    _scanline_y = 8.0
    _trigger_focus_sweep()
    _apply_font_color()
    queue_redraw()

func _on_mouse_exited() -> void:
    _hovered = false
    _held = false
    _apply_font_color()
    queue_redraw()

func _on_button_down() -> void:
    _held = true
    _pulse = 1.0
    _trigger_focus_sweep()
    _apply_font_color()
    queue_redraw()

func _on_button_up() -> void:
    _held = false
    _apply_font_color()
    queue_redraw()

func _on_focus_entered() -> void:
    _scanline_y = 8.0
    _trigger_focus_sweep()
    _apply_font_color()
    queue_redraw()

func _on_focus_exited() -> void:
    _apply_font_color()
    queue_redraw()

func _on_resized() -> void:
    _scanline_y = clampf(_scanline_y, 6.0, max(6.0, size.y - 6.0))

func _trigger_focus_sweep() -> void:
    _focus_sweep_t = 0.0
