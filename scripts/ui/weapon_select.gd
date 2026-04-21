extends Control

@onready var title_label: Label = get_node_or_null("Root/MainVBox/TitleLabel") as Label
@onready var subtitle_label: Label = get_node_or_null("Root/MainVBox/SubtitleLabel") as Label
@onready var weapon_list: VBoxContainer = get_node_or_null("Root/MainVBox/BodyRow/ListPanel/ListMargin/WeaponList") as VBoxContainer
@onready var detail_label: RichTextLabel = get_node_or_null("Root/MainVBox/BodyRow/DetailPanel/DetailMargin/DetailLabel") as RichTextLabel
@onready var confirm_button: Button = get_node_or_null("Root/MainVBox/BottomRow/ConfirmButton") as Button
@onready var back_button: Button = get_node_or_null("Root/MainVBox/BottomRow/BackButton") as Button

var _starter_weapons: Array[Dictionary] = []
var _selected_weapon_id: String = ""

func _ready() -> void :
    if not _validate_ui_nodes():
        push_error("WeaponSelect UI binding failed.")
        return
    _load_starter_weapons()
    _bind_buttons()
    _render_weapon_list()
    _refresh_selection_ui()

func _unhandled_input(event: InputEvent) -> void :
    if event.is_action_pressed("cancel"):
        _on_back_pressed()
    elif event.is_action_pressed("confirm"):
        _on_confirm_pressed()

func _bind_buttons() -> void:
    confirm_button.pressed.connect(_on_confirm_pressed)
    back_button.pressed.connect(_on_back_pressed)

func _validate_ui_nodes() -> bool:
    return (
        title_label != null
        and subtitle_label != null
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
            var weapon_entry: Dictionary = weapon_value
            if not bool(weapon_entry.get("starter", false)):
                continue
            _starter_weapons.append(weapon_entry.duplicate(true))
    if not _starter_weapons.is_empty():
        _selected_weapon_id = str(_starter_weapons[0].get("weapon_id", ""))

func _render_weapon_list() -> void:
    for child: Node in weapon_list.get_children():
        child.queue_free()
    for weapon_entry: Dictionary in _starter_weapons:
        var weapon_id: String = str(weapon_entry.get("weapon_id", ""))
        var weapon_name: String = str(weapon_entry.get("name", weapon_id))
        var mode: String = str(weapon_entry.get("attack_profile", {}).get("mode", "ranged_homing"))
        var select_button: Button = Button.new()
        select_button.custom_minimum_size = Vector2(0, 52)
        select_button.text = "%s  [%s]" % [weapon_name, mode]
        select_button.pressed.connect(_on_weapon_selected.bind(weapon_id))
        weapon_list.add_child(select_button)

func _on_weapon_selected(weapon_id: String) -> void:
    _selected_weapon_id = weapon_id
    _refresh_selection_ui()

func _refresh_selection_ui() -> void:
    title_label.text = "Select Starter Weapon"
    subtitle_label.text = "Character: %s" % GameManager.selected_character
    var selected_entry: Dictionary = _find_weapon_by_id(_selected_weapon_id)
    if selected_entry.is_empty():
        detail_label.text = "No starter weapon available."
        confirm_button.disabled = true
        return

    var attack_profile: Dictionary = selected_entry.get("attack_profile", {})
    var lines: Array[String] = []
    lines.append("[b]%s[/b]" % str(selected_entry.get("name", _selected_weapon_id)))
    lines.append(str(selected_entry.get("description", "")))
    lines.append("")
    lines.append("Mode: %s" % str(attack_profile.get("mode", "ranged_homing")))
    lines.append("Damage: %s" % str(attack_profile.get("base_damage", 10)))
    lines.append("Interval: %s" % str(attack_profile.get("interval", 0.35)))
    lines.append("Range: %s" % str(attack_profile.get("range", 320)))
    if attack_profile.has("projectile_speed"):
        lines.append("Projectile Speed: %s" % str(attack_profile.get("projectile_speed", 520)))
    if attack_profile.has("projectile_radius"):
        lines.append("Projectile Radius: %s" % str(attack_profile.get("projectile_radius", 4)))
    detail_label.text = "\n".join(lines)
    confirm_button.disabled = false

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
