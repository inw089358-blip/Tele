extends Control

const CHARACTER_IDS: PackedStringArray = [
    "the_fool",
    "the_chariot",
    "the_sun",
]

const CHARACTER_COLORS: Array[Color] = [
    Color(0.756863, 0.690196, 0.545098, 1),
    Color(0.666667, 0.4, 0.356863, 1),
    Color(0.54902, 0.647059, 0.780392, 1),
]

const CHARACTER_PORTRAITS: Dictionary[String, String] = {
    "the_fool": "res://sprite/characters/the_fool/portrait.png",
    "the_chariot": "res://sprite/characters/the_chariot/portrait.png",
    "the_sun": "res://sprite/characters/the_sun/portrait.png",
}

const CHARACTER_PASSIVES: Dictionary = {
    "the_fool": {
        "name_key": "data.character.the_fool.passive.name",
        "desc_key": "data.character.the_fool.passive.desc",
        "name_fallback": "Fate Bend",
        "desc_fallback": "When taking damage, has a chance to fully evade it. Higher Luck increases the chance.",
    },
    "the_chariot": {
        "name_key": "data.character.the_chariot.passive.name",
        "desc_key": "data.character.the_chariot.passive.desc",
        "name_fallback": "Iron Wheel",
        "desc_fallback": "After moving continuously, gains Move Speed and Armor. The bonus fades after stopping.",
    },
    "the_sun": {
        "name_key": "data.character.the_sun.passive.name",
        "desc_key": "data.character.the_sun.passive.desc",
        "name_fallback": "Corona Afterglow",
        "desc_fallback": "After several kills, heals 1 HP. At full HP, gains a brief Attack Speed bonus instead.",
    },
}

const BG_COLOR: Color = Color("#050a10")
const PANEL_COLOR: Color = Color(0.06, 0.09, 0.14, 0.96)
const PANEL_COLOR_SOFT: Color = Color(0.08, 0.12, 0.18, 0.88)
const LINE_COLOR: Color = Color(0.0, 0.94, 1.0, 0.35)
const TEXT_COLOR: Color = Color(0.94, 0.95, 0.98, 1.0)
const MUTED_TEXT_COLOR: Color = Color(0.6, 0.75, 0.8, 1.0)
const ACCENT_COLOR: Color = Color("#00f0ff")
const CHARACTER_STAGE_SIZE: Vector2 = Vector2(560, 420)
const PORTRAIT_SIZE: Vector2 = Vector2(250, 290)

const STAT_LABELS: Dictionary[String, String] = {
    "max_hp": "ui.stat.hp",
    "move_speed": "ui.stat.move",
    "armor": "ui.stat.armor",
    "attack_speed_mult": "ui.stat.attack_speed",
    "crit_chance": "ui.stat.crit",
    "luck": "ui.stat.luck",
}

const STAT_NORMALIZERS: Dictionary[String, float] = {
    "max_hp": 12.0,
    "move_speed": 260.0,
    "armor": 4.0,
    "attack_speed_mult": 1.25,
    "crit_chance": 0.12,
    "luck": 12.0,
}

@onready var background: ColorRect = $Background
@onready var header_label: Label = $HeaderLabel
@onready var character_center: CenterContainer = $CharacterCenter
@onready var character_stage: Control = $CharacterCenter/CharacterStage
@onready var left_arrow_button: Button = %LeftArrowButton
@onready var right_arrow_button: Button = %RightArrowButton
@onready var select_button: Button = %SelectButton
@onready var back_button: Button = %BackButton
@onready var character_name_label: Label = %CharacterNameLabel
@onready var character_hint_label: Label = %CharacterHintLabel
@onready var character_silhouette: TextureRect = %CharacterSilhouette
@onready var crt_overlay: ColorRect = $CRTOverlay

var _current_index: int = 0
var _scene_input_ready: bool = false
var _queued_action: Callable = Callable()
var _queued_action_id: String = ""
var _portrait_cache: Dictionary[String, Texture2D] = {}
var _placeholder_cache: Dictionary[int, Texture2D] = {}
var _stat_bars: Dictionary = {}
var _stat_value_labels: Dictionary = {}
var _character_chips: Array[Button] = []
var _portrait_tween: Tween
var _passive_title_label: Label
var _passive_name_label: Label
var _passive_desc_label: Label

func _ready() -> void :
    _build_layout()
    _style_static_controls()
    left_arrow_button.pressed.connect(_on_left_arrow_pressed)
    right_arrow_button.pressed.connect(_on_right_arrow_pressed)
    select_button.pressed.connect(_on_select_button_pressed)
    back_button.pressed.connect(_on_back_button_pressed)
    _refresh_character_view()
    _add_vignette_background()
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
    character_silhouette.texture = _get_character_portrait(character_id, _current_index)
    _refresh_character_stats(character_id)
    _refresh_character_passive(character_id)
    _refresh_character_chips()
    _play_character_swap_feedback()

func _do_left() -> void:
    var character_count: int = CHARACTER_IDS.size()
    _current_index = (_current_index - 1 + character_count) % character_count
    _refresh_character_view()

func _do_right() -> void:
    var character_count: int = CHARACTER_IDS.size()
    _current_index = (_current_index + 1) % character_count
    _refresh_character_view()

func _do_select_chip(index: int) -> void:
    if index < 0 or index >= CHARACTER_IDS.size():
        return
    if _current_index == index:
        return
    _current_index = index
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

func _build_layout() -> void:
    background.color = BG_COLOR

    var root: MarginContainer = MarginContainer.new()
    root.name = "ResponsiveRoot"
    root.set_anchors_preset(Control.PRESET_FULL_RECT)
    root.add_theme_constant_override("margin_left", 36)
    root.add_theme_constant_override("margin_top", 16)
    root.add_theme_constant_override("margin_right", 36)
    root.add_theme_constant_override("margin_bottom", 16)
    add_child(root)
    move_child(root, crt_overlay.get_index())

    var main_vbox: VBoxContainer = VBoxContainer.new()
    main_vbox.add_theme_constant_override("separation", 12)
    root.add_child(main_vbox)

    var header_row: HBoxContainer = HBoxContainer.new()
    header_row.add_theme_constant_override("separation", 20)
    main_vbox.add_child(header_row)

    _reparent_control(header_label, header_row)
    header_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header_label.text = _tx("ui.character_select.title", "Choose Character")
    header_label.add_theme_font_size_override("font_size", 38)
    header_label.add_theme_color_override("font_color", ACCENT_COLOR)

    var body_row: HBoxContainer = HBoxContainer.new()
    body_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
    body_row.add_theme_constant_override("separation", 24)
    main_vbox.add_child(body_row)

    var portrait_panel: PanelContainer = PanelContainer.new()
    portrait_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    portrait_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    portrait_panel.add_theme_stylebox_override("panel", _make_panel_style(PANEL_COLOR, LINE_COLOR, 8, 2))
    body_row.add_child(portrait_panel)

    var portrait_margin: MarginContainer = MarginContainer.new()
    portrait_margin.add_theme_constant_override("margin_left", 12)
    portrait_margin.add_theme_constant_override("margin_top", 12)
    portrait_margin.add_theme_constant_override("margin_right", 12)
    portrait_margin.add_theme_constant_override("margin_bottom", 12)
    portrait_panel.add_child(portrait_margin)

    _reparent_control(character_stage, portrait_margin)
    character_stage.custom_minimum_size = CHARACTER_STAGE_SIZE
    character_stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    character_stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
    character_center.visible = false

    var info_panel: PanelContainer = PanelContainer.new()
    info_panel.custom_minimum_size = Vector2(330, 0)
    info_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    info_panel.add_theme_stylebox_override("panel", _make_panel_style(PANEL_COLOR_SOFT, Color(0.42, 0.73, 0.72, 0.42), 8, 1))
    body_row.add_child(info_panel)

    var info_margin: MarginContainer = MarginContainer.new()
    info_margin.add_theme_constant_override("margin_left", 22)
    info_margin.add_theme_constant_override("margin_top", 22)
    info_margin.add_theme_constant_override("margin_right", 22)
    info_margin.add_theme_constant_override("margin_bottom", 22)
    info_panel.add_child(info_margin)

    var info_vbox: VBoxContainer = VBoxContainer.new()
    info_vbox.add_theme_constant_override("separation", 16)
    info_margin.add_child(info_vbox)

    var info_title: Label = Label.new()
    info_title.text = _tx("ui.character_select.profile_title", "Combat Profile")
    info_title.add_theme_color_override("font_color", ACCENT_COLOR)
    info_title.add_theme_font_size_override("font_size", 24)
    info_vbox.add_child(info_title)

    var stat_grid: GridContainer = GridContainer.new()
    stat_grid.columns = 1
    stat_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
    stat_grid.add_theme_constant_override("v_separation", 12)
    info_vbox.add_child(stat_grid)
    for stat_key: String in STAT_LABELS.keys():
        _add_stat_row(stat_grid, stat_key)

    var passive_panel: PanelContainer = PanelContainer.new()
    passive_panel.custom_minimum_size = Vector2(0, 118)
    passive_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    passive_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.055, 0.10, 0.13, 0.94), Color(0.42, 0.73, 0.72, 0.34), 8, 1))
    info_vbox.add_child(passive_panel)

    var passive_margin: MarginContainer = MarginContainer.new()
    passive_margin.add_theme_constant_override("margin_left", 12)
    passive_margin.add_theme_constant_override("margin_top", 10)
    passive_margin.add_theme_constant_override("margin_right", 12)
    passive_margin.add_theme_constant_override("margin_bottom", 10)
    passive_panel.add_child(passive_margin)

    var passive_vbox: VBoxContainer = VBoxContainer.new()
    passive_vbox.add_theme_constant_override("separation", 4)
    passive_margin.add_child(passive_vbox)

    _passive_title_label = Label.new()
    _passive_title_label.text = _tx("ui.character_select.passive_title", "Passive")
    _passive_title_label.add_theme_color_override("font_color", ACCENT_COLOR)
    _passive_title_label.add_theme_font_size_override("font_size", 16)
    passive_vbox.add_child(_passive_title_label)

    _passive_name_label = Label.new()
    _passive_name_label.add_theme_color_override("font_color", TEXT_COLOR)
    _passive_name_label.add_theme_font_size_override("font_size", 20)
    _passive_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    passive_vbox.add_child(_passive_name_label)

    _passive_desc_label = Label.new()
    _passive_desc_label.add_theme_color_override("font_color", MUTED_TEXT_COLOR)
    _passive_desc_label.add_theme_font_size_override("font_size", 15)
    _passive_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _passive_desc_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
    passive_vbox.add_child(_passive_desc_label)

    var chip_row: HBoxContainer = HBoxContainer.new()
    chip_row.add_theme_constant_override("separation", 8)
    info_vbox.add_child(chip_row)
    _build_character_chips(chip_row)

    var footer_row: HBoxContainer = HBoxContainer.new()
    footer_row.add_theme_constant_override("separation", 20)
    main_vbox.add_child(footer_row)
    
    _reparent_control(back_button, footer_row)
    back_button.custom_minimum_size = Vector2(180, 50)
    
    var footer_spacer: Control = Control.new()
    footer_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    footer_row.add_child(footer_spacer)
    
    _reparent_control(select_button, footer_row)
    select_button.custom_minimum_size = Vector2(300, 50)

    _apply_stage_layout()

func _style_static_controls() -> void:
    select_button.text = _tx("ui.character_select.confirm", "Confirm")
    back_button.text = _tx("ui.common.back", "Back")
    left_arrow_button.text = "<"
    right_arrow_button.text = ">"

    for button: Button in [left_arrow_button, right_arrow_button]:
        button.custom_minimum_size = Vector2(76, 76)
        button.add_theme_font_size_override("font_size", 38)
        button.add_theme_stylebox_override("normal", _make_button_style(Color(0.08, 0.12, 0.18, 0.92), LINE_COLOR))
        button.add_theme_stylebox_override("hover", _make_button_style(Color(0.12, 0.2, 0.3, 0.96), ACCENT_COLOR))
        button.add_theme_stylebox_override("pressed", _make_button_style(Color(0.15, 0.25, 0.4, 1.0), ACCENT_COLOR))

    for button: Button in [select_button, back_button]:
        button.add_theme_font_size_override("font_size", 24)
        button.add_theme_stylebox_override("normal", _make_button_style(Color(0.1, 0.16, 0.24, 0.95), LINE_COLOR))
        button.add_theme_stylebox_override("hover", _make_button_style(Color(0.15, 0.25, 0.35, 0.98), ACCENT_COLOR))
        button.add_theme_stylebox_override("pressed", _make_button_style(Color(0.2, 0.3, 0.45, 1.0), ACCENT_COLOR))
        button.add_theme_color_override("font_color", TEXT_COLOR)

    character_name_label.add_theme_color_override("font_color", TEXT_COLOR)
    character_name_label.add_theme_font_size_override("font_size", 44)
    character_hint_label.add_theme_color_override("font_color", MUTED_TEXT_COLOR)
    character_hint_label.add_theme_font_size_override("font_size", 22)
    character_silhouette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    character_silhouette.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

func _apply_stage_layout() -> void:
    left_arrow_button.position = Vector2(24, 172)
    left_arrow_button.size = Vector2(76, 76)
    right_arrow_button.position = Vector2(460, 172)
    right_arrow_button.size = Vector2(76, 76)
    character_name_label.position = Vector2(104, 12)
    character_name_label.size = Vector2(352, 58)
    character_silhouette.position = Vector2(155, 68)
    character_silhouette.size = PORTRAIT_SIZE
    character_hint_label.position = Vector2(86, 370)
    character_hint_label.size = Vector2(388, 42)


func _add_stat_row(parent: GridContainer, stat_key: String) -> void:
    var row: VBoxContainer = VBoxContainer.new()
    row.add_theme_constant_override("separation", 4)
    parent.add_child(row)

    var label_row: HBoxContainer = HBoxContainer.new()
    row.add_child(label_row)

    var name_label: Label = Label.new()
    name_label.text = _stat_label(stat_key)
    name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    name_label.add_theme_color_override("font_color", MUTED_TEXT_COLOR)
    name_label.add_theme_font_size_override("font_size", 15)
    label_row.add_child(name_label)

    var value_label: Label = Label.new()
    value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    value_label.add_theme_color_override("font_color", TEXT_COLOR)
    value_label.add_theme_font_size_override("font_size", 16)
    label_row.add_child(value_label)
    _stat_value_labels[stat_key] = value_label

    var bar: ProgressBar = ProgressBar.new()
    bar.custom_minimum_size = Vector2(0, 10)
    bar.max_value = 1.0
    bar.show_percentage = false
    bar.add_theme_stylebox_override("background", _make_bar_style(Color(0.045, 0.09, 0.10, 0.92), 5))
    bar.add_theme_stylebox_override("fill", _make_bar_style(ACCENT_COLOR, 5))
    row.add_child(bar)
    _stat_bars[stat_key] = bar

func _build_character_chips(parent: HBoxContainer) -> void:
    _character_chips.clear()
    for i: int in range(CHARACTER_IDS.size()):
        var chip: Button = Button.new()
        chip.text = str(i + 1)
        chip.custom_minimum_size = Vector2(42, 34)
        chip.focus_mode = Control.FOCUS_NONE
        chip.pressed.connect(_on_character_chip_pressed.bind(i))
        parent.add_child(chip)
        _character_chips.append(chip)

func _on_character_chip_pressed(index: int) -> void:
    _invoke_or_queue("char_chip_%d" % index, Callable(self, "_do_select_chip").bind(index))

func _refresh_character_chips() -> void:
    for i: int in range(_character_chips.size()):
        var chip: Button = _character_chips[i]
        var selected: bool = i == _current_index
        var fill: Color = ACCENT_COLOR if selected else Color(0.08, 0.16, 0.17, 0.92)
        var border: Color = ACCENT_COLOR if selected else Color(0.42, 0.73, 0.72, 0.35)
        chip.add_theme_stylebox_override("normal", _make_button_style(fill, border, 6, 1))
        chip.add_theme_stylebox_override("hover", _make_button_style(Color(0.20, 0.31, 0.29, 1.0), ACCENT_COLOR, 6, 1))
        chip.add_theme_color_override("font_color", Color(0.09, 0.12, 0.11, 1.0) if selected else TEXT_COLOR)

func _refresh_character_stats(character_id: String) -> void:
    var profile: Dictionary = BalanceService.get_character_profile(character_id)
    for stat_key: String in STAT_LABELS.keys():
        var raw_value: float = float(profile.get(stat_key, 0.0))
        var normalizer: float = max(0.001, float(STAT_NORMALIZERS.get(stat_key, 1.0)))
        var normalized: float = clampf(raw_value / normalizer, 0.0, 1.0)
        if stat_key == "armor":
            normalized = clampf((raw_value + 1.0) / normalizer, 0.0, 1.0)
        var bar: ProgressBar = _stat_bars.get(stat_key, null)
        if bar != null:
            bar.value = normalized
        var value_label: Label = _stat_value_labels.get(stat_key, null)
        if value_label != null:
            value_label.text = _format_stat_value(stat_key, raw_value)

func _refresh_character_passive(character_id: String) -> void:
    if _passive_title_label == null or _passive_name_label == null or _passive_desc_label == null:
        return
    _passive_title_label.text = _tx("ui.character_select.passive_title", "Passive")
    var passive_value: Variant = CHARACTER_PASSIVES.get(character_id, {})
    if not (passive_value is Dictionary):
        _passive_name_label.text = _tx("ui.character_select.passive_title", "Passive")
        _passive_desc_label.text = "No passive configured"
        return
    var passive: Dictionary = passive_value
    _passive_name_label.text = _tx(
        str(passive.get("name_key", "")),
        str(passive.get("name_fallback", "Passive"))
    )
    _passive_desc_label.text = _tx(
        str(passive.get("desc_key", "")),
        str(passive.get("desc_fallback", "No passive configured"))
    )

func _format_stat_value(stat_key: String, value: float) -> String:
    match stat_key:
        "move_speed":
            return "%d" % int(round(value))
        "attack_speed_mult":
            return "%.0f%%" % (value * 100.0)
        "crit_chance":
            return "%.0f%%" % (value * 100.0)
        "luck":
            return "%d" % int(round(value))
        _:
            return "%.1f" % value if absf(value - round(value)) > 0.01 else "%d" % int(round(value))

func _stat_label(stat_key: String) -> String:
    var label_key: String = str(STAT_LABELS.get(stat_key, stat_key))
    var fallback: String = stat_key
    match stat_key:
        "max_hp":
            fallback = "HP"
        "move_speed":
            fallback = "Move"
        "armor":
            fallback = "Armor"
        "attack_speed_mult":
            fallback = "Attack Speed"
        "crit_chance":
            fallback = "Crit"
        "luck":
            fallback = "Luck"
    return _tx(label_key, fallback)

func _play_character_swap_feedback() -> void:
    if _portrait_tween != null:
        _portrait_tween.kill()
    character_silhouette.modulate = Color(1, 1, 1, 0.6)
    character_silhouette.scale = Vector2(0.97, 0.97)
    _portrait_tween = create_tween()
    _portrait_tween.set_parallel(true)
    _portrait_tween.tween_property(character_silhouette, "modulate", Color.WHITE, 0.14)
    _portrait_tween.tween_property(character_silhouette, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _reparent_control(control: Control, new_parent: Node) -> void:
    var old_parent: Node = control.get_parent()
    if old_parent != null:
        old_parent.remove_child(control)
    new_parent.add_child(control)

func _add_vignette_background() -> void:
    var vignette: TextureRect = TextureRect.new()
    vignette.name = "VignetteOverlay"
    vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var grad: Gradient = Gradient.new()
    grad.set_color(0, Color(0, 0, 0, 0))
    grad.set_color(1, Color(0, 0, 0, 0.5))
    var fill: GradientTexture2D = GradientTexture2D.new()
    fill.gradient = grad
    fill.fill = GradientTexture2D.FILL_RADIAL
    fill.fill_from = Vector2(0.5, 0.5)
    fill.fill_to = Vector2(1.0, 1.0)
    vignette.texture = fill
    add_child(vignette)
    move_child(vignette, background.get_index() + 1)

func _make_panel_style(fill: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = fill
    style.border_color = border
    style.border_width_left = border_width
    style.border_width_top = border_width
    style.border_width_right = border_width
    style.border_width_bottom = border_width
    style.corner_radius_top_left = radius
    style.corner_radius_top_right = radius
    style.corner_radius_bottom_left = radius
    style.corner_radius_bottom_right = radius
    # 加入阴影效果
    style.shadow_color = border
    style.shadow_color.a = 0.2
    style.shadow_size = 8
    return style

func _make_button_style(fill: Color, border: Color, radius: int = 8, border_width: int = 1) -> StyleBoxFlat:
    var style: StyleBoxFlat = _make_panel_style(fill, border, radius, border_width)
    style.content_margin_left = 14
    style.content_margin_right = 14
    style.content_margin_top = 8
    style.content_margin_bottom = 8
    return style

func _make_bar_style(fill: Color, radius: int) -> StyleBoxFlat:
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = fill
    style.corner_radius_top_left = radius
    style.corner_radius_top_right = radius
    style.corner_radius_bottom_left = radius
    style.corner_radius_bottom_right = radius
    return style

func _tx(key: String, fallback: String = "") -> String:
    if LocaleService != null:
        return LocaleService.tx(key, fallback if not fallback.is_empty() else key)
    if fallback.is_empty():
        return key
    return fallback

func _get_character_portrait(character_id: String, color_index: int) -> Texture2D:
    if _portrait_cache.has(character_id):
        return _portrait_cache[character_id] as Texture2D

    var portrait_path: String = str(CHARACTER_PORTRAITS.get(character_id, ""))
    if not portrait_path.is_empty() and ResourceLoader.exists(portrait_path):
        var portrait: Texture2D = load(portrait_path) as Texture2D
        if portrait != null:
            _portrait_cache[character_id] = portrait
            return portrait

    var placeholder: Texture2D = _get_placeholder_texture(color_index)
    _portrait_cache[character_id] = placeholder
    return placeholder

func _get_placeholder_texture(color_index: int) -> Texture2D:
    var safe_index: int = clampi(color_index, 0, CHARACTER_COLORS.size() - 1)
    if _placeholder_cache.has(safe_index):
        return _placeholder_cache[safe_index] as Texture2D

    var image: Image = Image.create(260, 302, false, Image.FORMAT_RGBA8)
    image.fill(CHARACTER_COLORS[safe_index])
    var texture: ImageTexture = ImageTexture.create_from_image(image)
    _placeholder_cache[safe_index] = texture
    return texture
