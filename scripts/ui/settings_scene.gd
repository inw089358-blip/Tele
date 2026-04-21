extends Control

signal request_close

const RESOLUTION_OPTIONS: PackedStringArray = [
    "1280x720", 
    "1600x900", 
    "1920x1080", 
]
const WINDOW_MODE_KEYS: PackedStringArray = [
    "windowed", 
    "borderless", 
    "fullscreen", 
]
const WINDOW_MODE_LABELS: PackedStringArray = [
    "Windowed", 
    "Borderless", 
    "Fullscreen", 
]
const FPS_CAP_KEYS: PackedInt32Array = [30, 60, 120, 0]
const FPS_CAP_LABELS: PackedStringArray = [
    "30", 
    "60", 
    "120", 
    "Unlimited", 
]
const CRT_KEYS: PackedStringArray = ["off", "low", "mid", "high"]
const CRT_LABELS: PackedStringArray = ["Off", "Low", "Mid", "High"]
const COLORBLIND_KEYS: PackedStringArray = ["off", "protanopia", "deuteranopia", "tritanopia"]
const COLORBLIND_LABELS: PackedStringArray = ["Off", "Protanopia", "Deuteranopia", "Tritanopia"]
const FONT_SIZE_KEYS: PackedStringArray = ["small", "medium", "large"]
const FONT_SIZE_LABELS: PackedStringArray = ["Small", "Medium", "Large"]
const LANGUAGE_KEYS: PackedStringArray = ["zh_CN", "en_US"]
const LANGUAGE_LABELS: PackedStringArray = ["Chinese (Simplified)", "English"]

@onready var display_tab_button: Button = %DisplayTabButton
@onready var audio_tab_button: Button = %AudioTabButton
@onready var input_tab_button: Button = %InputTabButton
@onready var system_tab_button: Button = %SystemTabButton
@onready var crt_frame: PanelContainer = $ScreenCenter/CRTFrame
@onready var title_label: Label = $ScreenCenter/CRTFrame/MainMargin/RootVBox/TitleLabel

@onready var display_panel: VBoxContainer = %DisplayPanel
@onready var audio_panel: VBoxContainer = %AudioPanel
@onready var input_panel: VBoxContainer = %InputPanel
@onready var accessibility_panel: VBoxContainer = %AccessibilityPanel
@onready var system_panel: VBoxContainer = %SystemPanel

@onready var resolution_option: OptionButton = %ResolutionOption
@onready var window_mode_option: OptionButton = %WindowModeOption
@onready var vsync_checkbox: CheckBox = %VSyncCheckBox
@onready var fps_cap_option: OptionButton = %FpsCapOption
@onready var crt_option: OptionButton = %CrtIntensityOption
@onready var ui_scale_slider: HSlider = %UiScaleSlider
@onready var ui_scale_value_label: Label = %UiScaleValueLabel

@onready var master_volume_slider: HSlider = %MasterVolumeSlider
@onready var master_volume_value_label: Label = %MasterVolumeValueLabel
@onready var music_volume_slider: HSlider = %MusicVolumeSlider
@onready var music_volume_value_label: Label = %MusicVolumeValueLabel
@onready var sfx_volume_slider: HSlider = %SfxVolumeSlider
@onready var sfx_volume_value_label: Label = %SfxVolumeValueLabel
@onready var ui_volume_slider: HSlider = %UiVolumeSlider
@onready var ui_volume_value_label: Label = %UiVolumeValueLabel

@onready var right_click_skill_checkbox: CheckBox = %RightClickSkillCheckBox

@onready var colorblind_option: OptionButton = %ColorblindModeOption
@onready var high_contrast_checkbox: CheckBox = %HighContrastCheckBox
@onready var font_size_option: OptionButton = %FontSizeOption
@onready var glitch_intensity_option: OptionButton = %GlitchIntensityOption
@onready var simple_ui_checkbox: CheckBox = %SimpleUICheckBox

@onready var language_option: OptionButton = %LanguageOption
@onready var show_boss_test_checkbox: CheckBox = %ShowBossTestCheckBox

@onready var apply_button: Button = %ApplyButton
@onready var cancel_button: Button = %CancelButton
@onready var restore_defaults_button: Button = %RestoreDefaultsButton
@onready var back_button: Button = %BackButton
@onready var status_label: Label = %StatusLabel

@onready var unsaved_confirm_dialog: ConfirmationDialog = %UnsavedConfirmDialog
@onready var restore_confirm_dialog: ConfirmationDialog = %RestoreConfirmDialog

var _saved_settings: Dictionary = {}
var _active_category: String = "graphics"
var _embedded_mode: bool = false

func _ready() -> void :
    _setup_options()
    _connect_signals()
    _merge_graphics_sections()
    _enable_graphics_scrolling()
    _load_settings()
    _show_category(_active_category)
    _refresh_live_labels()
    status_label.text = ""

func _unhandled_input(event: InputEvent) -> void :
    if event.is_action_pressed("cancel"):
        _on_back_button_pressed()

func _setup_options() -> void :
    _fill_option_from_values(resolution_option, RESOLUTION_OPTIONS)
    _fill_option_from_key_label(window_mode_option, WINDOW_MODE_KEYS, WINDOW_MODE_LABELS)
    _fill_option_from_int_label(fps_cap_option, FPS_CAP_KEYS, FPS_CAP_LABELS)
    _fill_option_from_key_label(crt_option, CRT_KEYS, CRT_LABELS)
    _fill_option_from_key_label(colorblind_option, COLORBLIND_KEYS, COLORBLIND_LABELS)
    _fill_option_from_key_label(font_size_option, FONT_SIZE_KEYS, FONT_SIZE_LABELS)
    _fill_option_from_key_label(glitch_intensity_option, CRT_KEYS, CRT_LABELS)
    _fill_option_from_key_label(language_option, LANGUAGE_KEYS, LANGUAGE_LABELS)

func _connect_signals() -> void :
    display_tab_button.pressed.connect(_on_display_tab_pressed)
    audio_tab_button.pressed.connect(_on_audio_tab_pressed)
    input_tab_button.pressed.connect(_on_input_tab_pressed)
    system_tab_button.pressed.connect(_on_system_tab_pressed)

    ui_scale_slider.value_changed.connect(_on_ui_scale_changed)
    master_volume_slider.value_changed.connect(_on_master_volume_changed)
    music_volume_slider.value_changed.connect(_on_music_volume_changed)
    sfx_volume_slider.value_changed.connect(_on_sfx_volume_changed)
    ui_volume_slider.value_changed.connect(_on_ui_volume_changed)

    apply_button.pressed.connect(_on_apply_button_pressed)
    cancel_button.pressed.connect(_on_cancel_button_pressed)
    restore_defaults_button.pressed.connect(_on_restore_defaults_button_pressed)
    back_button.pressed.connect(_on_back_button_pressed)

    unsaved_confirm_dialog.confirmed.connect(_on_unsaved_leave_confirmed)
    restore_confirm_dialog.confirmed.connect(_on_restore_confirmed)

func _load_settings() -> void :
    var save_data: Dictionary = SaveSystem.load_save()
    var settings_value: Variant = save_data.get("settings", SaveSystem.DEFAULT_SETTINGS.duplicate(true))

    _saved_settings = SaveSystem.DEFAULT_SETTINGS.duplicate(true)
    if settings_value is Dictionary:
        _saved_settings = settings_value.duplicate(true)

    _apply_settings_to_controls(_saved_settings)
    GameManager.apply_runtime_settings(_saved_settings)

func _show_category(category: String) -> void :
    _active_category = category
    display_panel.visible = category == "graphics"
    audio_panel.visible = category == "audio"
    input_panel.visible = category == "controls"
    accessibility_panel.visible = false
    system_panel.visible = category == "gameplay"
    _refresh_nav_visuals()

func _merge_graphics_sections() -> void:
    if display_panel == null or accessibility_panel == null:
        return
    if accessibility_panel.get_parent() != display_panel.get_parent():
        return
    var moved_marker: Node = display_panel.get_node_or_null("GraphicsExtraMarker")
    if moved_marker != null:
        return

    var marker: Node = Node.new()
    marker.name = "GraphicsExtraMarker"
    display_panel.add_child(marker)

    var separator: HSeparator = HSeparator.new()
    display_panel.add_child(separator)
    var section_label: Label = Label.new()
    section_label.text = "Advanced Visual Options"
    section_label.add_theme_font_size_override("font_size", 22)
    section_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.86, 1.0))
    display_panel.add_child(section_label)

    var children_to_move: Array[Node] = []
    for child: Node in accessibility_panel.get_children():
        children_to_move.append(child)
    for child: Node in children_to_move:
        accessibility_panel.remove_child(child)
        display_panel.add_child(child)

func _enable_graphics_scrolling() -> void:
    if display_panel == null:
        return
    if display_panel.get_node_or_null("GraphicsScroll") != null:
        return

    var title: Node = display_panel.get_node_or_null("DisplayTitle")
    var content_nodes: Array[Node] = []
    for child: Node in display_panel.get_children():
        if child == title:
            continue
        content_nodes.append(child)

    if content_nodes.is_empty():
        return

    var scroll: ScrollContainer = ScrollContainer.new()
    scroll.name = "GraphicsScroll"
    scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.follow_focus = true
    display_panel.add_child(scroll)

    var content_vbox: VBoxContainer = VBoxContainer.new()
    content_vbox.name = "GraphicsScrollContent"
    content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
    content_vbox.add_theme_constant_override("separation", 10)
    scroll.add_child(content_vbox)

    for child: Node in content_nodes:
        display_panel.remove_child(child)
        content_vbox.add_child(child)

func _apply_settings_to_controls(settings: Dictionary) -> void :
    var display_settings: Dictionary = settings.get("display", {})
    var audio_settings: Dictionary = settings.get("audio", {})
    var input_settings: Dictionary = settings.get("input", {})
    var accessibility_settings: Dictionary = settings.get("accessibility", {})
    var system_settings: Dictionary = settings.get("system", {})

    _select_option_by_text(resolution_option, str(display_settings.get("resolution", "1920x1080")))
    _select_option_by_metadata(window_mode_option, str(display_settings.get("window_mode", "fullscreen")))
    vsync_checkbox.button_pressed = bool(display_settings.get("vsync", true))
    _select_option_by_metadata(fps_cap_option, int(display_settings.get("fps_cap", 60)))
    _select_option_by_metadata(crt_option, str(display_settings.get("crt_intensity", "mid")))
    ui_scale_slider.value = int(display_settings.get("ui_scale", 100))

    master_volume_slider.value = int(audio_settings.get("master_volume", 80))
    music_volume_slider.value = int(audio_settings.get("music_volume", 70))
    sfx_volume_slider.value = int(audio_settings.get("sfx_volume", 90))
    ui_volume_slider.value = int(audio_settings.get("ui_volume", 80))

    right_click_skill_checkbox.button_pressed = bool(input_settings.get("right_click_skill", true))

    _select_option_by_metadata(colorblind_option, str(accessibility_settings.get("colorblind_mode", "off")))
    high_contrast_checkbox.button_pressed = bool(accessibility_settings.get("high_contrast_ui", false))
    _select_option_by_metadata(font_size_option, str(accessibility_settings.get("font_size", "medium")))
    _select_option_by_metadata(glitch_intensity_option, str(accessibility_settings.get("glitch_intensity", "mid")))
    simple_ui_checkbox.button_pressed = bool(accessibility_settings.get("simple_ui", false))

    _select_option_by_metadata(language_option, str(system_settings.get("language", "zh_CN")))
    show_boss_test_checkbox.button_pressed = bool(system_settings.get("show_boss_test_entry", true))
    _refresh_live_labels()

func _collect_settings_from_controls() -> Dictionary:
    var settings: Dictionary = SaveSystem.DEFAULT_SETTINGS.duplicate(true)

    var display_settings: Dictionary = settings["display"]
    display_settings["resolution"] = resolution_option.get_item_text(resolution_option.selected)
    display_settings["window_mode"] = _selected_option_metadata_as_string(window_mode_option, "fullscreen")
    display_settings["vsync"] = vsync_checkbox.button_pressed
    display_settings["fps_cap"] = _selected_option_metadata_as_int(fps_cap_option, 60)
    display_settings["crt_intensity"] = _selected_option_metadata_as_string(crt_option, "mid")
    display_settings["ui_scale"] = int(ui_scale_slider.value)

    var audio_settings: Dictionary = settings["audio"]
    audio_settings["master_volume"] = int(master_volume_slider.value)
    audio_settings["music_volume"] = int(music_volume_slider.value)
    audio_settings["sfx_volume"] = int(sfx_volume_slider.value)
    audio_settings["ui_volume"] = int(ui_volume_slider.value)

    var input_settings: Dictionary = settings["input"]
    input_settings["right_click_skill"] = right_click_skill_checkbox.button_pressed

    var accessibility_settings: Dictionary = settings["accessibility"]
    accessibility_settings["colorblind_mode"] = _selected_option_metadata_as_string(colorblind_option, "off")
    accessibility_settings["high_contrast_ui"] = high_contrast_checkbox.button_pressed
    accessibility_settings["font_size"] = _selected_option_metadata_as_string(font_size_option, "medium")
    accessibility_settings["glitch_intensity"] = _selected_option_metadata_as_string(glitch_intensity_option, "mid")
    accessibility_settings["simple_ui"] = simple_ui_checkbox.button_pressed

    var system_settings: Dictionary = settings["system"]
    system_settings["language"] = _selected_option_metadata_as_string(language_option, "zh_CN")
    system_settings["show_boss_test_entry"] = show_boss_test_checkbox.button_pressed

    return settings

func _refresh_live_labels() -> void :
    ui_scale_value_label.text = "%d%%" % int(ui_scale_slider.value)
    master_volume_value_label.text = "%d%%" % int(master_volume_slider.value)
    music_volume_value_label.text = "%d%%" % int(music_volume_slider.value)
    sfx_volume_value_label.text = "%d%%" % int(sfx_volume_slider.value)
    ui_volume_value_label.text = "%d%%" % int(ui_volume_slider.value)

func _on_display_tab_pressed() -> void :
    _show_category("graphics")

func _on_audio_tab_pressed() -> void :
    _show_category("audio")

func _on_input_tab_pressed() -> void :
    _show_category("controls")

func _on_system_tab_pressed() -> void :
    _show_category("gameplay")

func _on_ui_scale_changed(_value: float) -> void :
    _refresh_live_labels()

func _on_master_volume_changed(_value: float) -> void :
    _refresh_live_labels()

func _on_music_volume_changed(_value: float) -> void :
    _refresh_live_labels()

func _on_sfx_volume_changed(_value: float) -> void :
    _refresh_live_labels()

func _on_ui_volume_changed(_value: float) -> void :
    _refresh_live_labels()

func _on_apply_button_pressed() -> void :
    var settings: Dictionary = _collect_settings_from_controls()
    var save_data: Dictionary = SaveSystem.load_save()
    save_data["settings"] = settings.duplicate(true)
    SaveSystem.write_save(save_data)
    _saved_settings = settings.duplicate(true)
    GameManager.apply_runtime_settings(_saved_settings)
    status_label.text = "Settings applied"

func _on_cancel_button_pressed() -> void :
    if _embedded_mode:
        _request_close_embedded()
        return
    _apply_settings_to_controls(_saved_settings)
    status_label.text = "Changes canceled"

func _on_restore_defaults_button_pressed() -> void :
    restore_confirm_dialog.popup_centered()

func _on_restore_confirmed() -> void :
    _apply_settings_to_controls(SaveSystem.DEFAULT_SETTINGS.duplicate(true))
    status_label.text = "Defaults restored (not yet applied)"

func _on_back_button_pressed() -> void :
    if _has_unsaved_changes():
        unsaved_confirm_dialog.popup_centered()
        return
    if _embedded_mode:
        _request_close_embedded()
        return
    GameManager.go_to_menu()

func _on_unsaved_leave_confirmed() -> void :
    if _embedded_mode:
        _request_close_embedded()
        return
    GameManager.go_to_menu()

func _has_unsaved_changes() -> bool:
    var current_settings: Dictionary = _collect_settings_from_controls()
    return JSON.stringify(current_settings) != JSON.stringify(_saved_settings)

func _fill_option_from_values(option: OptionButton, values: PackedStringArray) -> void :
    option.clear()
    for i in values.size():
        option.add_item(values[i])
        option.set_item_metadata(i, values[i])

func _fill_option_from_key_label(option: OptionButton, keys: PackedStringArray, labels: PackedStringArray) -> void :
    option.clear()
    var total: int = min(keys.size(), labels.size())
    for i in total:
        option.add_item(labels[i])
        option.set_item_metadata(i, keys[i])

func _fill_option_from_int_label(option: OptionButton, keys: PackedInt32Array, labels: PackedStringArray) -> void :
    option.clear()
    var total: int = min(keys.size(), labels.size())
    for i in total:
        option.add_item(labels[i])
        option.set_item_metadata(i, keys[i])

func _select_option_by_metadata(option: OptionButton, target: Variant) -> void :
    for i in option.item_count:
        if option.get_item_metadata(i) == target:
            option.select(i)
            return
    if option.item_count > 0:
        option.select(0)

func _select_option_by_text(option: OptionButton, target: String) -> void :
    for i in option.item_count:
        if option.get_item_text(i) == target:
            option.select(i)
            return
    if option.item_count > 0:
        option.select(0)

func _selected_option_metadata_as_string(option: OptionButton, fallback: String) -> String:
    if option.selected < 0:
        return fallback
    return str(option.get_item_metadata(option.selected))

func _selected_option_metadata_as_int(option: OptionButton, fallback: int) -> int:
    if option.selected < 0:
        return fallback
    return int(option.get_item_metadata(option.selected))

func set_embedded_mode(enabled: bool) -> void :
    _embedded_mode = enabled
    var black_bg: ColorRect = get_node_or_null("BlackBg") as ColorRect
    if black_bg != null:
        black_bg.visible = not enabled
    if crt_frame != null:
        if enabled:
            crt_frame.anchor_left = 0.03
            crt_frame.anchor_top = 0.04
            crt_frame.anchor_right = 0.97
            crt_frame.anchor_bottom = 0.96
        else:
            crt_frame.anchor_left = 0.08
            crt_frame.anchor_top = 0.06
            crt_frame.anchor_right = 0.92
            crt_frame.anchor_bottom = 0.94
    if title_label != null:
        title_label.text = "SYSTEM SETTINGS"
        title_label.add_theme_font_size_override("font_size", 34 if enabled else 42)

func _refresh_nav_visuals() -> void:
    _set_tab_active(display_tab_button, _active_category == "graphics")
    _set_tab_active(audio_tab_button, _active_category == "audio")
    _set_tab_active(input_tab_button, _active_category == "controls")
    _set_tab_active(system_tab_button, _active_category == "gameplay")

func _set_tab_active(button: Button, is_active: bool) -> void:
    if button == null:
        return
    button.modulate = Color(0.5, 1.0, 0.86, 1.0) if is_active else Color(0.62, 0.86, 0.92, 0.92)

func _request_close_embedded() -> void :
    request_close.emit()
