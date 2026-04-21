extends Control

const ShopSystemScript: Script = preload("res://scripts/systems/shop_system.gd")

@onready var gold_label: Label = get_node_or_null("Root/MainVBox/TopBar/GoldLabel") as Label
@onready var wave_label: Label = get_node_or_null("Root/MainVBox/TopBar/WaveLabel") as Label
@onready var refresh_button: Button = get_node_or_null("Root/MainVBox/TopBar/RefreshButton") as Button
@onready var lock_button: Button = get_node_or_null("Root/MainVBox/TopBar/LockButton") as Button
@onready var next_wave_button: Button = get_node_or_null("Root/MainVBox/BottomPanel/BottomMargin/BottomVBox/BottomActions/NextWaveButton") as Button
@onready var offers_grid: GridContainer = get_node_or_null("Root/MainVBox/MidRow/OffersPanel/OffersMargin/OffersGrid") as GridContainer
@onready var attr_label: RichTextLabel = get_node_or_null("Root/MainVBox/MidRow/RightPanel/RightMargin/AttrLabel") as RichTextLabel
@onready var weapon_slots_row: HBoxContainer = get_node_or_null("Root/MainVBox/BottomPanel/BottomMargin/BottomVBox/WeaponSlotsRow") as HBoxContainer
@onready var hint_label: Label = get_node_or_null("Root/MainVBox/BottomPanel/BottomMargin/BottomVBox/BottomActions/HintLabel") as Label

var _shop_system: ShopSystem
var _snapshot: Dictionary = {}
var _shop_offers: Array[Dictionary] = []
var _pending_replace_offer_id: String = ""

func _ready() -> void:
    randomize()
    if not _validate_ui_nodes():
        push_error("ShopScene UI binding failed.")
        return
    _shop_system = ShopSystemScript.new() as ShopSystem
    _shop_system.setup(BalanceService.get_shop_catalog())
    _snapshot = _build_default_snapshot(GameManager.consume_pending_shop_snapshot())
    _ensure_shop_state()
    _bind_buttons()
    _roll_if_needed()
    _rebuild_ui()

func _build_default_snapshot(raw: Dictionary) -> Dictionary:
    var snapshot: Dictionary = {
        "stage_id": GameManager.current_stage_id,
        "wave": max(1, GameManager.current_wave),
        "wave_progress_index": max(0, GameManager.current_wave - 1),
        "current_gold": 0,
        "player_stats": {},
        "bonus_attack_damage": 0,
        "bonus_target_range": 0.0,
        "player_move_speed": 220.0,
        "gold_gain_multiplier": 1.0,
        "shop_runtime_state": {},
        "shop_offers": [],
    }
    for key: String in raw.keys():
        snapshot[key] = raw[key]
    return snapshot

func _ensure_shop_state() -> void:
    var state: Dictionary = _snapshot.get("shop_runtime_state", {})
    if not (state is Dictionary):
        state = {}
    state["equipped_weapons"] = _normalize_weapon_slots(state.get("equipped_weapons", []))
    var locked_offers: Variant = state.get("locked_shop_offers", [])
    if not (locked_offers is Array):
        locked_offers = []
    state["locked_shop_offers"] = (locked_offers as Array).duplicate(true)
    state["refresh_count"] = max(0, int(state.get("refresh_count", 0)))
    state["shop_locked"] = bool(state.get("shop_locked", false))
    _snapshot["shop_runtime_state"] = state

func _bind_buttons() -> void:
    refresh_button.pressed.connect(_on_refresh_pressed)
    lock_button.pressed.connect(_on_lock_pressed)
    next_wave_button.pressed.connect(_on_next_wave_pressed)

func _validate_ui_nodes() -> bool:
    return (
        gold_label != null
        and wave_label != null
        and refresh_button != null
        and lock_button != null
        and next_wave_button != null
        and offers_grid != null
        and attr_label != null
        and weapon_slots_row != null
        and hint_label != null
    )

func _roll_if_needed() -> void:
    var existing: Variant = _snapshot.get("shop_offers", [])
    if existing is Array and not (existing as Array).is_empty():
        for offer in existing:
            if offer is Dictionary:
                _shop_offers.append((offer as Dictionary).duplicate(true))
    if _shop_offers.is_empty():
        _shop_offers = _shop_system.roll_shop_offers(_snapshot)
    _snapshot["shop_offers"] = _shop_offers.duplicate(true)

func _on_refresh_pressed() -> void:
    if not _pending_replace_offer_id.is_empty():
        hint_label.text = "Please finish weapon replacement first."
        return
    var shop_rules: Dictionary = BalanceService.get_shop_catalog().get("shop_rules", {})
    var state: Dictionary = _snapshot.get("shop_runtime_state", {})
    var refresh_count: int = int(state.get("refresh_count", 0))
    var refresh_price: int = int(shop_rules.get("refresh_base_cost", 20)) + int(shop_rules.get("refresh_cost_step", 10)) * refresh_count
    var current_gold: int = int(_snapshot.get("current_gold", 0))
    if current_gold < refresh_price:
        hint_label.text = "Not enough gold for refresh."
        return
    _snapshot["current_gold"] = current_gold - refresh_price
    state["refresh_count"] = refresh_count + 1
    _snapshot["shop_runtime_state"] = state
    _shop_offers = _shop_system.roll_shop_offers(_snapshot)
    _snapshot["shop_offers"] = _shop_offers.duplicate(true)
    hint_label.text = "Shop refreshed."
    _rebuild_ui()

func _on_lock_pressed() -> void:
    if not _pending_replace_offer_id.is_empty():
        hint_label.text = "Please finish weapon replacement first."
        return
    var state: Dictionary = _snapshot.get("shop_runtime_state", {})
    var next_locked: bool = not bool(state.get("shop_locked", false))
    state["shop_locked"] = next_locked
    if next_locked:
        state["locked_shop_offers"] = _shop_offers.duplicate(true)
    else:
        state["locked_shop_offers"] = []
    _snapshot["shop_runtime_state"] = state
    hint_label.text = "Shop lock %s." % ("enabled" if next_locked else "disabled")
    _rebuild_ui()

func _on_next_wave_pressed() -> void:
    if not _pending_replace_offer_id.is_empty():
        hint_label.text = "Choose a slot to replace first."
        return
    var state: Dictionary = _snapshot.get("shop_runtime_state", {})
    if not bool(state.get("shop_locked", false)):
        state["locked_shop_offers"] = []
    state.erase("pending_replace_weapon")
    _snapshot["shop_runtime_state"] = state
    _snapshot["shop_offers"] = _shop_offers.duplicate(true)
    GameManager.continue_from_shop(_snapshot)

func _on_offer_buy_pressed(offer_id: String) -> void:
    if not _pending_replace_offer_id.is_empty():
        hint_label.text = "Choose a weapon slot first."
        return
    _snapshot["shop_offers"] = _shop_offers.duplicate(true)
    var result: Dictionary = _shop_system.purchase_offer(offer_id, _snapshot)
    var updated_state: Dictionary = result.get("state", _snapshot)
    if bool(result.get("ok", false)):
        _snapshot = updated_state
        _shop_offers = _extract_offer_list(_snapshot.get("shop_offers", []))
        hint_label.text = str(result.get("message", "Purchased."))
        _rebuild_ui()
        return
    if bool(result.get("needs_replace", false)):
        _snapshot = updated_state
        _pending_replace_offer_id = offer_id
        hint_label.text = "Weapon slots full. Click a slot below to replace."
        _rebuild_ui()
        return
    hint_label.text = str(result.get("message", "Purchase failed"))
    _rebuild_ui()

func _on_weapon_slot_pressed(slot_index: int) -> void:
    if _pending_replace_offer_id.is_empty():
        return
    _snapshot["replace_slot_index"] = slot_index
    _snapshot["shop_offers"] = _shop_offers.duplicate(true)
    var result: Dictionary = _shop_system.purchase_offer(_pending_replace_offer_id, _snapshot)
    _snapshot.erase("replace_slot_index")
    if bool(result.get("ok", false)):
        _snapshot = result.get("state", _snapshot)
        _shop_offers = _extract_offer_list(_snapshot.get("shop_offers", []))
        _pending_replace_offer_id = ""
        hint_label.text = "Weapon replaced."
    else:
        hint_label.text = str(result.get("message", "Replace failed"))
    _rebuild_ui()

func _extract_offer_list(raw: Variant) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    if raw is Array:
        for item in raw:
            if item is Dictionary:
                result.append((item as Dictionary).duplicate(true))
    return result

func _normalize_weapon_slots(raw_slots: Variant) -> Array:
    var slots: Array = []
    if raw_slots is Array:
        var raw_array: Array = raw_slots
        for i: int in range(min(raw_array.size(), 6)):
            var item: Variant = raw_array[i]
            slots.append(item.duplicate(true) if item is Dictionary else {})
    while slots.size() < 6:
        slots.append({})
    return slots

func _rebuild_ui() -> void:
    gold_label.text = "Gold: %d" % int(_snapshot.get("current_gold", 0))
    wave_label.text = "Stage %s Shop" % str(_snapshot.get("stage_id", GameManager.current_stage_id))
    var shop_state: Dictionary = _snapshot.get("shop_runtime_state", {})
    var refresh_count: int = int(shop_state.get("refresh_count", 0))
    var shop_rules: Dictionary = BalanceService.get_shop_catalog().get("shop_rules", {})
    var refresh_price: int = int(shop_rules.get("refresh_base_cost", 20)) + int(shop_rules.get("refresh_cost_step", 10)) * refresh_count
    refresh_button.text = "Refresh (%dG)" % refresh_price
    lock_button.text = "Lock: %s" % ("ON" if bool(shop_state.get("shop_locked", false)) else "OFF")
    lock_button.modulate = Color(0.98, 0.85, 0.4, 1.0) if bool(shop_state.get("shop_locked", false)) else Color(1, 1, 1, 1)
    next_wave_button.text = "Start Next Stage"
    next_wave_button.disabled = false
    _rebuild_offer_cards()
    _rebuild_attr_panel()
    _rebuild_weapon_slots()

func _rebuild_offer_cards() -> void:
    for child: Node in offers_grid.get_children():
        child.queue_free()
    for offer: Dictionary in _shop_offers:
        var card: PanelContainer = PanelContainer.new()
        card.custom_minimum_size = Vector2(220, 190)
        var vb: VBoxContainer = VBoxContainer.new()
        var title: Label = Label.new()
        title.text = "%s [%s]" % [str(offer.get("name", "Offer")), str(offer.get("rarity", "common")).to_upper()]
        title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        var desc: Label = Label.new()
        desc.text = str(offer.get("description", ""))
        desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
        var buy_button: Button = Button.new()
        var sold: bool = bool(offer.get("sold", false))
        buy_button.text = "Sold Out" if sold else "Buy - %dG" % int(offer.get("price", 0))
        buy_button.disabled = sold or int(_snapshot.get("current_gold", 0)) < int(offer.get("price", 0))
        buy_button.pressed.connect(_on_offer_buy_pressed.bind(str(offer.get("offer_id", ""))))
        vb.add_child(title)
        vb.add_child(desc)
        vb.add_child(buy_button)
        card.add_child(vb)
        offers_grid.add_child(card)

func _rebuild_attr_panel() -> void:
    var stats: Dictionary = _snapshot.get("player_stats", {})
    var lines: Array[String] = []
    lines.append("[b]Stats[/b]")
    lines.append("ATK Bonus: %d" % int(_snapshot.get("bonus_attack_damage", 0)))
    lines.append("Range Bonus: %.0f" % float(_snapshot.get("bonus_target_range", 0.0)))
    lines.append("Move Speed: %.0f" % float(_snapshot.get("player_move_speed", 220.0)))
    lines.append("Armor: %.1f" % float(stats.get("armor", 0.0)))
    lines.append("Dodge: %.1f%%" % (float(stats.get("dodge_chance", 0.0)) * 100.0))
    lines.append("Atk Speed: %.2f" % float(stats.get("attack_speed_mult", 1.0)))
    lines.append("Crit: %.1f%%" % (float(stats.get("crit_chance", 0.05)) * 100.0))
    lines.append("Crit Mult: %.2f" % float(stats.get("crit_multiplier", 1.5)))
    lines.append("Lifesteal: %.1f%%" % (float(stats.get("lifesteal", 0.0)) * 100.0))
    attr_label.text = "\n".join(lines)

func _rebuild_weapon_slots() -> void:
    for child: Node in weapon_slots_row.get_children():
        child.queue_free()
    var shop_state: Dictionary = _snapshot.get("shop_runtime_state", {})
    var slots: Array = _normalize_weapon_slots(shop_state.get("equipped_weapons", []))
    for i: int in range(slots.size()):
        var slot_weapon: Variant = slots[i]
        var button: Button = Button.new()
        button.custom_minimum_size = Vector2(120, 58)
        var has_weapon: bool = slot_weapon is Dictionary and not str((slot_weapon as Dictionary).get("weapon_id", "")).is_empty()
        if has_weapon:
            var weapon: Dictionary = slot_weapon
            button.text = "%d: %s\n%s" % [i + 1, str(weapon.get("weapon_id", "weapon")), str(weapon.get("rarity", "common"))]
        else:
            button.text = "%d: Empty" % (i + 1)
        button.pressed.connect(_on_weapon_slot_pressed.bind(i))
        button.disabled = _pending_replace_offer_id.is_empty()
        weapon_slots_row.add_child(button)
