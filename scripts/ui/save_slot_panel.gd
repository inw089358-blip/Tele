class_name SaveSlotPanel
extends PanelContainer

signal slot_selected(slot_id: String)
signal panel_closed

const MODE_LOAD: String = "load"
const MODE_SAVE: String = "save"
const SLOT_IDS: PackedStringArray = ["slot_1", "slot_2", "slot_3"]

var title_label: Label
var hint_label: Label
var slot_one_button: Button
var slot_two_button: Button
var slot_three_button: Button
var close_button: Button

var _mode: String = MODE_LOAD

func _ready() -> void :
    _ensure_ui()
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
            var wave: int = int(slot.get("wave", 1))
            var saved_at: String = str(slot.get("saved_at", ""))
            button.text = _tf("ui.save_slot.slot_filled", [idx, stage_id, wave], "Slot %d  %s  WAVE %d")
            if not saved_at.is_empty():
                button.text += "\n%s" % saved_at
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

    custom_minimum_size = Vector2(440, 380)
    anchors_preset = Control.PRESET_CENTER
    anchor_left = 0.5
    anchor_top = 0.5
    anchor_right = 0.5
    anchor_bottom = 0.5
    offset_left = -220.0
    offset_top = -190.0
    offset_right = 220.0
    offset_bottom = 190.0
    grow_horizontal = Control.GROW_DIRECTION_BOTH
    grow_vertical = Control.GROW_DIRECTION_BOTH

    var margin: MarginContainer = MarginContainer.new()
    margin.name = "Margin"
    margin.add_theme_constant_override("margin_left", 12)
    margin.add_theme_constant_override("margin_top", 12)
    margin.add_theme_constant_override("margin_right", 12)
    margin.add_theme_constant_override("margin_bottom", 12)
    add_child(margin)

    var vbox: VBoxContainer = VBoxContainer.new()
    vbox.name = "VBox"
    vbox.add_theme_constant_override("separation", 8)
    margin.add_child(vbox)

    title_label = Label.new()
    title_label.name = "TitleLabel"
    title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title_label.add_theme_font_size_override("font_size", 24)
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
    close_button.custom_minimum_size = Vector2(376, 44)
    close_button.add_theme_font_size_override("font_size", 20)
    close_button.text = _tx("ui.common.back", "Back")
    vbox.add_child(close_button)

func _create_slot_button(node_name: String) -> Button:
    var button: Button = Button.new()
    button.name = node_name
    button.custom_minimum_size = Vector2(376, 64)
    button.add_theme_font_size_override("font_size", 20)
    return button

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
