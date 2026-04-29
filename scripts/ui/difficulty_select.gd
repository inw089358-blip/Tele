extends Control

const BG_COLOR: Color = Color("#050a10")
const PANEL_COLOR: Color = Color(0.06, 0.09, 0.14, 0.94)
const CARD_COLOR: Color = Color(0.1, 0.16, 0.24, 0.90)
const CARD_HOVER_COLOR: Color = Color(0.15, 0.25, 0.35, 0.96)
const TEXT_COLOR: Color = Color(0.94, 0.95, 0.98, 1.0)
const MUTED_TEXT_COLOR: Color = Color(0.6, 0.75, 0.8, 1.0)
const ACCENT_COLOR: Color = Color("#00f0ff")
const SOFT_LINE_COLOR: Color = Color(0.0, 0.94, 1.0, 0.3)

const DANGER_LEVELS: int = 10

const DIFFICULTY_CONFIGS: Dictionary = {
    0: {"name": "Danger 0", "desc": "Baseline experience.", "mods": ["Standard Enemies"]},
    1: {"name": "Danger 1", "desc": "The woods grow thicker.", "mods": ["+10% Enemy Count"]},
    2: {"name": "Danger 2", "desc": "Elite presence detected.", "mods": ["Elites spawn at Wave 10"]},
    3: {"name": "Danger 3", "desc": "Harsher environment.", "mods": ["Enemy Damage +10%"]},
    4: {"name": "Danger 4", "desc": "Faster prey.", "mods": ["Enemy Speed +10%"]},
    5: {"name": "Danger 5", "desc": "Bosses are relentless.", "mods": ["Boss HP +20%"]},
    6: {"name": "Danger 6", "desc": "Inflation hits.", "mods": ["Shop Prices +5%"]},
    7: {"name": "Danger 7", "desc": "Harder hits.", "mods": ["Enemy Damage +20%"]},
    8: {"name": "Danger 8", "desc": "Swarm intelligence.", "mods": ["Enemy Count +20%"]},
    9: {"name": "Danger 9", "desc": "The ultimate test.", "mods": ["All Stats Up for Enemies"]},
}

@onready var background: ColorRect = $Background
@onready var crt_overlay: ColorRect = $CRTOverlay

var title_label: Label
var char_panel: PanelContainer
var weapon_panel: PanelContainer
var diff_panel: PanelContainer
var start_button: Button
var back_button: Button
var diff_buttons: Array[Button] = []

var _selected_danger: int = 0

var _scene_input_ready: bool = false
var _queued_action: Callable = Callable()
var _queued_action_id: String = ""

func _ready() -> void :
    _build_layout()
    _add_vignette_background()
    _refresh_ui()
    _arm_scene_ready_gate()

func _unhandled_input(event: InputEvent) -> void :
    if event.is_action_pressed("cancel"):
        _on_back_pressed()

func _on_back_pressed() -> void :
    _invoke_or_queue("difficulty_back", Callable(self, "_do_back"))

func _on_start_pressed() -> void :
    _invoke_or_queue("difficulty_start", Callable(self, "_do_start"))

func _on_danger_selected(level: int) -> void :
    _selected_danger = level
    _refresh_ui()

func _do_start() -> void:
    # 映射到 GameManager 所需的难度 ID
    var diff_id: String = "normal"
    if _selected_danger == 0: diff_id = "easy"
    elif _selected_danger >= 2: diff_id = "hard"
    
    # 将 Danger Level 写入 GameManager
    GameManager.set_meta("danger_level", _selected_danger)
    GameManager.start_new_run_with_difficulty(diff_id)

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

func _build_layout() -> void:
    background.color = BG_COLOR
    if has_node("VBox"): get_node("VBox").visible = false

    var root: MarginContainer = MarginContainer.new()
    root.name = "ResponsiveRoot"
    root.set_anchors_preset(Control.PRESET_FULL_RECT)
    root.add_theme_constant_override("margin_left", 48)
    root.add_theme_constant_override("margin_top", 32)
    root.add_theme_constant_override("margin_right", 48)
    root.add_theme_constant_override("margin_bottom", 32)
    add_child(root)
    move_child(root, crt_overlay.get_index())

    var main_vbox: VBoxContainer = VBoxContainer.new()
    main_vbox.add_theme_constant_override("separation", 24)
    root.add_child(main_vbox)

    # 1. Header
    var header: Label = Label.new()
    header.text = _tx("ui.difficulty_select.title", "Run Preparation")
    header.add_theme_font_size_override("font_size", 42)
    header.add_theme_color_override("font_color", ACCENT_COLOR)
    header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    main_vbox.add_child(header)
    title_label = header

    # 2. Summary Panels (3 Columns)
    var summary_row: HBoxContainer = HBoxContainer.new()
    summary_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
    summary_row.add_theme_constant_override("separation", 20)
    main_vbox.add_child(summary_row)

    char_panel = _add_summary_panel(summary_row, "Character")
    weapon_panel = _add_summary_panel(summary_row, "Starter Weapon")
    diff_panel = _add_summary_panel(summary_row, "Danger Level")

    # 3. Difficulty Selector (0-9)
    var selector_vbox: VBoxContainer = VBoxContainer.new()
    selector_vbox.add_theme_constant_override("separation", 10)
    main_vbox.add_child(selector_vbox)

    var selector_row: HBoxContainer = HBoxContainer.new()
    selector_row.alignment = BoxContainer.ALIGNMENT_CENTER
    selector_row.add_theme_constant_override("separation", 12)
    selector_vbox.add_child(selector_row)

    diff_buttons.clear()
    for i in range(DANGER_LEVELS):
        var btn: Button = Button.new()
        btn.custom_minimum_size = Vector2(64, 64)
        btn.text = str(i)
        btn.add_theme_font_size_override("font_size", 28)
        btn.pressed.connect(_on_danger_selected.bind(i))
        selector_row.add_child(btn)
        diff_buttons.append(btn)

    # 4. Footer
    var footer: HBoxContainer = HBoxContainer.new()
    footer.add_theme_constant_override("separation", 20)
    main_vbox.add_child(footer)

    back_button = Button.new()
    back_button.text = _tx("ui.common.back", "Back")
    back_button.custom_minimum_size = Vector2(180, 56)
    back_button.pressed.connect(_on_back_pressed)
    _style_button(back_button, Color(0.1, 0.15, 0.2, 0.9), SOFT_LINE_COLOR)
    footer.add_child(back_button)

    var spacer: Control = Control.new()
    spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    footer.add_child(spacer)

    start_button = Button.new()
    start_button.text = _tx("ui.difficulty_select.start", "Start Run")
    start_button.custom_minimum_size = Vector2(280, 56)
    start_button.pressed.connect(_on_start_pressed)
    _style_button(start_button, Color(0.12, 0.2, 0.3, 0.95), ACCENT_COLOR)
    footer.add_child(start_button)

func _add_summary_panel(parent: HBoxContainer, title: String) -> PanelContainer:
    var panel: PanelContainer = PanelContainer.new()
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    panel.add_theme_stylebox_override("panel", _make_panel_style(PANEL_COLOR, SOFT_LINE_COLOR, 8, 1))
    parent.add_child(panel)

    var margin: MarginContainer = MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 16)
    margin.add_theme_constant_override("margin_top", 16)
    margin.add_theme_constant_override("margin_right", 16)
    margin.add_theme_constant_override("margin_bottom", 16)
    panel.add_child(margin)

    var vbox: VBoxContainer = VBoxContainer.new()
    vbox.add_theme_constant_override("separation", 10)
    margin.add_child(vbox)

    var lbl: Label = Label.new()
    lbl.text = title
    lbl.add_theme_color_override("font_color", MUTED_TEXT_COLOR)
    lbl.add_theme_font_size_override("font_size", 18)
    vbox.add_child(lbl)

    var content: RichTextLabel = RichTextLabel.new()
    content.name = "Content"
    content.bbcode_enabled = true
    content.size_flags_vertical = Control.SIZE_EXPAND_FILL
    vbox.add_child(content)

    return panel

func _refresh_ui() -> void:
    # 1. Character Summary
    var char_id: String = GameManager.selected_character
    var char_name: String = _tx("data.character.%s.name" % char_id, char_id)
    var char_rt: RichTextLabel = char_panel.find_child("Content", true, false) as RichTextLabel
    if char_rt:
        char_rt.text = "[font_size=28][color=%s]%s[/color][/font_size]\n\n[color=#adC7c2]Selected Hero ready for deployment.[/color]" % [ACCENT_COLOR.to_html(), char_name]

    # 2. Weapon Summary
    var weapon_id: String = GameManager.selected_starter_weapon_id
    var weapon_name: String = "Unknown"
    var weapon_desc: String = ""
    
    var shop_catalog: Dictionary = BalanceService.get_shop_catalog()
    var weapon_pool: Array = shop_catalog.get("weapon_pool", [])
    for w in weapon_pool:
        if str(w.get("weapon_id")) == weapon_id:
            weapon_name = str(w.get("name"))
            weapon_desc = str(w.get("description"))
            break
            
    var weapon_rt: RichTextLabel = weapon_panel.find_child("Content", true, false) as RichTextLabel
    if weapon_rt:
        weapon_rt.text = "[font_size=28][color=%s]%s[/color][/font_size]\n\n[color=#adC7c2]%s[/color]" % [ACCENT_COLOR.to_html(), weapon_name, weapon_desc]

    # 3. Difficulty Summary
    var diff_cfg: Dictionary = DIFFICULTY_CONFIGS.get(_selected_danger, {})
    var diff_rt: RichTextLabel = diff_panel.find_child("Content", true, false) as RichTextLabel
    if diff_rt:
        var mod_lines: Array = diff_cfg.get("mods", [])
        var mod_text: String = ""
        for m in mod_lines:
            mod_text += "• %s\n" % m
        diff_rt.text = "[font_size=28][color=#f2a12e]%s[/color][/font_size]\n\n%s\n\n[color=#adC7c2]%s[/color]" % [str(diff_cfg.get("name")), mod_text, str(diff_cfg.get("desc"))]

    # 4. Buttons State
    for i in range(diff_buttons.size()):
        var btn: Button = diff_buttons[i]
        var is_selected: bool = i == _selected_danger
        var style: StyleBoxFlat = _make_button_style(Color(0.15, 0.25, 0.35, 1.0) if is_selected else CARD_COLOR, ACCENT_COLOR if is_selected else SOFT_LINE_COLOR)
        btn.add_theme_stylebox_override("normal", style)
        btn.add_theme_stylebox_override("hover", _make_button_style(CARD_HOVER_COLOR, ACCENT_COLOR))
        btn.add_theme_color_override("font_color", Color.YELLOW if is_selected else TEXT_COLOR)


func _style_button(button: Button, fill: Color, border: Color) -> void:
    button.add_theme_stylebox_override("normal", _make_button_style(fill, border))
    button.add_theme_stylebox_override("hover", _make_button_style(CARD_HOVER_COLOR, ACCENT_COLOR))
    button.add_theme_stylebox_override("pressed", _make_button_style(Color(0.2, 0.3, 0.45, 1.0), ACCENT_COLOR))
    button.add_theme_stylebox_override("focus", _make_button_style(Color(0.15, 0.25, 0.35, 1.0), ACCENT_COLOR))

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

func _reparent_control(control: Control, new_parent: Node) -> void:
    var old_parent: Node = control.get_parent()
    if old_parent != null:
        old_parent.remove_child(control)
    new_parent.add_child(control)

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
    # 阴影光晕
    style.shadow_color = border
    style.shadow_color.a = 0.2
    style.shadow_size = 8
    return style

func _make_button_style(fill: Color, border: Color) -> StyleBoxFlat:
    var style: StyleBoxFlat = _make_panel_style(fill, border, 8, 1)
    style.content_margin_left = 18
    style.content_margin_right = 18
    style.content_margin_top = 16
    style.content_margin_bottom = 16
    return style

func _tx(key: String, fallback: String = "") -> String:
    if LocaleService != null:
        return LocaleService.tx(key, fallback if not fallback.is_empty() else key)
    if fallback.is_empty():
        return key
    return fallback
