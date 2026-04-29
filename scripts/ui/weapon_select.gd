extends Control

const WEAPON_ICON_DIR: String = "res://sprite/weapons/generated_from_doc_v1_alpha_final_v2/"
const WEAPON_ICON_MAX_WIDTH: int = 72
const WEAPON_GRID_COLUMNS: int = 5
const BG_COLOR: Color = Color("#050a10")
const PANEL_COLOR: Color = Color(0.06, 0.09, 0.14, 0.94)
const CARD_COLOR: Color = Color(0.1, 0.16, 0.24, 0.90)
const CARD_HOVER_COLOR: Color = Color(0.15, 0.25, 0.35, 0.96)
const TEXT_COLOR: Color = Color(0.94, 0.95, 0.98, 1.0)
const MUTED_TEXT_COLOR: Color = Color(0.6, 0.75, 0.8, 1.0)
const ACCENT_COLOR: Color = Color("#00f0ff")
const SOFT_LINE_COLOR: Color = Color(0.0, 0.94, 1.0, 0.3)
const WEAPON_DISPLAY_ORDER: Array[String] = [
    "kunai",
    "steel_pipe",
    "heavy_wrench",
    "road_sign",
    "nail_gun",
    "mechanical_crossbow",
    "flare_launcher",
    "traffic_cone",
    "circular_saw",
    "shuriken_ring",
    "molotov",
    "rebar_spear",
    "drum_mallet",
    "meteor_hammer",
    "chain_whip",
]

@onready var background: ColorRect = get_node_or_null("Background") as ColorRect
@onready var root_margin: MarginContainer = get_node_or_null("Root") as MarginContainer
@onready var main_vbox: VBoxContainer = get_node_or_null("Root/MainVBox") as VBoxContainer
@onready var list_panel: PanelContainer = get_node_or_null("Root/MainVBox/BodyRow/ListPanel") as PanelContainer
@onready var detail_panel: PanelContainer = get_node_or_null("Root/MainVBox/BodyRow/DetailPanel") as PanelContainer
@onready var bottom_row: HBoxContainer = get_node_or_null("Root/MainVBox/BottomRow") as HBoxContainer
@onready var title_label: Label = get_node_or_null("Root/MainVBox/TitleLabel") as Label
@onready var subtitle_label: Label = get_node_or_null("Root/MainVBox/SubtitleLabel") as Label
@onready var weapon_scroll: ScrollContainer = get_node_or_null("Root/MainVBox/BodyRow/ListPanel/ListMargin/WeaponScroll") as ScrollContainer
@onready var weapon_list: GridContainer = get_node_or_null("Root/MainVBox/BodyRow/ListPanel/ListMargin/WeaponScroll/WeaponList") as GridContainer
@onready var detail_label: RichTextLabel = get_node_or_null("Root/MainVBox/BodyRow/DetailPanel/DetailMargin/DetailLabel") as RichTextLabel
@onready var confirm_button: Button = get_node_or_null("Root/MainVBox/BottomRow/ConfirmButton") as Button
@onready var back_button: Button = get_node_or_null("Root/MainVBox/BottomRow/BackButton") as Button

var _starter_weapons: Array[Dictionary] = []
var _selected_weapon_id: String = ""
var _weapon_buttons: Array[Button] = []
var _scroll_tween: Tween
var _weapon_icon_cache: Dictionary = {}
var _style_unselected: StyleBoxFlat
var _style_hover: StyleBoxFlat
var _style_selected: StyleBoxFlat
var _scene_input_ready: bool = false
var _queued_action: Callable = Callable()
var _queued_action_id: String = ""

func _ready() -> void :
    if not _validate_ui_nodes():
        push_error("WeaponSelect UI binding failed.")
        return
    _style_layout()
    _load_starter_weapons()
    _build_button_styles()
    _bind_buttons()
    _render_weapon_list()
    _refresh_selection_ui()
    await get_tree().process_frame
    _scroll_selected_button_into_view(false)
    _add_vignette_background()
    _arm_scene_ready_gate()

func _unhandled_input(event: InputEvent) -> void :
    if event.is_action_pressed("cancel"):
        _on_back_pressed()
    elif event.is_action_pressed("confirm"):
        _on_confirm_pressed()
    elif event.is_action_pressed("ui_left"):
        _invoke_or_queue("weapon_nav_left", Callable(self, "_do_nav_left"))
    elif event.is_action_pressed("ui_right"):
        _invoke_or_queue("weapon_nav_right", Callable(self, "_do_nav_right"))
    elif event.is_action_pressed("ui_up"):
        _invoke_or_queue("weapon_nav_up", Callable(self, "_do_nav_up"))
    elif event.is_action_pressed("ui_down"):
        _invoke_or_queue("weapon_nav_down", Callable(self, "_do_nav_down"))

func _bind_buttons() -> void:
    confirm_button.pressed.connect(_on_confirm_pressed)
    back_button.pressed.connect(_on_back_pressed)

func _validate_ui_nodes() -> bool:
    return (
        title_label != null
        and subtitle_label != null
        and weapon_scroll != null
        and weapon_list != null
        and detail_label != null
        and confirm_button != null
        and back_button != null
    )

func _load_starter_weapons() -> void:
    _starter_weapons.clear()
    var shop_catalog: Dictionary = BalanceService.get_shop_catalog()
    var weapon_pool_value: Variant = shop_catalog.get("weapon_pool", [])
    if weapon_pool_value is Array:
        var weapon_pool: Array = weapon_pool_value
        for weapon_value in weapon_pool:
            if not (weapon_value is Dictionary):
                continue
            var weapon_entry: Dictionary = (weapon_value as Dictionary).duplicate(true)
            if not bool(weapon_entry.get("starter", false)):
                continue
            _apply_localized_display_text(weapon_entry)
            _starter_weapons.append(weapon_entry)
    _sort_starter_weapons()
    if not _starter_weapons.is_empty():
        _selected_weapon_id = str(_starter_weapons[0].get("weapon_id", ""))

func _apply_localized_display_text(weapon_entry: Dictionary) -> void:
    var weapon_id: String = str(weapon_entry.get("weapon_id", ""))
    if weapon_id.is_empty():
        return
    weapon_entry["name"] = LocaleService.t_data("weapon", weapon_id, "name", str(weapon_entry.get("name", weapon_id)))
    weapon_entry["description"] = LocaleService.t_data("weapon", weapon_id, "desc", str(weapon_entry.get("description", "")))

func _sort_starter_weapons() -> void:
    var order_map: Dictionary = {}
    for i: int in range(WEAPON_DISPLAY_ORDER.size()):
        order_map[WEAPON_DISPLAY_ORDER[i]] = i
    _starter_weapons.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        var a_id: String = str(a.get("weapon_id", ""))
        var b_id: String = str(b.get("weapon_id", ""))
        var a_order: int = int(order_map.get(a_id, 10000))
        var b_order: int = int(order_map.get(b_id, 10000))
        if a_order == b_order:
            return a_id < b_id
        return a_order < b_order
    )

func _render_weapon_list() -> void:
    for child: Node in weapon_list.get_children():
        child.queue_free()
    _weapon_buttons.clear()
    for weapon_entry: Dictionary in _starter_weapons:
        var weapon_id: String = str(weapon_entry.get("weapon_id", ""))
        var weapon_name: String = str(weapon_entry.get("name", weapon_id))
        var mode: String = str(weapon_entry.get("attack_profile", {}).get("mode", "ranged_homing"))
        var mode_label: String = _weapon_mode_label(mode)
        var select_button: Button = Button.new()
        select_button.custom_minimum_size = Vector2(0, 138)
        select_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        select_button.text = weapon_name
        select_button.tooltip_text = "%s [%s]" % [weapon_name, mode_label]
        select_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
        select_button.focus_mode = Control.FOCUS_NONE
        select_button.clip_text = true
        select_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
        select_button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
        select_button.expand_icon = true
        select_button.add_theme_constant_override("icon_max_width", WEAPON_ICON_MAX_WIDTH)
        select_button.add_theme_font_size_override("font_size", 15)
        select_button.add_theme_color_override("font_color", TEXT_COLOR)
        select_button.add_theme_color_override("font_hover_color", TEXT_COLOR)
        select_button.add_theme_color_override("font_pressed_color", TEXT_COLOR)
        select_button.add_theme_stylebox_override("focus", _style_hover)
        var icon: Texture2D = _get_weapon_icon(weapon_id)
        if icon != null:
            select_button.icon = icon
        select_button.pressed.connect(_on_weapon_selected.bind(weapon_id))
        weapon_list.add_child(select_button)
        _weapon_buttons.append(select_button)

func _get_weapon_icon(weapon_id: String) -> Texture2D:
    if weapon_id.is_empty():
        return null
    if _weapon_icon_cache.has(weapon_id):
        return _weapon_icon_cache[weapon_id] as Texture2D
    var icon_path: String = "%s%s.png" % [WEAPON_ICON_DIR, weapon_id]
    if not ResourceLoader.exists(icon_path):
        _weapon_icon_cache[weapon_id] = null
        return null
    var icon: Texture2D = load(icon_path) as Texture2D
    _weapon_icon_cache[weapon_id] = icon
    return icon

func _on_weapon_selected(weapon_id: String) -> void:
    _invoke_or_queue(
        "weapon_select_%s" % weapon_id,
        Callable(self, "_do_weapon_select").bind(weapon_id)
    )

func _refresh_selection_ui() -> void:
    title_label.text = _tx("ui.weapon_select.title", "Select Starter Weapon")
    subtitle_label.text = _tf("ui.weapon_select.character_fmt", [GameManager.selected_character], "Character: %s")
    var selected_entry: Dictionary = _find_weapon_by_id(_selected_weapon_id)
    if selected_entry.is_empty():
        detail_label.text = _tx("ui.weapon_select.no_weapon", "No starter weapon available.")
        confirm_button.disabled = true
        return

    var attack_profile: Dictionary = selected_entry.get("attack_profile", {})
    var lines: Array[String] = []
    lines.append("[font_size=30][color=#f2a12e][b]%s[/b][/color][/font_size]" % str(selected_entry.get("name", _selected_weapon_id)))
    lines.append("[color=#adC7c2]%s[/color]" % str(selected_entry.get("description", "")))
    lines.append("")
    lines.append(
        _tf(
            "ui.weapon_select.mode_fmt",
            [_weapon_mode_label(str(attack_profile.get("mode", "ranged_homing")))],
            "Mode: %s"
        )
    )
    lines.append(_tf("ui.weapon_select.damage_fmt", [str(attack_profile.get("base_damage", 10))], "Damage: %s"))
    lines.append(_tf("ui.weapon_select.interval_fmt", [str(attack_profile.get("interval", 0.35))], "Interval: %s"))
    lines.append(_tf("ui.weapon_select.range_fmt", [str(attack_profile.get("range", 320))], "Range: %s"))
    if attack_profile.has("projectile_speed"):
        lines.append(_tf("ui.weapon_select.projectile_speed_fmt", [str(attack_profile.get("projectile_speed", 520))], "Projectile Speed: %s"))
    if attack_profile.has("projectile_radius"):
        lines.append(_tf("ui.weapon_select.projectile_radius_fmt", [str(attack_profile.get("projectile_radius", 4))], "Projectile Radius: %s"))
    detail_label.text = "\n".join(lines)
    confirm_button.disabled = false
    _refresh_button_states()

func _find_weapon_by_id(weapon_id: String) -> Dictionary:
    for weapon_entry: Dictionary in _starter_weapons:
        if str(weapon_entry.get("weapon_id", "")) == weapon_id:
            return weapon_entry
    return {}

func _on_confirm_pressed() -> void:
    _invoke_or_queue("weapon_confirm", Callable(self, "_do_confirm"))

func _on_back_pressed() -> void:
    _invoke_or_queue("weapon_back", Callable(self, "_do_back"))

func _move_selection(delta: int) -> void:
    if _starter_weapons.is_empty():
        return
    var index: int = _get_selected_index()
    if index < 0:
        index = 0
    var next_index: int = clampi(index + delta, 0, _starter_weapons.size() - 1)
    if next_index == index:
        return
    _selected_weapon_id = str(_starter_weapons[next_index].get("weapon_id", ""))
    _refresh_selection_ui()
    _scroll_selected_button_into_view(true)

func _do_nav_left() -> void:
    _move_selection(-1)

func _do_nav_right() -> void:
    _move_selection(1)

func _do_nav_up() -> void:
    _move_selection(-WEAPON_GRID_COLUMNS)

func _do_nav_down() -> void:
    _move_selection(WEAPON_GRID_COLUMNS)

func _do_weapon_select(weapon_id: String) -> void:
    _selected_weapon_id = weapon_id
    _refresh_selection_ui()
    _scroll_selected_button_into_view(true)

func _do_confirm() -> void:
    if _selected_weapon_id.is_empty():
        return
    GameManager.go_to_difficulty_select_with_weapon(_selected_weapon_id)

func _do_back() -> void:
    GameManager.selected_starter_weapon_id = ""
    GameManager.go_to_character_select()

func _get_selected_index() -> int:
    for i: int in range(_starter_weapons.size()):
        if str(_starter_weapons[i].get("weapon_id", "")) == _selected_weapon_id:
            return i
    return -1

func _refresh_button_states() -> void:
    var selected_index: int = _get_selected_index()
    for i: int in range(_weapon_buttons.size()):
        var btn: Button = _weapon_buttons[i]
        var selected: bool = i == selected_index
        _apply_button_style(btn, selected)

func _build_button_styles() -> void:
    _style_unselected = _make_button_style(CARD_COLOR, SOFT_LINE_COLOR, 8, 1)
    _style_hover = _make_button_style(CARD_HOVER_COLOR, ACCENT_COLOR, 8, 1)
    _style_selected = _make_button_style(Color(0.18, 0.27, 0.25, 1.0), ACCENT_COLOR, 8, 2)

func _apply_button_style(btn: Button, selected: bool) -> void:
    btn.add_theme_stylebox_override("normal", _style_selected if selected else _style_unselected)
    btn.add_theme_stylebox_override("pressed", _style_selected if selected else _style_hover)
    btn.add_theme_stylebox_override("hover", _style_hover if not selected else _style_selected)
    btn.add_theme_color_override("font_color", ACCENT_COLOR if selected else TEXT_COLOR)

func _scroll_selected_button_into_view(animated: bool) -> void:
    var selected_index: int = _get_selected_index()
    if selected_index < 0 or selected_index >= _weapon_buttons.size():
        return
    var selected_button: Button = _weapon_buttons[selected_index]
    var top: float = selected_button.position.y
    var bottom: float = top + selected_button.size.y
    var view_top: float = float(weapon_scroll.scroll_vertical)
    var view_bottom: float = view_top + weapon_scroll.size.y

    var target_scroll: float = view_top
    if top < view_top:
        target_scroll = top
    elif bottom > view_bottom:
        target_scroll = bottom - weapon_scroll.size.y
    else:
        return

    target_scroll = max(0.0, target_scroll)
    if not animated:
        weapon_scroll.scroll_vertical = int(round(target_scroll))
        return

    if _scroll_tween != null and _scroll_tween.is_valid():
        _scroll_tween.kill()
    _scroll_tween = create_tween()
    _scroll_tween.set_trans(Tween.TRANS_QUAD)
    _scroll_tween.set_ease(Tween.EASE_OUT)
    _scroll_tween.tween_property(weapon_scroll, "scroll_vertical", int(round(target_scroll)), 0.16)

func _weapon_mode_label(mode: String) -> String:
    return _tx("ui.weapon_select.mode.%s" % mode, mode)

func _style_layout() -> void:
    if background != null:
        background.color = BG_COLOR
    if root_margin != null:
        root_margin.add_theme_constant_override("margin_left", 36)
        root_margin.add_theme_constant_override("margin_top", 24)
        root_margin.add_theme_constant_override("margin_right", 36)
        root_margin.add_theme_constant_override("margin_bottom", 28)
    if main_vbox != null:
        main_vbox.add_theme_constant_override("separation", 18)
    if list_panel != null:
        list_panel.add_theme_stylebox_override("panel", _make_panel_style(PANEL_COLOR, SOFT_LINE_COLOR, 8, 1))
    if detail_panel != null:
        detail_panel.custom_minimum_size = Vector2(390, 0)
        detail_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.12, 0.235, 0.235, 0.88), SOFT_LINE_COLOR, 8, 1))
    if weapon_list != null:
        weapon_list.columns = WEAPON_GRID_COLUMNS
        weapon_list.add_theme_constant_override("h_separation", 12)
        weapon_list.add_theme_constant_override("v_separation", 12)
    if title_label != null:
        title_label.add_theme_font_size_override("font_size", 38)
        title_label.add_theme_color_override("font_color", ACCENT_COLOR)
    if subtitle_label != null:
        subtitle_label.add_theme_font_size_override("font_size", 20)
        subtitle_label.add_theme_color_override("font_color", MUTED_TEXT_COLOR)
    if detail_label != null:
        detail_label.bbcode_enabled = true
        detail_label.fit_content = false
        detail_label.add_theme_font_size_override("normal_font_size", 18)
        detail_label.add_theme_color_override("default_color", TEXT_COLOR)
    if bottom_row != null:
        bottom_row.add_theme_constant_override("separation", 20)
        # 将返回放在左侧，确认放在右侧，中间加弹簧
        var old_children = bottom_row.get_children()
        for c in old_children:
            bottom_row.remove_child(c)
            
        bottom_row.add_child(back_button)
        var spacer: Control = Control.new()
        spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        bottom_row.add_child(spacer)
        bottom_row.add_child(confirm_button)
        
    _style_action_button(back_button, false)
    _style_action_button(confirm_button, true)

func _style_action_button(button: Button, primary: bool) -> void:
    if button == null:
        return
    button.custom_minimum_size = Vector2(220 if not primary else 300, 54)
    button.add_theme_font_size_override("font_size", 24)
    button.add_theme_color_override("font_color", TEXT_COLOR)
    var border: Color = ACCENT_COLOR if primary else SOFT_LINE_COLOR
    button.add_theme_stylebox_override("normal", _make_button_style(Color(0.1, 0.18, 0.25, 0.95), border, 8, 1))
    button.add_theme_stylebox_override("hover", _make_button_style(Color(0.15, 0.25, 0.35, 0.98), ACCENT_COLOR, 8, 1))
    button.add_theme_stylebox_override("pressed", _make_button_style(Color(0.2, 0.3, 0.45, 1.0), ACCENT_COLOR, 8, 1))

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
    move_child(vignette, 1) # 放在 Background 之上

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
    # 增加阴影发光感
    style.shadow_color = border
    style.shadow_color.a = 0.2
    style.shadow_size = 6
    return style

func _make_button_style(fill: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
    var style: StyleBoxFlat = _make_panel_style(fill, border, radius, border_width)
    style.content_margin_left = 12
    style.content_margin_right = 12
    style.content_margin_top = 10
    style.content_margin_bottom = 10
    return style

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
        subtitle_label.text = _tx("msg.common.loading_short", "Loading...")

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
