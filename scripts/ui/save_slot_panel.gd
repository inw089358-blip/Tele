class_name SaveSlotPanel
extends PanelContainer

signal slot_selected(slot_id: String)
signal panel_closed

const MODE_LOAD: String = "load"
const MODE_SAVE: String = "save"
const SLOT_IDS: PackedStringArray = ["slot_1", "slot_2", "slot_3"]
const PANEL_SIZE: Vector2 = Vector2(560, 428)
const SLOT_BUTTON_SIZE: Vector2 = Vector2(496, 82)
const CLOSE_BUTTON_SIZE: Vector2 = Vector2(496, 52)

var title_label: Label
var hint_label: Label
var slot_one_button: Button
var slot_two_button: Button
var slot_three_button: Button
var close_button: Button

var _mode: String = MODE_LOAD

func _ready() -> void :
    _ensure_ui()
    _apply_visual_style()
    _bind_buttons()
    setup(MODE_LOAD)

func setup(mode: String) -> void :
    _mode = mode
    if _mode == MODE_SAVE:
        title_label.text = _tx("ui.save_slot.title_save", "Save Slot")
        hint_label.text = _tx("ui.save_slot.hint_save", "Select a slot to overwrite")
    else:
        title_label.text = _tx("ui.save_slot.title_load", "Load Slot")
        hint_label.text = _tx("ui.save_slot.hint_load", "Select a slot to continue")
    refresh_slots()

func get_mode() -> String:
    return _mode

func show_hint(message: String) -> void :
    hint_label.text = message

func refresh_slots() -> void :
    var slots: Array[Dictionary] = SaveSystem.list_save_slots()
    var buttons: Array[Button] = [slot_one_button, slot_two_button, slot_three_button]
    for i: int in range(buttons.size()):
        var button: Button = buttons[i]
        var slot: Dictionary = {}
        if i < slots.size():
            slot = slots[i]
        var idx: int = i + 1
        var has_data: bool = bool(slot.get("has_data", false))
        if has_data:
            var stage_id: String = str(slot.get("stage_id", "stage_001"))
            var saved_at: String = str(slot.get("saved_at", ""))
            var character: String = _format_character_name(str(slot.get("selected_character", "the_fool")))
            var difficulty: String = _format_difficulty(str(slot.get("difficulty", "danger_1")))
            var header: String = _tf("ui.save_slot.slot_filled", [idx, stage_id], "Slot %d  %s")
            var detail_parts: PackedStringArray = [character, difficulty]
            if not saved_at.is_empty():
                detail_parts.append(saved_at)
            button.text = "%s\n%s" % [header, " / ".join(detail_parts)]
        else:
            button.text = _tf("ui.save_slot.slot_empty", [idx], "Slot %d  <Empty>")
        button.disabled = (_mode == MODE_LOAD and not has_data)

func _on_slot_button_pressed(slot_id: String) -> void :
    slot_selected.emit(slot_id)

func _on_close_button_pressed() -> void :
    panel_closed.emit()

func _bind_buttons() -> void :
    slot_one_button.pressed.connect(_on_slot_button_pressed.bind(SLOT_IDS[0]))
    slot_two_button.pressed.connect(_on_slot_button_pressed.bind(SLOT_IDS[1]))
    slot_three_button.pressed.connect(_on_slot_button_pressed.bind(SLOT_IDS[2]))
    close_button.pressed.connect(_on_close_button_pressed)

func _ensure_ui() -> void :
    title_label = get_node_or_null("Margin/VBox/TitleLabel") as Label
    hint_label = get_node_or_null("Margin/VBox/HintLabel") as Label
    slot_one_button = get_node_or_null("Margin/VBox/SlotOneButton") as Button
    slot_two_button = get_node_or_null("Margin/VBox/SlotTwoButton") as Button
    slot_three_button = get_node_or_null("Margin/VBox/SlotThreeButton") as Button
    close_button = get_node_or_null("Margin/VBox/CloseButton") as Button

    if title_label != null and hint_label != null and slot_one_button != null and slot_two_button != null and slot_three_button != null and close_button != null:
        return

    for child: Node in get_children():
        child.queue_free()

    custom_minimum_size = PANEL_SIZE
    anchors_preset = Control.PRESET_CENTER
    anchor_left = 0.5
    anchor_top = 0.5
    anchor_right = 0.5
    anchor_bottom = 0.5
    offset_left = -PANEL_SIZE.x * 0.5
    offset_top = -PANEL_SIZE.y * 0.5
    offset_right = PANEL_SIZE.x * 0.5
    offset_bottom = PANEL_SIZE.y * 0.5
    grow_horizontal = Control.GROW_DIRECTION_BOTH
    grow_vertical = Control.GROW_DIRECTION_BOTH

    var margin: MarginContainer = MarginContainer.new()
    margin.name = "Margin"
    margin.add_theme_constant_override("margin_left", 26)
    margin.add_theme_constant_override("margin_top", 24)
    margin.add_theme_constant_override("margin_right", 26)
    margin.add_theme_constant_override("margin_bottom", 24)
    add_child(margin)

    var vbox: VBoxContainer = VBoxContainer.new()
    vbox.name = "VBox"
    vbox.add_theme_constant_override("separation", 12)
    margin.add_child(vbox)

    title_label = Label.new()
    title_label.name = "TitleLabel"
    title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title_label.add_theme_font_size_override("font_size", 30)
    vbox.add_child(title_label)

    hint_label = Label.new()
    hint_label.name = "HintLabel"
    hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hint_label.add_theme_font_size_override("font_size", 16)
    vbox.add_child(hint_label)

    slot_one_button = _create_slot_button("SlotOneButton")
    vbox.add_child(slot_one_button)
    slot_two_button = _create_slot_button("SlotTwoButton")
    vbox.add_child(slot_two_button)
    slot_three_button = _create_slot_button("SlotThreeButton")
    vbox.add_child(slot_three_button)

    close_button = Button.new()
    close_button.name = "CloseButton"
    close_button.custom_minimum_size = CLOSE_BUTTON_SIZE
    close_button.add_theme_font_size_override("font_size", 20)
    close_button.text = _tx("ui.common.back", "Back")
    vbox.add_child(close_button)

func _create_slot_button(node_name: String) -> Button:
    var button: Button = Button.new()
    button.name = node_name
    button.custom_minimum_size = SLOT_BUTTON_SIZE
    button.add_theme_font_size_override("font_size", 20)
    return button

func _apply_visual_style() -> void:
    custom_minimum_size = PANEL_SIZE
    offset_left = -PANEL_SIZE.x * 0.5
    offset_top = -PANEL_SIZE.y * 0.5
    offset_right = PANEL_SIZE.x * 0.5
    offset_bottom = PANEL_SIZE.y * 0.5

    var panel_style: StyleBoxFlat = StyleBoxFlat.new()
    panel_style.bg_color = Color(0.025, 0.038, 0.036, 0.88)
    panel_style.border_color = Color(0.33, 0.95, 0.65, 0.82)
    panel_style.border_width_left = 2
    panel_style.border_width_top = 2
    panel_style.border_width_right = 2
    panel_style.border_width_bottom = 2
    panel_style.corner_radius_top_left = 4
    panel_style.corner_radius_top_right = 4
    panel_style.corner_radius_bottom_left = 4
    panel_style.corner_radius_bottom_right = 4
    panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.55)
    panel_style.shadow_size = 18
    panel_style.shadow_offset = Vector2(0, 8)
    add_theme_stylebox_override("panel", panel_style)

    var margin: MarginContainer = get_node_or_null("Margin") as MarginContainer
    if margin != null:
        margin.add_theme_constant_override("margin_left", 26)
        margin.add_theme_constant_override("margin_top", 24)
        margin.add_theme_constant_override("margin_right", 26)
        margin.add_theme_constant_override("margin_bottom", 24)

    var vbox: VBoxContainer = get_node_or_null("Margin/VBox") as VBoxContainer
    if vbox != null:
        vbox.add_theme_constant_override("separation", 12)

    if title_label != null:
        title_label.add_theme_color_override("font_color", Color(0.92, 0.98, 0.95, 1.0))
        title_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
        title_label.add_theme_constant_override("shadow_offset_x", 3)
        title_label.add_theme_constant_override("shadow_offset_y", 3)
        title_label.add_theme_font_size_override("font_size", 30)

    if hint_label != null:
        hint_label.add_theme_color_override("font_color", Color(0.72, 0.95, 0.82, 0.82))
        hint_label.add_theme_font_size_override("font_size", 16)

    var slot_buttons: Array[Button] = [slot_one_button, slot_two_button, slot_three_button]
    for button: Button in slot_buttons:
        _style_slot_button(button, SLOT_BUTTON_SIZE, 20)
    _style_slot_button(close_button, CLOSE_BUTTON_SIZE, 20)

func _style_slot_button(button: Button, min_size: Vector2, font_size: int) -> void:
    if button == null:
        return
    button.custom_minimum_size = min_size
    button.flat = false
    button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    button.alignment = HORIZONTAL_ALIGNMENT_CENTER
    button.add_theme_font_size_override("font_size", font_size)
    button.add_theme_color_override("font_color", Color(0.86, 1.0, 0.92, 0.96))
    button.add_theme_color_override("font_hover_color", Color(0.96, 1.0, 0.98, 1.0))
    button.add_theme_color_override("font_pressed_color", Color(0.62, 1.0, 0.8, 1.0))
    button.add_theme_color_override("font_disabled_color", Color(0.43, 0.52, 0.48, 0.58))
    button.add_theme_stylebox_override("normal", _make_button_style(Color(0.02, 0.04, 0.035, 0.58), Color(0.33, 0.95, 0.65, 0.68)))
    button.add_theme_stylebox_override("hover", _make_button_style(Color(0.06, 0.14, 0.10, 0.72), Color(0.45, 1.0, 0.72, 0.94)))
    button.add_theme_stylebox_override("pressed", _make_button_style(Color(0.08, 0.19, 0.13, 0.82), Color(0.62, 1.0, 0.8, 1.0)))
    button.add_theme_stylebox_override("focus", _make_button_style(Color(0.05, 0.12, 0.09, 0.68), Color(0.45, 1.0, 0.72, 0.92)))
    button.add_theme_stylebox_override("disabled", _make_button_style(Color(0.02, 0.03, 0.028, 0.38), Color(0.25, 0.36, 0.31, 0.38)))

func _make_button_style(bg_color: Color, border_color: Color) -> StyleBoxFlat:
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = bg_color
    style.border_color = border_color
    style.border_width_left = 1
    style.border_width_top = 1
    style.border_width_right = 1
    style.border_width_bottom = 1
    style.corner_radius_top_left = 3
    style.corner_radius_top_right = 3
    style.corner_radius_bottom_left = 3
    style.corner_radius_bottom_right = 3
    style.content_margin_left = 18
    style.content_margin_right = 18
    style.content_margin_top = 8
    style.content_margin_bottom = 8
    return style

func _format_character_name(character_id: String) -> String:
    match character_id:
        "the_fool":
            return _tx("ui.character.the_fool", "The Fool")
        "the_sun":
            return _tx("ui.character.the_sun", "The Sun")
        "the_chariot":
            return _tx("ui.character.the_chariot", "The Chariot")
        _:
            return character_id

func _format_difficulty(difficulty_id: String) -> String:
    if difficulty_id.begins_with("danger_"):
        var raw_level: String = difficulty_id.substr(7)
        if raw_level.is_valid_int():
            return _tf("ui.difficulty_select.danger_name_fmt", [int(raw_level)], "Danger %d")
    return difficulty_id

func _tx(key: String, fallback: String = "") -> String:
    if LocaleService != null:
        return LocaleService.tx(key, fallback if not fallback.is_empty() else key)
    if fallback.is_empty():
        return key
    return fallback

func _tf(key: String, args: Array, fallback: String = "") -> String:
    if LocaleService != null:
        return LocaleService.tf(key, args, fallback if not fallback.is_empty() else key)
    var base: String = fallback if not fallback.is_empty() else key
    return base % args
