extends Control

@onready var easy_button: Button = %EasyButton
@onready var normal_button: Button = %NormalButton
@onready var hard_button: Button = %HardButton
@onready var back_button: Button = %BackButton
var _scene_input_ready: bool = false
var _queued_action: Callable = Callable()
var _queued_action_id: String = ""

func _ready() -> void :
    easy_button.pressed.connect(_on_easy_pressed)
    normal_button.pressed.connect(_on_normal_pressed)
    hard_button.pressed.connect(_on_hard_pressed)
    back_button.pressed.connect(_on_back_pressed)
    _arm_scene_ready_gate()

func _unhandled_input(event: InputEvent) -> void :
    if event.is_action_pressed("cancel"):
        _on_back_pressed()

func _on_easy_pressed() -> void :
    _invoke_or_queue("difficulty_easy", Callable(self, "_do_easy"))

func _on_normal_pressed() -> void :
    _invoke_or_queue("difficulty_normal", Callable(self, "_do_normal"))

func _on_hard_pressed() -> void :
    _invoke_or_queue("difficulty_hard", Callable(self, "_do_hard"))

func _on_back_pressed() -> void :
    _invoke_or_queue("difficulty_back", Callable(self, "_do_back"))

func _do_easy() -> void:
    GameManager.start_new_run_with_difficulty("easy")

func _do_normal() -> void:
    GameManager.start_new_run_with_difficulty("normal")

func _do_hard() -> void:
    GameManager.start_new_run_with_difficulty("hard")

func _do_back() -> void:
    GameManager.go_to_weapon_select(GameManager.selected_character)

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
