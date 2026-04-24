extends Control

const SAVE_SLOT_PANEL_SCENE: PackedScene = preload("res://scenes/ui/save_slot_panel.tscn")

@onready var clock_label: Label = %ClockLabel
@onready var notice_label: Label = %NoticeLabel
@onready var title_label: Label = %TitleLabel
@onready var menu_panel: PanelContainer = $ScreenCenter/CRTFrame/UIRoot/MenuPanel
@onready var ui_feedback_flash: ColorRect = %UIFeedbackFlash
@onready var start_button: Button = %StartButton
@onready var boss_test_button: Button = %BossTestButton
@onready var continue_button: Button = %ContinueButton
@onready var settings_button: Button = %SettingsButton
@onready var quit_button: Button = %QuitButton

var _title_base_pos: Vector2
var _notice_base_alpha: float = 0.85
var _continue_slot_panel: SaveSlotPanel
var _scene_input_ready: bool = false
var _queued_action: Callable = Callable()
var _queued_action_id: String = ""

func _ready() -> void :
    _refresh_static_texts()
    start_button.pressed.connect(_on_start_button_pressed)
    boss_test_button.pressed.connect(_on_boss_test_button_pressed)
    continue_button.pressed.connect(_on_continue_button_pressed)
    settings_button.pressed.connect(_on_settings_button_pressed)
    quit_button.pressed.connect(_on_quit_button_pressed)
    _bind_menu_feedback_fx()
    _title_base_pos = title_label.position
    _notice_base_alpha = notice_label.modulate.a
    _prepare_continue_slot_panel()
    _apply_test_entry_visibility()
    AudioManager.play_menu_bgm()
    _update_clock()
    _arm_scene_ready_gate()

func _process(_delta: float) -> void :
    _update_clock()
    _update_title_glitch()
    _update_notice_glitch()

func _update_clock() -> void :
    var now: Dictionary = Time.get_datetime_dict_from_system()
    clock_label.text = "%02d:%02d" % [now.hour, now.minute]

func _update_title_glitch() -> void :
    var x_offset: float = sin(Time.get_ticks_msec() * 0.004) * 1.2
    var y_offset: float = cos(Time.get_ticks_msec() * 0.0033) * 0.8
    title_label.position = _title_base_pos + Vector2(x_offset, y_offset)

func _update_notice_glitch() -> void:
    var t: float = Time.get_ticks_msec() * 0.001
    var flicker: float = 0.08 * (0.5 + 0.5 * sin(t * 5.2))
    var c: Color = notice_label.modulate
    c.a = clampf(_notice_base_alpha - flicker, 0.45, 1.0)
    notice_label.modulate = c

func _on_start_button_pressed() -> void :
    _invoke_or_queue("start", Callable(self, "_do_start"), _tx("msg.common.loading_short", "Loading..."))

func _on_boss_test_button_pressed() -> void :
    _invoke_or_queue("boss_test", Callable(self, "_do_boss_test"), _tx("msg.common.loading_short", "Loading..."))

func _on_continue_button_pressed() -> void :
    if not _scene_input_ready or _is_scene_transition_pending():
        _queue_action("continue", Callable(self, "_on_continue_button_pressed"), _tx("msg.common.loading_short", "Loading..."))
        return
    if _continue_slot_panel == null:
        notice_label.text = _tx("msg.main.save_panel_unavailable", "Save panel unavailable")
        return
    notice_label.text = _tx("msg.main.select_save_slot", "Select save slot")
    _set_menu_enabled(false)
    _continue_slot_panel.setup(SaveSlotPanel.MODE_LOAD)
    _continue_slot_panel.show_hint(_tx("msg.main.select_slot_to_continue", "Select a slot to continue."))
    _continue_slot_panel.visible = true

func _on_settings_button_pressed() -> void :
    _invoke_or_queue("settings", Callable(self, "_do_settings"), _tx("msg.common.loading_short", "Loading..."))

func _on_quit_button_pressed() -> void :
    _invoke_or_queue("quit", Callable(self, "_do_quit"), _tx("msg.common.loading_short", "Loading..."))

func _refresh_static_texts() -> void:
    start_button.text = _tx("ui.main.start_button", "Start Game")
    boss_test_button.text = _tx("ui.main.boss_test_button", "Boss Test (Stage 5)")
    continue_button.text = _tx("ui.main.continue_button", "Continue")
    settings_button.text = _tx("ui.main.settings_button", "Settings")
    quit_button.text = _tx("ui.main.quit_button", "Quit")
    if notice_label != null:
        notice_label.text = _tx("ui.main.notice_default", "Flickering CRT screen with static noise")

func _prepare_continue_slot_panel() -> void :
    var panel_node: Node = SAVE_SLOT_PANEL_SCENE.instantiate()
    _continue_slot_panel = panel_node as SaveSlotPanel
    if _continue_slot_panel == null:
        panel_node.queue_free()
        return
    add_child(_continue_slot_panel)
    _continue_slot_panel.visible = false
    _continue_slot_panel.slot_selected.connect(_on_continue_slot_selected)
    _continue_slot_panel.panel_closed.connect(_on_continue_slot_closed)

func _on_continue_slot_selected(slot_id: String) -> void :
    if _continue_slot_panel == null:
        return
    var slot_data: Dictionary = SaveSystem.load_from_slot(slot_id)
    if slot_data.is_empty():
        _continue_slot_panel.show_hint(_tx("msg.slot.empty", "This slot is empty."))
        return
    _invoke_or_queue(
        "continue_slot",
        Callable(self, "_do_start_from_slot").bind(slot_data)
    )

func _on_continue_slot_closed() -> void :
    if _continue_slot_panel != null:
        _continue_slot_panel.visible = false
    _set_menu_enabled(true)
    notice_label.text = _tx("msg.common.ready", "Ready")

func _set_menu_enabled(enabled: bool) -> void :
    start_button.disabled = not enabled
    boss_test_button.disabled = not enabled
    continue_button.disabled = not enabled
    settings_button.disabled = not enabled
    quit_button.disabled = not enabled

func _apply_test_entry_visibility() -> void :
    var settings: Dictionary = SaveSystem.get_settings()
    var system_settings: Dictionary = settings.get("system", {})
    boss_test_button.visible = bool(system_settings.get("show_boss_test_entry", true))
    _refresh_menu_panel_height()

func _refresh_menu_panel_height() -> void :
    var buttons: Array[Button] = [
        start_button, 
        boss_test_button, 
        continue_button, 
        quit_button, 
    ]
    var visible_count: int = 0
    var total_height: float = 0.0
    for button: Button in buttons:
        if button != null and button.visible:
            visible_count += 1
            var h: float = button.custom_minimum_size.y
            if h <= 0.0:
                h = button.size.y
            if h <= 0.0:
                h = 42.0
            total_height += h
    visible_count = max(1, visible_count)
    var spacing: float = 14.0
    var panel_padding: float = 28.0
    var target_height: float = total_height + max(0, visible_count - 1) * spacing + panel_padding
    menu_panel.offset_top = menu_panel.offset_bottom - target_height

func _bind_menu_feedback_fx() -> void:
    var menu_buttons: Array[Button] = [
        start_button,
        boss_test_button,
        continue_button,
        quit_button,
        settings_button,
    ]
    for b: Button in menu_buttons:
        if b == null:
            continue
        b.mouse_entered.connect(_on_menu_button_hovered.bind(b))
        b.button_down.connect(_on_menu_button_down.bind(b))

func _on_menu_button_hovered(button: Button) -> void:
    if button == null:
        return
    notice_label.text = "%s %s" % [_tx("msg.main.pointer_prefix", ">>"), button.text]

func _on_menu_button_down(_button: Button) -> void:
    _trigger_ui_flash()

func _trigger_ui_flash() -> void:
    if ui_feedback_flash == null:
        return
    ui_feedback_flash.color = Color(0.509804, 1.0, 0.768627, 0.0)
    var tween: Tween = create_tween()
    tween.set_trans(Tween.TRANS_SINE)
    tween.set_ease(Tween.EASE_OUT)
    tween.tween_property(ui_feedback_flash, "color:a", 0.16, 0.05)
    tween.tween_property(ui_feedback_flash, "color:a", 0.0, 0.16)

func _do_start() -> void:
    notice_label.text = _tx("msg.main.start_new_run", "Start new run")
    AudioManager.play_prepare_bgm()
    GameManager.go_to_character_select()

func _do_boss_test() -> void:
    notice_label.text = _tx("msg.main.jump_stage_015", "Jump to stage_015 (Final boss test)")
    AudioManager.play_prepare_bgm()
    if GameManager.selected_character.is_empty():
        GameManager.selected_character = "the_fool"
    if GameManager.current_difficulty.is_empty():
        GameManager.current_difficulty = "normal"
    GameManager.start_game("stage_015")

func _do_settings() -> void:
    notice_label.text = _tx("msg.main.open_settings", "Open settings")
    GameManager.go_to_settings()

func _do_quit() -> void:
    _trigger_ui_flash()
    _do_quit_async()

func _do_quit_async() -> void:
    if CRTTransition != null and CRTTransition.has_method("play_shutdown"):
        await CRTTransition.play_shutdown()
    get_tree().quit()

func _do_start_from_slot(slot_data: Dictionary) -> void:
    notice_label.text = _tx("msg.main.loading_save", "Loading save...")
    GameManager.start_game_from_slot(slot_data)

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

func _invoke_or_queue(action_id: String, action: Callable, pending_text: String = "") -> void:
    if _scene_input_ready and not _is_scene_transition_pending():
        action.call()
        return
    _queue_action(action_id, action, pending_text)

func _queue_action(action_id: String, action: Callable, pending_text: String = "") -> void:
    if _queued_action_id.is_empty():
        _queued_action_id = action_id
        _queued_action = action
    if not pending_text.is_empty():
        notice_label.text = pending_text

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
