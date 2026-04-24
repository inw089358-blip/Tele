extends Control

const CHARACTER_IDS: PackedStringArray = [
    "the_fool",
    "the_chariot",
    "the_hanged_man",
]

const CHARACTER_COLORS: Array[Color] = [
    Color(0.756863, 0.690196, 0.545098, 1),
    Color(0.666667, 0.4, 0.356863, 1),
    Color(0.54902, 0.647059, 0.780392, 1),
]

@onready var left_arrow_button: Button = %LeftArrowButton
@onready var right_arrow_button: Button = %RightArrowButton
@onready var select_button: Button = %SelectButton
@onready var back_button: Button = %BackButton
@onready var character_name_label: Label = %CharacterNameLabel
@onready var character_hint_label: Label = %CharacterHintLabel
@onready var character_silhouette: ColorRect = %CharacterSilhouette

var _current_index: int = 0
var _scene_input_ready: bool = false
var _queued_action: Callable = Callable()
var _queued_action_id: String = ""

func _ready() -> void :
    left_arrow_button.pressed.connect(_on_left_arrow_pressed)
    right_arrow_button.pressed.connect(_on_right_arrow_pressed)
    select_button.pressed.connect(_on_select_button_pressed)
    back_button.pressed.connect(_on_back_button_pressed)
    _refresh_character_view()
    _arm_scene_ready_gate()

func _unhandled_input(event: InputEvent) -> void :
    if event.is_action_pressed("move_left"):
        _on_left_arrow_pressed()
    elif event.is_action_pressed("move_right"):
        _on_right_arrow_pressed()
    elif event.is_action_pressed("confirm"):
        _on_select_button_pressed()
    elif event.is_action_pressed("cancel"):
        _on_back_button_pressed()

func _on_left_arrow_pressed() -> void :
    _invoke_or_queue("char_left", Callable(self, "_do_left"))

func _on_right_arrow_pressed() -> void :
    _invoke_or_queue("char_right", Callable(self, "_do_right"))

func _on_select_button_pressed() -> void :
    _invoke_or_queue("char_select", Callable(self, "_do_select"))

func _on_back_button_pressed() -> void :
    _invoke_or_queue("char_back", Callable(self, "_do_back"))

func _refresh_character_view() -> void :
    var character_id: String = CHARACTER_IDS[_current_index]
    character_name_label.text = _tx("data.character.%s.name" % character_id, character_id)
    character_hint_label.text = _tx("data.character.%s.hint" % character_id, character_id)
    character_silhouette.color = CHARACTER_COLORS[_current_index]

func _do_left() -> void:
    var character_count: int = CHARACTER_IDS.size()
    _current_index = (_current_index - 1 + character_count) % character_count
    _refresh_character_view()

func _do_right() -> void:
    var character_count: int = CHARACTER_IDS.size()
    _current_index = (_current_index + 1) % character_count
    _refresh_character_view()

func _do_select() -> void:
    GameManager.go_to_weapon_select(CHARACTER_IDS[_current_index])

func _do_back() -> void:
    GameManager.go_to_menu()

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
        character_hint_label.text = _tx("msg.common.loading_short", "Loading...")

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

func _tx(key: String, fallback: String = "") -> String:
    if LocaleService != null:
        return LocaleService.tx(key, fallback if not fallback.is_empty() else key)
    if fallback.is_empty():
        return key
    return fallback
