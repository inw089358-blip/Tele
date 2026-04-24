extends Node

const TUBE_SHADER_PATH: String = "res://shaders/crt_tube_collapse.gdshader"
const SHUTDOWN_DURATION: float = 0.75
const STARTUP_DURATION: float = 0.85
const LINE_HOLD_DURATION: float = 0.05

var _layer: CanvasLayer
var _overlay: ColorRect
var _material: ShaderMaterial
var _transition_tween: Tween
var _transition_busy: bool = false
var _boot_played: bool = false
var _layer_attach_queued: bool = false

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _build_overlay()
    _play_boot_startup()

func is_busy() -> bool:
    return _transition_busy

func play_shutdown() -> void:
    await _play_transition(0.0, 1.0, SHUTDOWN_DURATION, true, Tween.EASE_IN, true, false)

func play_startup() -> void:
    await _play_transition(1.0, 0.0, STARTUP_DURATION, false, Tween.EASE_OUT, false, false)

func _build_overlay() -> void:
    if _layer != null and is_instance_valid(_layer):
        return

    _layer = CanvasLayer.new()
    _layer.layer = 200
    _layer.process_mode = Node.PROCESS_MODE_ALWAYS

    _overlay = ColorRect.new()
    _overlay.name = "TubeCollapseOverlay"
    _overlay.anchors_preset = Control.PRESET_FULL_RECT
    _overlay.anchor_right = 1.0
    _overlay.anchor_bottom = 1.0
    _overlay.grow_horizontal = Control.GROW_DIRECTION_BOTH
    _overlay.grow_vertical = Control.GROW_DIRECTION_BOTH
    _overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _overlay.visible = false
    _overlay.process_mode = Node.PROCESS_MODE_ALWAYS

    _material = ShaderMaterial.new()
    var shader: Resource = ResourceLoader.load(TUBE_SHADER_PATH)
    if shader is Shader:
        var typed_shader: Shader = shader
        _material.shader = typed_shader
    _material.set_shader_parameter("progress", 0.0)

    _overlay.material = _material
    _layer.add_child(_overlay)
    _queue_layer_attach()

func _queue_layer_attach() -> void:
    if _layer == null or not is_instance_valid(_layer):
        return
    if _layer.is_inside_tree():
        return
    if _layer_attach_queued:
        return
    _layer_attach_queued = true
    get_tree().root.call_deferred("add_child", _layer)

func _ensure_layer_attached() -> void:
    _queue_layer_attach()
    var guard: int = 0
    while (_layer == null or not _layer.is_inside_tree()) and guard < 8:
        guard += 1
        await get_tree().process_frame
    _layer_attach_queued = false

func _play_transition(
    from_value: float,
    to_value: float,
    duration: float,
    _play_hum: bool,
    ease_type: Tween.EaseType,
    hold_line: bool,
    show_line: bool
) -> void:
    _build_overlay()
    if _overlay == null or _material == null:
        return
    await _ensure_layer_attached()
    if _layer == null or not _layer.is_inside_tree():
        return

    _stop_transition_tween()
    _transition_busy = true

    _overlay.visible = true
    _material.set_shader_parameter("progress", from_value)
    _material.set_shader_parameter("show_line", 1.0 if show_line else 0.0)

    # Disabled by request: CRT hum SFX was affecting UX.

    _transition_tween = create_tween()
    _transition_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
    _transition_tween.set_trans(Tween.TRANS_CUBIC)
    _transition_tween.set_ease(ease_type)
    _transition_tween.tween_property(_material, "shader_parameter/progress", to_value, duration)
    if hold_line:
        _transition_tween.tween_interval(LINE_HOLD_DURATION)
    await _transition_tween.finished

    if is_equal_approx(to_value, 0.0):
        _overlay.visible = false

    _transition_tween = null
    _transition_busy = false

func _stop_transition_tween() -> void:
    if _transition_tween != null and is_instance_valid(_transition_tween):
        _transition_tween.kill()
    _transition_tween = null

func _play_boot_startup() -> void:
    if _boot_played:
        return
    _boot_played = true
    await get_tree().process_frame
    await play_startup()
