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
const WINDOW_MODE_LABEL_KEYS: PackedStringArray = [
    "ui.settings.option.windowed", 
    "ui.settings.option.borderless", 
    "ui.settings.option.fullscreen", 
]
const FPS_CAP_KEYS: PackedInt32Array = [30, 60, 120, 0]
const FPS_CAP_LABEL_KEYS: PackedStringArray = [
    "ui.settings.option.30", 
    "ui.settings.option.60", 
    "ui.settings.option.120", 
    "ui.settings.option.unlimited", 
]
const LANGUAGE_KEYS: PackedStringArray = ["zh_CN", "en_US"]

@onready var display_tab_button: Button = %DisplayTabButton
@onready var audio_tab_button: Button = %AudioTabButton
@onready var system_tab_button: Button = %SystemTabButton
@onready var crt_frame: PanelContainer = $ScreenCenter/CRTFrame
@onready var title_label: Label = $ScreenCenter/CRTFrame/MainMargin/RootVBox/TitleLabel

@onready var display_panel: VBoxContainer = %DisplayPanel
@onready var audio_panel: VBoxContainer = %AudioPanel
@onready var system_panel: VBoxContainer = %SystemPanel

@onready var resolution_option: OptionButton = %ResolutionOption
@onready var window_mode_option: OptionButton = %WindowModeOption
@onready var vsync_checkbox: CheckBox = %VSyncCheckBox
@onready var fps_cap_option: OptionButton = %FpsCapOption
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

@onready var language_option: OptionButton = %LanguageOption
@onready var show_boss_test_checkbox: CheckBox = %ShowBossTestCheckBox
@onready var show_boss_test_label: Label = %ShowBossTestLabel

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
var _status_message_key: String = ""
var _status_message_args: Array = []
var _suppress_locale_preview: bool = false

func _ready() -> void :
    _setup_options()
    _disable_boss_test_setting()
    _connect_signals()
    _load_settings()
    _show_category(_active_category)
    _refresh_live_labels()
    _set_status("")
    _refresh_i18n_texts()

func _unhandled_input(event: InputEvent) -> void :
    if event.is_action_pressed("cancel"):
        _on_back_button_pressed()

func _setup_options() -> void :
    _fill_option_from_values(resolution_option, RESOLUTION_OPTIONS)
    _fill_option_from_key_label_keys(window_mode_option, WINDOW_MODE_KEYS, WINDOW_MODE_LABEL_KEYS)
    _fill_option_from_int_label_keys(fps_cap_option, FPS_CAP_KEYS, FPS_CAP_LABEL_KEYS)
    _fill_language_option()

func _connect_signals() -> void :
    display_tab_button.pressed.connect(_on_display_tab_pressed)
    audio_tab_button.pressed.connect(_on_audio_tab_pressed)
    system_tab_button.pressed.connect(_on_system_tab_pressed)

    ui_scale_slider.value_changed.connect(_on_ui_scale_changed)
    master_volume_slider.value_changed.connect(_on_master_volume_changed)
    music_volume_slider.value_changed.connect(_on_music_volume_changed)
    sfx_volume_slider.value_changed.connect(_on_sfx_volume_changed)
    ui_volume_slider.value_changed.connect(_on_ui_volume_changed)
    language_option.item_selected.connect(_on_language_option_selected)

    apply_button.pressed.connect(_on_apply_button_pressed)
    cancel_button.pressed.connect(_on_cancel_button_pressed)
    restore_defaults_button.pressed.connect(_on_restore_defaults_button_pressed)
    back_button.pressed.connect(_on_back_button_pressed)

    unsaved_confirm_dialog.confirmed.connect(_on_unsaved_leave_confirmed)
    restore_confirm_dialog.confirmed.connect(_on_restore_confirmed)

    if LocaleService != null and not LocaleService.locale_changed.is_connected(_on_locale_changed):
        LocaleService.locale_changed.connect(_on_locale_changed)

func _load_settings() -> void :
    _saved_settings = SaveSystem.get_settings().duplicate(true)

    _apply_settings_to_controls(_saved_settings)
    GameManager.apply_runtime_settings(_saved_settings)

func _show_category(category: String) -> void :
    _active_category = category
    display_panel.visible = category == "graphics"
    audio_panel.visible = category == "audio"
    system_panel.visible = category == "gameplay"
    _refresh_nav_visuals()

func _apply_settings_to_controls(settings: Dictionary) -> void :
    _suppress_locale_preview = true
    var display_settings: Dictionary = settings.get("display", {})
    var audio_settings: Dictionary = settings.get("audio", {})
    var system_settings: Dictionary = settings.get("system", {})

    _select_option_by_text(resolution_option, str(display_settings.get("resolution", "1920x1080")))
    _select_option_by_metadata(window_mode_option, str(display_settings.get("window_mode", "fullscreen")))
    vsync_checkbox.button_pressed = bool(display_settings.get("vsync", true))
    _select_option_by_metadata(fps_cap_option, int(display_settings.get("fps_cap", 60)))
    ui_scale_slider.value = int(display_settings.get("ui_scale", 100))

    master_volume_slider.value = int(audio_settings.get("master_volume", 80))
    music_volume_slider.value = int(audio_settings.get("music_volume", 70))
    sfx_volume_slider.value = int(audio_settings.get("sfx_volume", 90))
    ui_volume_slider.value = int(audio_settings.get("ui_volume", 80))

    _select_option_by_metadata(language_option, str(system_settings.get("language", "zh_CN")))
    show_boss_test_checkbox.button_pressed = false
    _refresh_live_labels()
    _suppress_locale_preview = false

func _collect_settings_from_controls() -> Dictionary:
    var settings: Dictionary = _saved_settings.duplicate(true) if not _saved_settings.is_empty() else SaveSystem.DEFAULT_SETTINGS.duplicate(true)

    if not settings.has("display") or not (settings["display"] is Dictionary):
        settings["display"] = SaveSystem.DEFAULT_SETTINGS["display"].duplicate(true)
    if not settings.has("audio") or not (settings["audio"] is Dictionary):
        settings["audio"] = SaveSystem.DEFAULT_SETTINGS["audio"].duplicate(true)
    if not settings.has("system") or not (settings["system"] is Dictionary):
        settings["system"] = SaveSystem.DEFAULT_SETTINGS["system"].duplicate(true)

    var display_settings: Dictionary = settings["display"]
    display_settings["resolution"] = resolution_option.get_item_text(resolution_option.selected)
    display_settings["window_mode"] = _selected_option_metadata_as_string(window_mode_option, "fullscreen")
    display_settings["vsync"] = vsync_checkbox.button_pressed
    display_settings["fps_cap"] = _selected_option_metadata_as_int(fps_cap_option, 60)
    display_settings["ui_scale"] = int(ui_scale_slider.value)

    var audio_settings: Dictionary = settings["audio"]
    audio_settings["master_volume"] = int(master_volume_slider.value)
    audio_settings["music_volume"] = int(music_volume_slider.value)
    audio_settings["sfx_volume"] = int(sfx_volume_slider.value)
    audio_settings["ui_volume"] = int(ui_volume_slider.value)

    var system_settings: Dictionary = settings["system"]
    system_settings["language"] = _selected_option_metadata_as_string(language_option, "zh_CN")
    system_settings["show_boss_test_entry"] = false

    return settings

func _disable_boss_test_setting() -> void:
    if show_boss_test_label != null:
        show_boss_test_label.visible = false
    if show_boss_test_checkbox != null:
        show_boss_test_checkbox.button_pressed = false
        show_boss_test_checkbox.disabled = true
        show_boss_test_checkbox.visible = false

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
    _set_status("msg.settings.applied")

func _on_cancel_button_pressed() -> void :
    if _embedded_mode:
        _request_close_embedded()
        return
    _apply_settings_to_controls(_saved_settings)
    GameManager.apply_runtime_settings(_saved_settings)
    _set_status("msg.settings.canceled")

func _on_restore_defaults_button_pressed() -> void :
    restore_confirm_dialog.popup_centered()

func _on_restore_confirmed() -> void :
    _apply_settings_to_controls(SaveSystem.DEFAULT_SETTINGS.duplicate(true))
    if LocaleService != null:
        LocaleService.apply_locale(_selected_option_metadata_as_string(language_option, "zh_CN"))
    _refresh_i18n_texts()
    _set_status("msg.settings.defaults_restored")

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

func _fill_option_from_key_label_keys(option: OptionButton, keys: PackedStringArray, label_keys: PackedStringArray) -> void :
    option.clear()
    var total: int = min(keys.size(), label_keys.size())
    for i in total:
        option.add_item(_tx(label_keys[i], label_keys[i]))
        option.set_item_metadata(i, keys[i])

func _fill_option_from_int_label_keys(option: OptionButton, keys: PackedInt32Array, label_keys: PackedStringArray) -> void :
    option.clear()
    var total: int = min(keys.size(), label_keys.size())
    for i in total:
        option.add_item(_tx(label_keys[i], label_keys[i]))
        option.set_item_metadata(i, keys[i])

func _fill_language_option() -> void:
    language_option.clear()
    for i: int in range(LANGUAGE_KEYS.size()):
        var locale_key: String = LANGUAGE_KEYS[i]
        var label: String = locale_key
        if LocaleService != null:
            label = LocaleService.get_locale_label(locale_key)
        language_option.add_item(label)
        language_option.set_item_metadata(i, locale_key)

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
        title_label.text = _tx("ui.settings.title", "SYSTEM SETTINGS")
        title_label.add_theme_font_size_override("font_size", 34 if enabled else 42)

func _refresh_nav_visuals() -> void:
    _set_tab_active(display_tab_button, _active_category == "graphics")
    _set_tab_active(audio_tab_button, _active_category == "audio")
    _set_tab_active(system_tab_button, _active_category == "gameplay")

func _set_tab_active(button: Button, is_active: bool) -> void:
    if button == null:
        return
    button.modulate = Color(0.5, 1.0, 0.86, 1.0) if is_active else Color(0.62, 0.86, 0.92, 0.92)

func _on_language_option_selected(_index: int) -> void:
    if _suppress_locale_preview:
        return
    if LocaleService == null:
        return
    LocaleService.apply_locale(_selected_option_metadata_as_string(language_option, "zh_CN"))
    _refresh_i18n_texts()

func _on_locale_changed(_locale: String) -> void:
    _refresh_i18n_texts()

func _refresh_i18n_texts() -> void:
    _refresh_option_labels()
    if title_label != null:
        title_label.text = _tx("ui.settings.title", "SYSTEM SETTINGS")
    _refresh_static_label_texts()
    _apply_status_text()

func _refresh_static_label_texts() -> void:
    var node_texts: Dictionary = {
        "DisplayTabButton": "DISPLAY",
        "AudioTabButton": "AUDIO",
        "SystemTabButton": "SYSTEM",
        "DisplayTitle": "Graphics",
        "AudioTitle": "Audio",
        "SystemTitle": "SYSTEM",
        "ResolutionLabel": "Resolution",
        "WindowModeLabel": "Window Mode",
        "VSyncLabel": "VSync",
        "FpsCapLabel": "FPS Cap",
        "UiScaleLabel": "UI Scale",
        "MasterLabel": "Master Volume",
        "MusicLabel": "Music Volume",
        "SfxLabel": "SFX Volume",
        "UiLabel": "UI Volume",
        "LanguageLabel": "Language",
        "ShowBossTestLabel": "Boss Test Entry",
        "ApplyButton": "APPLY",
        "CancelButton": "CANCEL",
        "RestoreDefaultsButton": "DEFAULTS",
        "BackButton": "BACK",
    }
    for node_name: String in node_texts.keys():
        var target: Node = find_child(node_name, true, false)
        if target != null and (target is Label or target is Button):
            var key: String = str(node_texts[node_name])
            target.set("text", _tx(key, key))
    if vsync_checkbox != null:
        vsync_checkbox.text = _tx("Enable VSync", "Enable VSync")
    if show_boss_test_checkbox != null:
        show_boss_test_checkbox.text = _tx("Show on Main Menu", "Show on Main Menu")
    if unsaved_confirm_dialog != null:
        unsaved_confirm_dialog.ok_button_text = _tx("Leave", "Leave")
        unsaved_confirm_dialog.cancel_button_text = _tx("Continue Editing", "Continue Editing")
        unsaved_confirm_dialog.dialog_text = _tx("You have unsaved changes. Leave without applying?", "You have unsaved changes. Leave without applying?")
    if restore_confirm_dialog != null:
        restore_confirm_dialog.cancel_button_text = _tx("Cancel", "Cancel")
        restore_confirm_dialog.dialog_text = _tx("Restore current page settings to defaults?", "Restore current page settings to defaults?")

func _refresh_option_labels() -> void:
    var window_mode_selection: String = _selected_option_metadata_as_string(window_mode_option, "fullscreen")
    var fps_selection: int = _selected_option_metadata_as_int(fps_cap_option, 60)
    var language_selection: String = _selected_option_metadata_as_string(language_option, "zh_CN")

    _suppress_locale_preview = true
    _fill_option_from_key_label_keys(window_mode_option, WINDOW_MODE_KEYS, WINDOW_MODE_LABEL_KEYS)
    _fill_option_from_int_label_keys(fps_cap_option, FPS_CAP_KEYS, FPS_CAP_LABEL_KEYS)
    _fill_language_option()
    _suppress_locale_preview = false

    _select_option_by_metadata(window_mode_option, window_mode_selection)
    _select_option_by_metadata(fps_cap_option, fps_selection)
    _select_option_by_metadata(language_option, language_selection)

func _set_status(message_key: String, args: Array = []) -> void:
    _status_message_key = message_key
    _status_message_args = args.duplicate()
    _apply_status_text()

func _apply_status_text() -> void:
    if status_label == null:
        return
    if _status_message_key.is_empty():
        status_label.text = ""
        return
    if LocaleService != null:
        status_label.text = LocaleService.tf(_status_message_key, _status_message_args, _status_message_key)
        return
    if _status_message_args.is_empty():
        status_label.text = _status_message_key
    else:
        status_label.text = _status_message_key % _status_message_args

func _tx(key: String, fallback: String = "") -> String:
    if LocaleService != null:
        return LocaleService.tx(key, fallback if not fallback.is_empty() else key)
    if fallback.is_empty():
        return key
    return fallback

func _request_close_embedded() -> void :
    request_close.emit()
