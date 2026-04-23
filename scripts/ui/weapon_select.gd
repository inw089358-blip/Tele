extends Control

const WEAPON_ICON_DIR: String = "res://sprite/weapons/generated_from_doc_v1_alpha_final_v2/"
const WEAPON_ICON_MAX_WIDTH: int = 72
const WEAPON_GRID_COLUMNS: int = 5
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

func _ready() -> void :
    if not _validate_ui_nodes():
        push_error("WeaponSelect UI binding failed.")
        return
    _load_starter_weapons()
    _build_button_styles()
    _bind_buttons()
    _render_weapon_list()
    _refresh_selection_ui()
    await get_tree().process_frame
    _scroll_selected_button_into_view(false)

func _unhandled_input(event: InputEvent) -> void :
    if event.is_action_pressed("cancel"):
        _on_back_pressed()
    elif event.is_action_pressed("confirm"):
        _on_confirm_pressed()
    elif event.is_action_pressed("ui_left"):
        _move_selection(-1)
    elif event.is_action_pressed("ui_right"):
        _move_selection(1)
    elif event.is_action_pressed("ui_up"):
        _move_selection(-WEAPON_GRID_COLUMNS)
    elif event.is_action_pressed("ui_down"):
        _move_selection(WEAPON_GRID_COLUMNS)

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
        select_button.custom_minimum_size = Vector2(0, 120)
        select_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        select_button.text = ""
        select_button.tooltip_text = "%s [%s]" % [weapon_name, mode_label]
        select_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
        select_button.focus_mode = Control.FOCUS_NONE
        select_button.clip_text = true
        select_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
        select_button.expand_icon = true
        select_button.add_theme_constant_override("icon_max_width", WEAPON_ICON_MAX_WIDTH)
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
    _selected_weapon_id = weapon_id
    _refresh_selection_ui()
    _scroll_selected_button_into_view(true)

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
    lines.append("[b]%s[/b]" % str(selected_entry.get("name", _selected_weapon_id)))
    lines.append(str(selected_entry.get("description", "")))
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
    if _selected_weapon_id.is_empty():
        return
    GameManager.go_to_difficulty_select_with_weapon(_selected_weapon_id)

func _on_back_pressed() -> void:
    GameManager.selected_starter_weapon_id = ""
    GameManager.go_to_character_select()

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
    _style_unselected = StyleBoxFlat.new()
    _style_unselected.bg_color = Color(0.06, 0.09, 0.12, 0.92)
    _style_unselected.border_color = Color(0.08, 0.15, 0.2, 0.95)
    _style_unselected.border_width_left = 1
    _style_unselected.border_width_top = 1
    _style_unselected.border_width_right = 1
    _style_unselected.border_width_bottom = 1

    _style_hover = _style_unselected.duplicate() as StyleBoxFlat
    _style_hover.bg_color = Color(0.09, 0.13, 0.17, 0.96)
    _style_hover.border_color = Color(0.2, 0.56, 0.7, 0.95)

    _style_selected = _style_unselected.duplicate() as StyleBoxFlat
    _style_selected.bg_color = Color(0.14, 0.17, 0.2, 1.0)
    _style_selected.border_color = Color(0.86, 0.9, 0.95, 1.0)
    _style_selected.border_width_left = 3
    _style_selected.border_width_top = 3
    _style_selected.border_width_right = 3
    _style_selected.border_width_bottom = 3

func _apply_button_style(btn: Button, selected: bool) -> void:
    btn.add_theme_stylebox_override("normal", _style_selected if selected else _style_unselected)
    btn.add_theme_stylebox_override("pressed", _style_selected if selected else _style_hover)
    btn.add_theme_stylebox_override("hover", _style_hover if not selected else _style_selected)

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
