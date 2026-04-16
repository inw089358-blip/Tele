extends Control

const SAVE_SLOT_PANEL_SCENE: PackedScene = preload("res://scenes/ui/save_slot_panel.tscn")

@onready var clock_label: Label = %ClockLabel
@onready var notice_label: Label = %NoticeLabel
@onready var title_label: Label = %TitleLabel
@onready var menu_panel: PanelContainer = $ScreenCenter/CRTFrame/UIRoot/MenuPanel
@onready var start_button: Button = %StartButton
@onready var boss_test_button: Button = %BossTestButton
@onready var continue_button: Button = %ContinueButton
@onready var character_button: Button = %CharacterButton
@onready var settings_button: Button = %SettingsButton
@onready var quit_button: Button = %QuitButton

var _title_base_pos: Vector2
var _continue_slot_panel: SaveSlotPanel

func _ready() -> void :
    start_button.pressed.connect(_on_start_button_pressed)
    boss_test_button.pressed.connect(_on_boss_test_button_pressed)
    continue_button.pressed.connect(_on_continue_button_pressed)
    character_button.pressed.connect(_on_character_button_pressed)
    settings_button.pressed.connect(_on_settings_button_pressed)
    quit_button.pressed.connect(_on_quit_button_pressed)
    _title_base_pos = title_label.position
    _prepare_continue_slot_panel()
    _apply_test_entry_visibility()
    AudioManager.play_menu_bgm()
    _update_clock()

func _process(_delta: float) -> void :
    _update_clock()
    _update_title_glitch()

func _update_clock() -> void :
    var now: Dictionary = Time.get_datetime_dict_from_system()
    clock_label.text = "%02d:%02d" % [now.hour, now.minute]

func _update_title_glitch() -> void :
    var x_offset: float = sin(Time.get_ticks_msec() * 0.004) * 1.2
    var y_offset: float = cos(Time.get_ticks_msec() * 0.0033) * 0.8
    title_label.position = _title_base_pos + Vector2(x_offset, y_offset)

func _on_start_button_pressed() -> void :
    notice_label.text = "Start new run"
    AudioManager.play_prepare_bgm()
    GameManager.go_to_character_select()

func _on_boss_test_button_pressed() -> void :
    notice_label.text = "Jump to stage_005 (Boss test)"
    AudioManager.play_prepare_bgm()
    if GameManager.selected_character.is_empty():
        GameManager.selected_character = "the_fool"
    if GameManager.current_difficulty.is_empty():
        GameManager.current_difficulty = "normal"
    GameManager.start_game("stage_005")

func _on_continue_button_pressed() -> void :
    if _continue_slot_panel == null:
        notice_label.text = "Save panel unavailable"
        return
    notice_label.text = "Select save slot"
    _set_menu_enabled(false)
    _continue_slot_panel.setup(SaveSlotPanel.MODE_LOAD)
    _continue_slot_panel.show_hint("Select a slot to continue.")
    _continue_slot_panel.visible = true

func _on_character_button_pressed() -> void :
    notice_label.text = "Select character"
    GameManager.go_to_character_select()

func _on_settings_button_pressed() -> void :
    notice_label.text = "Open settings"
    GameManager.go_to_settings()

func _on_quit_button_pressed() -> void :
    get_tree().quit()

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
        _continue_slot_panel.show_hint("This slot is empty.")
        return
    notice_label.text = "Loading save..."
    GameManager.start_game_from_slot(slot_data)

func _on_continue_slot_closed() -> void :
    if _continue_slot_panel != null:
        _continue_slot_panel.visible = false
    _set_menu_enabled(true)
    notice_label.text = "Ready"

func _set_menu_enabled(enabled: bool) -> void :
    start_button.disabled = not enabled
    boss_test_button.disabled = not enabled
    continue_button.disabled = not enabled
    character_button.disabled = not enabled
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
        character_button, 
        quit_button, 
    ]
    var visible_count: int = 0
    for button: Button in buttons:
        if button != null and button.visible:
            visible_count += 1
    visible_count = max(1, visible_count)
    var button_height: float = 42.0
    var spacing: float = 6.0
    var panel_padding: float = 28.0
    var target_height: float = visible_count * button_height + max(0, visible_count - 1) * spacing + panel_padding
    menu_panel.offset_top = menu_panel.offset_bottom - target_height
