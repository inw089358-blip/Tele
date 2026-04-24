extends Control

const TOTAL_STAGE_COUNT: int = 15
var _scene_input_ready: bool = false
var _queued_action: Callable = Callable()
var _queued_action_id: String = ""

func _ready() -> void :
    _build_stage_buttons()
    %BackButton.pressed.connect(_on_back_button_pressed)
    _arm_scene_ready_gate()

func _build_stage_buttons() -> void:
    var list_root: VBoxContainer = $VBoxContainer
    if list_root == null:
        return

    var stage_one_button: Button = %StageOneButton
    var insert_at: int = stage_one_button.get_index()
    stage_one_button.queue_free()

    var scroll := ScrollContainer.new()
    scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.custom_minimum_size = Vector2(0.0, 260.0)
    list_root.add_child(scroll)
    list_root.move_child(scroll, insert_at)

    var stage_list := VBoxContainer.new()
    stage_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    stage_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
    stage_list.add_theme_constant_override("separation", 8)
    scroll.add_child(stage_list)

    for stage_no: int in range(1, TOTAL_STAGE_COUNT + 1):
        var stage_id: String = "stage_%03d" % stage_no
        var button := Button.new()
        button.text = _tf("ui.stage_select.stage_fmt", [stage_no], "Stage %02d")
        button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        button.focus_mode = Control.FOCUS_ALL
        button.pressed.connect(_on_stage_button_pressed.bind(stage_id))
        stage_list.add_child(button)

func _on_stage_button_pressed(stage_id: String) -> void:
    _invoke_or_queue(
        "stage_%s" % stage_id,
        Callable(self, "_do_start_stage").bind(stage_id)
    )

func _on_back_button_pressed() -> void :
    _invoke_or_queue("stage_back", Callable(self, "_do_back"))

func _do_start_stage(stage_id: String) -> void:
    GameManager.start_game(stage_id)

func _do_back() -> void:
    GameManager.go_to_character_select()

func _tf(key: String, args: Array, fallback: String = "") -> String:
    if LocaleService != null:
        return LocaleService.tf(key, args, fallback if not fallback.is_empty() else key)
    var base: String = fallback if not fallback.is_empty() else key
    return base % args

func _arm_scene_ready_gate() -> void:
    _scene_input_ready = false
    call_deferred("_await_scene_input_ready")

func _await_scene_input_ready() -> void:
    await get_tree().process_frame
    var guard: int = 0
    while _is_scene_transition_pending() and guard < 180:
        guard += 1
        await get_tree().process_frame
    await get_tree().process_frame
    await get_tree().process_frame
    _scene_input_ready = true
    _flush_queued_action()

func _invoke_or_queue(action_id: String, action: Callable) -> void:
    if _scene_input_ready and not _is_scene_transition_pending():
        action.call()
        return
    if _queued_action_id.is_empty():
        _queued_action_id = action_id
        _queued_action = action

func _flush_queued_action() -> void:
    if not _queued_action.is_valid():
        return
    var queued: Callable = _queued_action
    _queued_action = Callable()
    _queued_action_id = ""
    queued.call_deferred()

func _is_scene_transition_pending() -> bool:
    var gm_busy: bool = GameManager != null and GameManager.has_method("is_scene_transition_busy") and bool(GameManager.call("is_scene_transition_busy"))
    var crt_busy: bool = CRTTransition != null and CRTTransition.has_method("is_busy") and bool(CRTTransition.call("is_busy"))
    return gm_busy or crt_busy
