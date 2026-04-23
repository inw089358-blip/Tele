extends Node2D

const PLAYER_SCRIPT_MAP: Dictionary[String, Script] = {
    "the_fool": preload("res://scripts/characters/the_fool.gd"),
    "the_chariot": preload("res://scripts/characters/the_chariot.gd"),
    "the_hanged_man": preload("res://scripts/characters/the_hanged_man.gd"),
}

const MAX_REFRESH_COUNT: int = 2
const BASE_REFRESH_PRICE: int = 30
const REFRESH_PRICE_STEP: int = 20
const INTERACT_ENTER_RADIUS: float = 120.0
const INTERACT_EXIT_RADIUS: float = 136.0
const INTERACT_COOLDOWN_SEC: float = 0.15
const HUB_HALF_EXTENTS: Vector2 = Vector2(360.0, 220.0)
const HUB_EDGE_PADDING: float = 16.0
const HUB_CAMERA_ZOOM: Vector2 = Vector2(1.08, 1.08)

const PATH_WORLD_ROOT: NodePath = ^"CrtWorldContainer/CrtWorldViewport/GameWorldRoot"
const PATH_GOLD_LABEL: NodePath = ^"HubUI/Root/TopBar/TopBarVBox/GoldLabel"
const PATH_GOLD_GAIN_LABEL: NodePath = ^"HubUI/Root/TopBar/TopBarVBox/GoldGainLabel"
const PATH_HINT_LABEL: NodePath = ^"HubUI/Root/TopBar/TopBarVBox/HintLabel"
const PATH_VENDOR_PANEL: NodePath = ^"HubUI/Root/VendorPanel"
const PATH_VENDOR_TITLE: NodePath = ^"HubUI/Root/VendorPanel/VendorVBox/VendorTitle"
const PATH_OFFER_LIST: NodePath = ^"HubUI/Root/VendorPanel/VendorVBox/OfferList"
const PATH_CLOSE_VENDOR_BUTTON: NodePath = ^"HubUI/Root/VendorPanel/VendorVBox/CloseVendorButton"
const PATH_REFRESH_BUTTON: NodePath = ^"HubUI/Root/BottomBar/RefreshButton"
const PATH_LEAVE_BUTTON: NodePath = ^"HubUI/Root/BottomBar/LeaveButton"
const PATH_LEAVE_CONFIRM: NodePath = ^"HubUI/Root/LeaveConfirmDialog"
const PATH_WITCH_AREA: NodePath = ^"CrtWorldContainer/CrtWorldViewport/GameWorldRoot/World/WitchRoot/WitchArea"
const PATH_TRAVELER_AREA: NodePath = ^"CrtWorldContainer/CrtWorldViewport/GameWorldRoot/World/TravelerRoot/TravelerArea"
const PATH_SEER_AREA: NodePath = ^"CrtWorldContainer/CrtWorldViewport/GameWorldRoot/World/SeerRoot/SeerArea"
const PATH_BROKER_AREA: NodePath = ^"CrtWorldContainer/CrtWorldViewport/GameWorldRoot/World/BrokerRoot/BrokerArea"
const PATH_WITCH_ANCHOR: NodePath = ^"CrtWorldContainer/CrtWorldViewport/GameWorldRoot/World/WitchRoot"
const PATH_TRAVELER_ANCHOR: NodePath = ^"CrtWorldContainer/CrtWorldViewport/GameWorldRoot/World/TravelerRoot"
const PATH_SEER_ANCHOR: NodePath = ^"CrtWorldContainer/CrtWorldViewport/GameWorldRoot/World/SeerRoot"
const PATH_BROKER_ANCHOR: NodePath = ^"CrtWorldContainer/CrtWorldViewport/GameWorldRoot/World/BrokerRoot"
const PATH_WORLD_HINT_LABEL: NodePath = ^"HubUI/Root/WorldHintLabel"
const PATH_STATUS_LABEL: NodePath = ^"HubUI/Root/TopBar/TopBarVBox/StatusLabel"

var world_root: Node2D
var gold_label: Label
var gold_gain_label: Label
var hint_label: Label
var vendor_panel: PanelContainer
var vendor_title: Label
var offer_list: VBoxContainer
var close_vendor_button: Button
var refresh_button: Button
var leave_button: Button
var leave_confirm: ConfirmationDialog
var witch_area: Area2D
var traveler_area: Area2D
var seer_area: Area2D
var broker_area: Area2D
var witch_anchor: Node2D
var traveler_anchor: Node2D
var seer_anchor: Node2D
var broker_anchor: Node2D
var world_hint_label: Label
var status_label: Label

var _player: Player
var _run_state: Dictionary = {}
var _vendor_offers: Dictionary = {}
var _active_vendor: String = ""
var _in_witch_range: bool = false
var _in_traveler_range: bool = false
var _in_seer_range: bool = false
var _in_broker_range: bool = false
var _interact_cooldown_timer: float = 0.0
var _vendor_core_purchases: Dictionary = {}
var _hub_camera: Camera2D

const RECOVER_OFFERS: Array[Dictionary] = [
    {
        "offer_id": "recover_small",
        "type": "recover",
        "name": "Small Recover",
        "heal_percent": 0.25,
        "base_price": 35,
        "price_scale": 1.15,
        "limit": 3,
        "vendor": "witch",
    },
    {
        "offer_id": "recover_mid",
        "type": "recover",
        "name": "Medium Recover",
        "heal_percent": 0.5,
        "base_price": 65,
        "price_scale": 1.15,
        "limit": 2,
        "vendor": "witch",
    },
    {
        "offer_id": "recover_full",
        "type": "recover",
        "name": "Full Recover",
        "heal_percent": 1.0,
        "base_price": 120,
        "price_scale": 1.15,
        "limit": 1,
        "vendor": "witch",
    },
]

const UPGRADE_OFFERS: Array[Dictionary] = [
    {
        "offer_id": "upgrade_attack_power",
        "type": "upgrade",
        "name": "Attack Power +8%",
        "base_price": 60,
        "price_scale": 1.35,
        "limit": 3,
        "effect": {"bonus_attack_damage": 3},
        "vendor": "witch",
    },
    {
        "offer_id": "upgrade_attack_speed",
        "type": "upgrade",
        "name": "Attack Frequency +6%",
        "base_price": 65,
        "price_scale": 1.35,
        "limit": 3,
        "effect": {"auto_attack_interval_multiplier": 0.94},
        "vendor": "witch",
    },
    {
        "offer_id": "upgrade_survival",
        "type": "upgrade",
        "name": "Survival Capacity +12% HP",
        "base_price": 55,
        "price_scale": 1.30,
        "limit": 3,
        "effect": {"max_hp_percent": 0.12},
        "vendor": "witch",
    },
    {
        "offer_id": "upgrade_resource_cycle",
        "type": "upgrade",
        "name": "Resource Cycle +10%",
        "base_price": 50,
        "price_scale": 1.25,
        "limit": 3,
        "effect": {"stamina_recover_percent": 0.10},
        "vendor": "witch",
    },
    {
        "offer_id": "upgrade_economy",
        "type": "upgrade",
        "name": "Yield Efficiency +8%",
        "base_price": 70,
        "price_scale": 1.40,
        "limit": 1,
        "effect": {"xp_gain_multiplier": 1.08, "gold_gain_multiplier": 1.08},
        "vendor": "witch",
    },
]

const TRAVELER_ITEM_POOL: Array[Dictionary] = [
    {
        "offer_id": "item_damage_module",
        "type": "item",
        "name": "Damage Module",
        "base_price": 70,
        "price_scale": 1.0,
        "limit": 1,
        "effect": {"bonus_attack_damage": 2},
        "vendor": "traveler",
    },
    {
        "offer_id": "item_shield_pack",
        "type": "item",
        "name": "Shield Pack (next stage HP +20)",
        "base_price": 60,
        "price_scale": 1.0,
        "limit": 1,
        "effect": {"next_stage_bonus_heal_flat": 20},
        "vendor": "traveler",
    },
    {
        "offer_id": "item_emergency_medkit",
        "type": "item",
        "name": "Emergency Medkit (next stage HP +35%)",
        "base_price": 65,
        "price_scale": 1.0,
        "limit": 1,
        "effect": {"next_stage_bonus_heal_percent": 0.35},
        "vendor": "traveler",
    },
    {
        "offer_id": "item_rift_boots",
        "type": "item",
        "name": "Rift Boots (+18 Move Speed)",
        "base_price": 55,
        "price_scale": 1.0,
        "limit": 1,
        "effect": {"player_move_speed": 18.0},
        "vendor": "traveler",
    },
    {
        "offer_id": "item_focus_chip",
        "type": "item",
        "name": "Focus Chip (+60 Target Range)",
        "base_price": 75,
        "price_scale": 1.0,
        "limit": 1,
        "effect": {"bonus_target_range": 60.0},
        "vendor": "traveler",
    },
]

const SEER_OFFERS: Array[Dictionary] = [
    {
        "offer_id": "seer_bias_output",
        "type": "seer_bias",
        "name": "Seer: Bias Output",
        "base_price": 75,
        "price_scale": 1.0,
        "limit": 1,
        "effect": {"set_reward_bias": "output", "uses": 2},
        "vendor": "seer",
    },
    {
        "offer_id": "seer_bias_survival",
        "type": "seer_bias",
        "name": "Seer: Bias Survival",
        "base_price": 75,
        "price_scale": 1.0,
        "limit": 1,
        "effect": {"set_reward_bias": "survival", "uses": 2},
        "vendor": "seer",
    },
    {
        "offer_id": "seer_bias_economy",
        "type": "seer_bias",
        "name": "Seer: Bias Economy",
        "base_price": 70,
        "price_scale": 1.0,
        "limit": 1,
        "effect": {"set_reward_bias": "economy", "uses": 2},
        "vendor": "seer",
    },
]

const BROKER_OFFERS: Array[Dictionary] = [
    {
        "offer_id": "broker_contract_greedy",
        "type": "contract",
        "name": "Broker Contract: Greedy",
        "base_price": 0,
        "price_scale": 1.0,
        "limit": 1,
        "effect": {
            "set_contract_modifier": {
                "enemy_damage_mult": 1.10,
                "gold_gain_mult": 1.25,
                "label": "Greedy Contract",
            }
        },
        "vendor": "broker",
    },
    {
        "offer_id": "broker_contract_pressure",
        "type": "contract",
        "name": "Broker Contract: Pressure",
        "base_price": 0,
        "price_scale": 1.0,
        "limit": 1,
        "effect": {
            "set_contract_modifier": {
                "enemy_hp_mult": 1.12,
                "xp_gain_mult": 1.20,
                "label": "Pressure Contract",
            }
        },
        "vendor": "broker",
    },
]

const CORE_VENDOR_IDS: PackedStringArray = ["witch", "traveler", "seer", "broker"]

func _ready() -> void:
    randomize()
    if not _resolve_ui_refs():
        set_process(false)
        return
    if close_vendor_button != null:
        close_vendor_button.pressed.connect(_close_vendor_panel)
    if refresh_button != null:
        refresh_button.visible = false
    if leave_button != null:
        leave_button.pressed.connect(_on_leave_pressed)
    if leave_confirm != null:
        leave_confirm.confirmed.connect(_on_leave_confirmed)
    if witch_area != null:
        witch_area.body_entered.connect(_on_witch_body_entered)
        witch_area.body_exited.connect(_on_witch_body_exited)
    if traveler_area != null:
        traveler_area.body_entered.connect(_on_traveler_body_entered)
        traveler_area.body_exited.connect(_on_traveler_body_exited)
    if seer_area != null:
        seer_area.body_entered.connect(_on_seer_body_entered)
        seer_area.body_exited.connect(_on_seer_body_exited)
    if broker_area != null:
        broker_area.body_entered.connect(_on_broker_body_entered)
        broker_area.body_exited.connect(_on_broker_body_exited)

    _run_state = _build_initial_run_state(GameManager.consume_pending_hub_snapshot())
    _vendor_core_purchases = _normalize_vendor_core_purchases(_run_state.get("npc_core_purchases", {}))
    _run_state["npc_core_purchases"] = _vendor_core_purchases.duplicate(true)
    _spawn_player(str(_run_state.get("character_id", "the_fool")))
    _apply_player_state_to_instance()
    _build_vendor_offers()
    _close_vendor_panel()
    _refresh_status_ui(_tx("msg.hub.ready", "Supply Hub ready"))

func _process(delta: float) -> void:
    _interact_cooldown_timer = max(0.0, _interact_cooldown_timer - delta)
    _constrain_player_to_hub()
    _update_vendor_proximity_state()
    if not _active_vendor.is_empty():
        return
    if _interact_cooldown_timer > 0.0:
        return
    if not _is_interact_pressed():
        return
    if not _can_open_vendor():
        _refresh_status_ui(_tx("msg.hub.move_closer_short", "Move closer to a vendor and press E"))
        _interact_cooldown_timer = INTERACT_COOLDOWN_SEC
        return
    _open_nearest_vendor()
    _interact_cooldown_timer = INTERACT_COOLDOWN_SEC

func _unhandled_input(event: InputEvent) -> void:
    if _active_vendor.is_empty():
        return
    if event.is_action_pressed("cancel"):
        _close_vendor_panel()
        get_viewport().set_input_as_handled()

func _build_initial_run_state(snapshot: Dictionary) -> Dictionary:
    var normalized: Dictionary = {
        "source_stage_id": "stage_005",
        "character_id": "the_fool",
        "difficulty": GameManager.current_difficulty,
        "current_gold": 0,
        "player_hp": 100,
        "player_max_hp": 100,
        "player_move_speed": 220.0,
        "player_stamina_max": 100.0,
        "player_stamina_recover_per_sec": 26.0,
        "bonus_target_range": 0.0,
        "bonus_attack_damage": 0,
        "current_level": 1,
        "current_xp": 0,
        "xp_to_next_level": 20,
        "auto_attack_interval_multiplier": 1.0,
        "xp_gain_multiplier": 1.0,
        "gold_gain_multiplier": 1.0,
        "hub_actions": [],
        "purchased_offers": {},
        "npc_core_purchases": {},
        "refresh_count": 0,
        "hub_effects": {},
        "seer_bias_category": "",
        "seer_bias_remaining": 0,
        "broker_contract": {},
        "broker_contract_active_stage": "",
    }
    for key: String in snapshot.keys():
        normalized[key] = snapshot[key]
    normalized["current_gold"] = max(0, int(normalized.get("current_gold", 0)))
    normalized["refresh_count"] = clampi(int(normalized.get("refresh_count", 0)), 0, MAX_REFRESH_COUNT)
    if not (normalized.get("purchased_offers", {}) is Dictionary):
        normalized["purchased_offers"] = {}
    if not (normalized.get("hub_actions", []) is Array):
        normalized["hub_actions"] = []
    if not (normalized.get("hub_effects", {}) is Dictionary):
        normalized["hub_effects"] = {}
    if not (normalized.get("broker_contract", {}) is Dictionary):
        normalized["broker_contract"] = {}
    normalized["seer_bias_category"] = str(normalized.get("seer_bias_category", ""))
    normalized["seer_bias_remaining"] = max(0, int(normalized.get("seer_bias_remaining", 0)))
    normalized["broker_contract_active_stage"] = str(normalized.get("broker_contract_active_stage", ""))
    return normalized

func _spawn_player(character_id: String) -> void:
    var selected_id: String = character_id
    if selected_id.is_empty():
        selected_id = "the_fool"
    var script_resource: Script = PLAYER_SCRIPT_MAP["the_fool"]
    if PLAYER_SCRIPT_MAP.has(selected_id):
        script_resource = PLAYER_SCRIPT_MAP[selected_id]

    _player = script_resource.new()
    _player.global_position = Vector2(0, 0)
    if world_root != null:
        world_root.add_child(_player)
    else:
        add_child(_player)

    _hub_camera = Camera2D.new()
    _hub_camera.enabled = true
    _hub_camera.position_smoothing_enabled = true
    _hub_camera.position_smoothing_speed = 8.0
    _hub_camera.zoom = HUB_CAMERA_ZOOM
    _player.add_child(_hub_camera)

func _apply_player_state_to_instance() -> void:
    if _player == null or not is_instance_valid(_player):
        return
    _player.max_hp = max(1, int(_run_state.get("player_max_hp", _player.max_hp)))
    _player.current_hp = clampi(int(_run_state.get("player_hp", _player.max_hp)), 0, _player.max_hp)
    _player.move_speed = float(_run_state.get("player_move_speed", _player.move_speed))
    _player.stamina_max = max(1.0, float(_run_state.get("player_stamina_max", _player.stamina_max)))
    _player.current_stamina = _player.stamina_max
    _player.stamina_recover_per_sec = max(1.0, float(_run_state.get("player_stamina_recover_per_sec", _player.stamina_recover_per_sec)))
    _player.bonus_target_range = float(_run_state.get("bonus_target_range", _player.bonus_target_range))
    _player.bonus_attack_damage = int(_run_state.get("bonus_attack_damage", _player.bonus_attack_damage))

func _build_vendor_offers() -> void:
    _vendor_offers = {
        "witch": [],
        "traveler": [],
        "seer": [],
        "broker": [],
    }
    var witch_offers: Array[Dictionary] = []
    for offer: Dictionary in RECOVER_OFFERS:
        witch_offers.append(offer.duplicate(true))
    for offer: Dictionary in UPGRADE_OFFERS:
        witch_offers.append(offer.duplicate(true))
    _vendor_offers["witch"] = witch_offers
    _vendor_offers["traveler"] = _roll_traveler_offers()
    _vendor_offers["seer"] = _clone_offer_templates(SEER_OFFERS)
    _vendor_offers["broker"] = _clone_offer_templates(BROKER_OFFERS)

func _roll_traveler_offers() -> Array[Dictionary]:
    var pool: Array[Dictionary] = []
    for template: Dictionary in TRAVELER_ITEM_POOL:
        pool.append(template.duplicate(true))
    pool.shuffle()
    var result: Array[Dictionary] = []
    var take_count: int = min(3, pool.size())
    for i: int in range(take_count):
        result.append(pool[i])
    return result

func _clone_offer_templates(source: Array[Dictionary]) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for offer: Dictionary in source:
        result.append(offer.duplicate(true))
    return result

func _open_nearest_vendor() -> void:
    var open_vendor: String = _get_nearest_vendor_in_range()
    if open_vendor.is_empty():
        return
    _active_vendor = open_vendor
    _set_player_movement_enabled(false)
    _rebuild_vendor_panel()

func _close_vendor_panel() -> void:
    _active_vendor = ""
    if vendor_panel != null:
        vendor_panel.visible = false
    _set_player_movement_enabled(true)
    _refresh_interact_hint()

func _rebuild_vendor_panel() -> void:
    if vendor_panel == null or vendor_title == null or offer_list == null:
        return
    vendor_panel.visible = true
    match _active_vendor:
        "witch":
            vendor_title.text = _tx("ui.hub.vendor.witch", "WITCH - Recover & Upgrade")
        "traveler":
            vendor_title.text = _tx("ui.hub.vendor.traveler", "TRAVELER - Shop")
        "seer":
            vendor_title.text = _tx("ui.hub.vendor.seer", "SEER - Build Bias")
        "broker":
            vendor_title.text = _tx("ui.hub.vendor.broker", "BROKER - Contracts")
        _:
            vendor_title.text = _tx("ui.hub.vendor.default", "VENDOR")

    for child: Node in offer_list.get_children():
        child.queue_free()

    var offers: Array = _vendor_offers.get(_active_vendor, [])
    var vendor_locked: bool = _vendor_has_core_purchase(_active_vendor)
    if _active_vendor == "traveler":
        var traveler_refresh_button: Button = Button.new()
        traveler_refresh_button.custom_minimum_size = Vector2(0, 42)
        traveler_refresh_button.focus_mode = Control.FOCUS_NONE
        var refresh_count: int = int(_run_state.get("refresh_count", 0))
        var refresh_price: int = BASE_REFRESH_PRICE + REFRESH_PRICE_STEP * refresh_count
        traveler_refresh_button.text = _tf("ui.hub.refresh_fmt", [refresh_count, MAX_REFRESH_COUNT, refresh_price], "Refresh Shop (%d/%d) - %dG")
        traveler_refresh_button.disabled = (
            vendor_locked
            or refresh_count >= MAX_REFRESH_COUNT
            or int(_run_state.get("current_gold", 0)) < refresh_price
        )
        traveler_refresh_button.pressed.connect(_on_refresh_pressed)
        offer_list.add_child(traveler_refresh_button)

    for offer_value: Variant in offers:
        if not (offer_value is Dictionary):
            continue
        var offer: Dictionary = offer_value
        var button: Button = Button.new()
        button.custom_minimum_size = Vector2(0, 42)
        button.focus_mode = Control.FOCUS_NONE
        var price: int = _resolve_offer_price(offer)
        var bought_count: int = _get_purchase_count(str(offer.get("offer_id", "")))
        var limit: int = max(1, int(offer.get("limit", 1)))
        button.text = "%s | %dG | %d/%d" % [_offer_name(offer), price, bought_count, limit]
        button.disabled = vendor_locked or bought_count >= limit or int(_run_state.get("current_gold", 0)) < price
        button.pressed.connect(_on_offer_pressed.bind(str(offer.get("offer_id", ""))))
        offer_list.add_child(button)

    _refresh_status_ui(_tf("msg.hub.browsing_fmt", [_vendor_name(_active_vendor)], "Browsing %s"))

func _on_offer_pressed(offer_id: String) -> void:
    if _vendor_has_core_purchase(_active_vendor):
        _refresh_status_ui(_tx("msg.hub.vendor_exhausted", "This vendor is exhausted for this hub"))
        _rebuild_vendor_panel()
        return
    var offer: Dictionary = _find_offer(_active_vendor, offer_id)
    if offer.is_empty():
        return
    var price: int = _resolve_offer_price(offer)
    var gold: int = int(_run_state.get("current_gold", 0))
    if gold < price:
        _refresh_status_ui(_tf("msg.shop.not_enough_gold_need_fmt", [price - gold], "Not enough gold: need %d more"))
        _rebuild_vendor_panel()
        return

    _run_state["current_gold"] = gold - price
    _increment_purchase_count(offer_id)
    _increment_vendor_core_purchase(_active_vendor)
    _append_hub_action("buy:%s:%d" % [offer_id, price])
    _apply_offer_effect(offer)

    _refresh_status_ui(_tf("msg.hub.purchased_fmt", [_offer_name(offer)], "Purchased %s"))
    _rebuild_vendor_panel()

func _apply_offer_effect(offer: Dictionary) -> void:
    var offer_type: String = str(offer.get("type", ""))
    if offer_type == "recover":
        var heal_percent: float = float(offer.get("heal_percent", 0.0))
        var heal_amount: int = int(round(float(_player.max_hp) * heal_percent))
        _player.current_hp = clampi(_player.current_hp + heal_amount, 0, _player.max_hp)
        _run_state["player_hp"] = _player.current_hp
        return

    var effect: Dictionary = {}
    var effect_value: Variant = offer.get("effect", {})
    if effect_value is Dictionary:
        effect = effect_value

    if effect.has("set_reward_bias"):
        var bias_tag: String = str(effect.get("set_reward_bias", ""))
        var bias_uses: int = max(1, int(effect.get("uses", 2)))
        _run_state["seer_bias_category"] = bias_tag
        _run_state["seer_bias_remaining"] = bias_uses

    if effect.has("set_contract_modifier"):
        var contract_value: Variant = effect.get("set_contract_modifier", {})
        if contract_value is Dictionary:
            var source_stage_id: String = str(_run_state.get("source_stage_id", "stage_001"))
            _run_state["broker_contract"] = contract_value.duplicate(true)
            _run_state["broker_contract_active_stage"] = _calculate_next_stage_id(source_stage_id)

    if effect.has("bonus_attack_damage"):
        var bonus_damage: int = int(effect.get("bonus_attack_damage", 0))
        _run_state["bonus_attack_damage"] = int(_run_state.get("bonus_attack_damage", 0)) + bonus_damage

    if effect.has("bonus_target_range"):
        var bonus_range: float = float(effect.get("bonus_target_range", 0.0))
        _run_state["bonus_target_range"] = float(_run_state.get("bonus_target_range", 0.0)) + bonus_range

    if effect.has("player_move_speed"):
        var move_speed_bonus: float = float(effect.get("player_move_speed", 0.0))
        _run_state["player_move_speed"] = float(_run_state.get("player_move_speed", 220.0)) + move_speed_bonus

    if effect.has("max_hp_percent"):
        var hp_scale: float = 1.0 + float(effect.get("max_hp_percent", 0.0))
        var new_max_hp: int = max(1, int(round(float(_run_state.get("player_max_hp", _player.max_hp)) * hp_scale)))
        _run_state["player_max_hp"] = new_max_hp
        _run_state["player_hp"] = clampi(int(_run_state.get("player_hp", _player.current_hp)) + int(round(float(new_max_hp) * 0.12)), 0, new_max_hp)

    if effect.has("stamina_recover_percent"):
        var stamina_scale: float = 1.0 + float(effect.get("stamina_recover_percent", 0.0))
        _run_state["player_stamina_recover_per_sec"] = float(_run_state.get("player_stamina_recover_per_sec", _player.stamina_recover_per_sec)) * stamina_scale

    if effect.has("auto_attack_interval_multiplier"):
        var current_mul: float = clampf(float(_run_state.get("auto_attack_interval_multiplier", 1.0)), 0.45, 1.0)
        var mul: float = clampf(float(effect.get("auto_attack_interval_multiplier", 1.0)), 0.45, 1.0)
        _run_state["auto_attack_interval_multiplier"] = clampf(current_mul * mul, 0.45, 1.0)

    if effect.has("xp_gain_multiplier"):
        var xp_mul: float = max(1.0, float(effect.get("xp_gain_multiplier", 1.0)))
        _run_state["xp_gain_multiplier"] = float(_run_state.get("xp_gain_multiplier", 1.0)) * xp_mul

    if effect.has("gold_gain_multiplier"):
        var gold_mul: float = max(1.0, float(effect.get("gold_gain_multiplier", 1.0)))
        _run_state["gold_gain_multiplier"] = float(_run_state.get("gold_gain_multiplier", 1.0)) * gold_mul

    var hub_effects: Dictionary = _run_state.get("hub_effects", {})
    if effect.has("next_stage_bonus_heal_flat"):
        hub_effects["next_stage_bonus_heal_flat"] = int(hub_effects.get("next_stage_bonus_heal_flat", 0)) + int(effect.get("next_stage_bonus_heal_flat", 0))
    if effect.has("next_stage_bonus_heal_percent"):
        hub_effects["next_stage_bonus_heal_percent"] = float(hub_effects.get("next_stage_bonus_heal_percent", 0.0)) + float(effect.get("next_stage_bonus_heal_percent", 0.0))
    _run_state["hub_effects"] = hub_effects

    _apply_player_state_to_instance()

func _resolve_offer_price(offer: Dictionary) -> int:
    var offer_id: String = str(offer.get("offer_id", ""))
    var bought_count: int = _get_purchase_count(offer_id)
    var base_price: float = float(offer.get("base_price", 0))
    var price_scale: float = float(offer.get("price_scale", 1.0))
    var price: int = int(round(base_price * pow(price_scale, bought_count)))
    return max(1, price)

func _find_offer(vendor_id: String, offer_id: String) -> Dictionary:
    var offers: Array = _vendor_offers.get(vendor_id, [])
    for offer_value: Variant in offers:
        if offer_value is Dictionary:
            var offer: Dictionary = offer_value
            if str(offer.get("offer_id", "")) == offer_id:
                return offer
    return {}

func _get_purchase_count(offer_id: String) -> int:
    var purchased_value: Variant = _run_state.get("purchased_offers", {})
    if purchased_value is Dictionary:
        var purchased: Dictionary = purchased_value
        return max(0, int(purchased.get(offer_id, 0)))
    return 0

func _increment_purchase_count(offer_id: String) -> void:
    var purchased_value: Variant = _run_state.get("purchased_offers", {})
    var purchased: Dictionary = {}
    if purchased_value is Dictionary:
        purchased = purchased_value
    purchased[offer_id] = _get_purchase_count(offer_id) + 1
    _run_state["purchased_offers"] = purchased

func _normalize_vendor_core_purchases(raw_value: Variant) -> Dictionary:
    var normalized: Dictionary = {}
    if raw_value is Dictionary:
        var raw_dict: Dictionary = raw_value
        for vendor_id: String in CORE_VENDOR_IDS:
            normalized[vendor_id] = max(0, int(raw_dict.get(vendor_id, 0)))
    else:
        for vendor_id: String in CORE_VENDOR_IDS:
            normalized[vendor_id] = 0
    return normalized

func _vendor_has_core_purchase(vendor_id: String) -> bool:
    if vendor_id.is_empty():
        return false
    return int(_vendor_core_purchases.get(vendor_id, 0)) >= 1

func _increment_vendor_core_purchase(vendor_id: String) -> void:
    if vendor_id.is_empty():
        return
    _vendor_core_purchases[vendor_id] = int(_vendor_core_purchases.get(vendor_id, 0)) + 1
    _run_state["npc_core_purchases"] = _vendor_core_purchases.duplicate(true)

func _append_hub_action(action: String) -> void:
    var actions: Array[String] = []
    var actions_value: Variant = _run_state.get("hub_actions", [])
    if actions_value is Array:
        var raw_actions: Array = actions_value
        for value: Variant in raw_actions:
            actions.append(str(value))
    actions.append(action)
    _run_state["hub_actions"] = actions

func _on_refresh_pressed() -> void:
    if _active_vendor != "traveler":
        _refresh_status_ui(_tx("msg.hub.refresh_only_traveler", "Traveler refresh is only available in Traveler shop"))
        return
    var refresh_count: int = int(_run_state.get("refresh_count", 0))
    if refresh_count >= MAX_REFRESH_COUNT:
        _refresh_status_ui(_tx("msg.hub.refresh_limit", "Refresh limit reached"))
        return
    var price: int = BASE_REFRESH_PRICE + REFRESH_PRICE_STEP * refresh_count
    var gold: int = int(_run_state.get("current_gold", 0))
    if gold < price:
        _refresh_status_ui(_tx("msg.shop.not_enough_gold_refresh", "Not enough gold to refresh"))
        return
    _run_state["current_gold"] = gold - price
    _run_state["refresh_count"] = refresh_count + 1
    _append_hub_action("refresh:%d" % [price])
    _vendor_offers["traveler"] = _roll_traveler_offers()
    _refresh_status_ui(_tx("msg.hub.traveler_refreshed", "Traveler stock refreshed"))
    if not _active_vendor.is_empty():
        _rebuild_vendor_panel()
    else:
        _refresh_interact_hint()

func _on_leave_pressed() -> void:
    if leave_confirm == null:
        return
    leave_confirm.dialog_text = _tx("msg.hub.leave_confirm", "Leave Supply Hub? You cannot return to this hub.")
    leave_confirm.popup_centered(Vector2i(460, 160))

func _on_leave_confirmed() -> void:
    _run_state["player_hp"] = _player.current_hp
    _run_state["player_max_hp"] = _player.max_hp
    _run_state["player_move_speed"] = _player.move_speed
    _run_state["player_stamina_max"] = _player.stamina_max
    _run_state["player_stamina_recover_per_sec"] = _player.stamina_recover_per_sec
    _run_state["bonus_target_range"] = _player.bonus_target_range
    _run_state["bonus_attack_damage"] = _player.bonus_attack_damage
    GameManager.continue_from_hub(_run_state)

func _set_player_movement_enabled(enabled: bool) -> void:
    if _player == null or not is_instance_valid(_player):
        return
    _player.set_physics_process(enabled)
    if not enabled:
        _player.velocity = Vector2.ZERO

func _can_open_vendor() -> bool:
    return not _get_nearest_vendor_in_range().is_empty()

func _is_interact_pressed() -> bool:
    return Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("ui_accept")

func _calculate_next_stage_id(stage_id: String) -> String:
    if not stage_id.begins_with("stage_"):
        return ""
    var suffix: String = stage_id.trim_prefix("stage_")
    if not suffix.is_valid_int():
        return ""
    var stage_number: int = int(suffix)
    if stage_number <= 0:
        return ""
    return "stage_%03d" % [stage_number + 1]

func _refresh_status_ui(status_text: String) -> void:
    if gold_label == null or gold_gain_label == null or status_label == null or refresh_button == null:
        return
    var refresh_count: int = int(_run_state.get("refresh_count", 0))
    var refresh_price: int = BASE_REFRESH_PRICE + REFRESH_PRICE_STEP * refresh_count
    var gold_gain_multiplier: float = max(0.1, float(_run_state.get("gold_gain_multiplier", 1.0)))
    var gold_gain_bonus_percent: int = int(round((gold_gain_multiplier - 1.0) * 100.0))
    var gold_gain_bonus_text: String = "%d%%" % gold_gain_bonus_percent
    if gold_gain_bonus_percent > 0:
        gold_gain_bonus_text = "+%d%%" % gold_gain_bonus_percent
    gold_label.text = _tf("ui.shop.gold_fmt", [int(_run_state.get("current_gold", 0))], "Gold: %d")
    gold_gain_label.text = _tf("ui.hub.gold_gain_fmt", [gold_gain_multiplier, gold_gain_bonus_text], "Gold Gain: x%.2f (%s)")
    status_label.text = status_text
    refresh_button.disabled = refresh_count >= MAX_REFRESH_COUNT or int(_run_state.get("current_gold", 0)) < refresh_price
    refresh_button.text = _tf("ui.hub.refresh_fmt", [refresh_count, MAX_REFRESH_COUNT, refresh_price], "Refresh Shop (%d/%d) - %dG")
    _refresh_interact_hint()

func _refresh_interact_hint() -> void:
    if hint_label == null or world_hint_label == null:
        return
    if not _active_vendor.is_empty():
        hint_label.text = _tf("msg.hub.browsing_action_fmt", [_vendor_name(_active_vendor)], "Browsing %s. Purchase or close panel.")
        world_hint_label.visible = false
        return
    if _in_witch_range:
        hint_label.text = _tx("msg.hub.press_e_witch", "Press E to trade with Witch")
        world_hint_label.visible = true
        world_hint_label.text = _tx("ui.hub.world_hint_witch", "[E] Witch")
        return
    if _in_traveler_range:
        hint_label.text = _tx("msg.hub.press_e_traveler", "Press E to trade with Rift Traveler")
        world_hint_label.visible = true
        world_hint_label.text = _tx("ui.hub.world_hint_traveler", "[E] Traveler")
        return
    if _in_seer_range:
        hint_label.text = _tx("msg.hub.press_e_seer", "Press E to consult Seer")
        world_hint_label.visible = true
        world_hint_label.text = _tx("ui.hub.world_hint_seer", "[E] Seer")
        return
    if _in_broker_range:
        hint_label.text = _tx("msg.hub.press_e_broker", "Press E to negotiate Broker")
        world_hint_label.visible = true
        world_hint_label.text = _tx("ui.hub.world_hint_broker", "[E] Broker")
        return
    var nearest_distance: float = _get_nearest_vendor_distance()
    if nearest_distance >= 0.0:
        hint_label.text = _tf("msg.hub.move_closer_distance_fmt", [nearest_distance], "Move closer to a vendor and press E (%.0f)")
    else:
        hint_label.text = _tx("msg.hub.move_to_vendor", "Move to a vendor and press E to interact")
    world_hint_label.visible = false

func _on_witch_body_entered(body: Node) -> void:
    if body == _player:
        _in_witch_range = true
        if _active_vendor.is_empty():
            _refresh_status_ui(_tx("msg.hub.near_witch", "Near Witch"))

func _on_witch_body_exited(body: Node) -> void:
    if body == _player:
        _in_witch_range = false
        if _active_vendor == "witch":
            _close_vendor_panel()
        elif _active_vendor.is_empty():
            _refresh_status_ui(_tx("msg.hub.left_witch", "Left Witch"))

func _on_traveler_body_entered(body: Node) -> void:
    if body == _player:
        _in_traveler_range = true
        if _active_vendor.is_empty():
            _refresh_status_ui(_tx("msg.hub.near_traveler", "Near Traveler"))

func _on_traveler_body_exited(body: Node) -> void:
    if body == _player:
        _in_traveler_range = false
        if _active_vendor == "traveler":
            _close_vendor_panel()
        elif _active_vendor.is_empty():
            _refresh_status_ui(_tx("msg.hub.left_traveler", "Left Traveler"))

func _on_seer_body_entered(body: Node) -> void:
    if body == _player:
        _in_seer_range = true
        if _active_vendor.is_empty():
            _refresh_status_ui(_tx("msg.hub.near_seer", "Near Seer"))

func _on_seer_body_exited(body: Node) -> void:
    if body == _player:
        _in_seer_range = false
        if _active_vendor == "seer":
            _close_vendor_panel()
        elif _active_vendor.is_empty():
            _refresh_status_ui(_tx("msg.hub.left_seer", "Left Seer"))

func _on_broker_body_entered(body: Node) -> void:
    if body == _player:
        _in_broker_range = true
        if _active_vendor.is_empty():
            _refresh_status_ui(_tx("msg.hub.near_broker", "Near Broker"))

func _on_broker_body_exited(body: Node) -> void:
    if body == _player:
        _in_broker_range = false
        if _active_vendor == "broker":
            _close_vendor_panel()
        elif _active_vendor.is_empty():
            _refresh_status_ui(_tx("msg.hub.left_broker", "Left Broker"))

func _resolve_ui_refs() -> bool:
    world_root = get_node_or_null(PATH_WORLD_ROOT) as Node2D
    gold_label = get_node_or_null(PATH_GOLD_LABEL) as Label
    gold_gain_label = get_node_or_null(PATH_GOLD_GAIN_LABEL) as Label
    hint_label = get_node_or_null(PATH_HINT_LABEL) as Label
    vendor_panel = get_node_or_null(PATH_VENDOR_PANEL) as PanelContainer
    vendor_title = get_node_or_null(PATH_VENDOR_TITLE) as Label
    offer_list = get_node_or_null(PATH_OFFER_LIST) as VBoxContainer
    close_vendor_button = get_node_or_null(PATH_CLOSE_VENDOR_BUTTON) as Button
    refresh_button = get_node_or_null(PATH_REFRESH_BUTTON) as Button
    leave_button = get_node_or_null(PATH_LEAVE_BUTTON) as Button
    leave_confirm = get_node_or_null(PATH_LEAVE_CONFIRM) as ConfirmationDialog
    witch_area = get_node_or_null(PATH_WITCH_AREA) as Area2D
    traveler_area = get_node_or_null(PATH_TRAVELER_AREA) as Area2D
    seer_area = get_node_or_null(PATH_SEER_AREA) as Area2D
    broker_area = get_node_or_null(PATH_BROKER_AREA) as Area2D
    witch_anchor = get_node_or_null(PATH_WITCH_ANCHOR) as Node2D
    traveler_anchor = get_node_or_null(PATH_TRAVELER_ANCHOR) as Node2D
    seer_anchor = get_node_or_null(PATH_SEER_ANCHOR) as Node2D
    broker_anchor = get_node_or_null(PATH_BROKER_ANCHOR) as Node2D
    world_hint_label = get_node_or_null(PATH_WORLD_HINT_LABEL) as Label
    status_label = get_node_or_null(PATH_STATUS_LABEL) as Label

    var missing: Array[String] = []
    if world_root == null:
        missing.append("GameWorldRoot")
    if gold_label == null:
        missing.append("GoldLabel")
    if gold_gain_label == null:
        missing.append("GoldGainLabel")
    if hint_label == null:
        missing.append("HintLabel")
    if vendor_panel == null:
        missing.append("VendorPanel")
    if vendor_title == null:
        missing.append("VendorTitle")
    if offer_list == null:
        missing.append("OfferList")
    if close_vendor_button == null:
        missing.append("CloseVendorButton")
    if refresh_button == null:
        missing.append("RefreshButton")
    if leave_button == null:
        missing.append("LeaveButton")
    if leave_confirm == null:
        missing.append("LeaveConfirmDialog")
    if witch_area == null:
        missing.append("WitchArea")
    if traveler_area == null:
        missing.append("TravelerArea")
    if seer_area == null:
        missing.append("SeerArea")
    if broker_area == null:
        missing.append("BrokerArea")
    if witch_anchor == null:
        missing.append("WitchAnchor")
    if traveler_anchor == null:
        missing.append("TravelerAnchor")
    if seer_anchor == null:
        missing.append("SeerAnchor")
    if broker_anchor == null:
        missing.append("BrokerAnchor")
    if world_hint_label == null:
        missing.append("WorldHintLabel")
    if status_label == null:
        missing.append("StatusLabel")
    if missing.is_empty():
        return true

    push_error("SupplyHub UI binding failed: %s" % ", ".join(missing))
    return false

func _update_vendor_proximity_state() -> void:
    if _player == null or not is_instance_valid(_player):
        return
    if witch_anchor == null or traveler_anchor == null or seer_anchor == null or broker_anchor == null:
        return

    var witch_distance: float = _player.global_position.distance_to(witch_anchor.global_position)
    var traveler_distance: float = _player.global_position.distance_to(traveler_anchor.global_position)
    var seer_distance: float = _player.global_position.distance_to(seer_anchor.global_position)
    var broker_distance: float = _player.global_position.distance_to(broker_anchor.global_position)
    var previous_witch_range: bool = _in_witch_range
    var previous_traveler_range: bool = _in_traveler_range
    var previous_seer_range: bool = _in_seer_range
    var previous_broker_range: bool = _in_broker_range

    _in_witch_range = witch_distance <= (INTERACT_EXIT_RADIUS if _in_witch_range else INTERACT_ENTER_RADIUS)
    _in_traveler_range = traveler_distance <= (INTERACT_EXIT_RADIUS if _in_traveler_range else INTERACT_ENTER_RADIUS)
    _in_seer_range = seer_distance <= (INTERACT_EXIT_RADIUS if _in_seer_range else INTERACT_ENTER_RADIUS)
    _in_broker_range = broker_distance <= (INTERACT_EXIT_RADIUS if _in_broker_range else INTERACT_ENTER_RADIUS)

    if _active_vendor == "witch" and not _in_witch_range:
        _close_vendor_panel()
        return
    if _active_vendor == "traveler" and not _in_traveler_range:
        _close_vendor_panel()
        return
    if _active_vendor == "seer" and not _in_seer_range:
        _close_vendor_panel()
        return
    if _active_vendor == "broker" and not _in_broker_range:
        _close_vendor_panel()
        return

    if _active_vendor.is_empty() and (
        _in_witch_range != previous_witch_range
        or _in_traveler_range != previous_traveler_range
        or _in_seer_range != previous_seer_range
        or _in_broker_range != previous_broker_range
    ):
        _refresh_interact_hint()

func _get_nearest_vendor_in_range() -> String:
    if _player == null or not is_instance_valid(_player):
        return ""
    if witch_anchor == null or traveler_anchor == null or seer_anchor == null or broker_anchor == null:
        return ""
    var candidates: Array[Dictionary] = []
    if _in_witch_range:
        candidates.append({"vendor": "witch", "distance": _player.global_position.distance_to(witch_anchor.global_position)})
    if _in_traveler_range:
        candidates.append({"vendor": "traveler", "distance": _player.global_position.distance_to(traveler_anchor.global_position)})
    if _in_seer_range:
        candidates.append({"vendor": "seer", "distance": _player.global_position.distance_to(seer_anchor.global_position)})
    if _in_broker_range:
        candidates.append({"vendor": "broker", "distance": _player.global_position.distance_to(broker_anchor.global_position)})
    if candidates.is_empty():
        return ""
    candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        return float(a.get("distance", 999999.0)) < float(b.get("distance", 999999.0))
    )
    return str(candidates[0].get("vendor", ""))

func _get_nearest_vendor_distance() -> float:
    if _player == null or not is_instance_valid(_player):
        return -1.0
    if witch_anchor == null or traveler_anchor == null or seer_anchor == null or broker_anchor == null:
        return -1.0
    var witch_distance: float = _player.global_position.distance_to(witch_anchor.global_position)
    var traveler_distance: float = _player.global_position.distance_to(traveler_anchor.global_position)
    var seer_distance: float = _player.global_position.distance_to(seer_anchor.global_position)
    var broker_distance: float = _player.global_position.distance_to(broker_anchor.global_position)
    return min(witch_distance, min(traveler_distance, min(seer_distance, broker_distance)))

func _constrain_player_to_hub() -> void:
    if _player == null or not is_instance_valid(_player):
        return
    var body_padding: float = max(HUB_EDGE_PADDING, _player.body_radius + 2.0)
    var min_x: float = -HUB_HALF_EXTENTS.x + body_padding
    var max_x: float = HUB_HALF_EXTENTS.x - body_padding
    var min_y: float = -HUB_HALF_EXTENTS.y + body_padding
    var max_y: float = HUB_HALF_EXTENTS.y - body_padding
    var clamped_x: float = clampf(_player.global_position.x, min_x, max_x)
    var clamped_y: float = clampf(_player.global_position.y, min_y, max_y)
    if not is_equal_approx(clamped_x, _player.global_position.x) or not is_equal_approx(clamped_y, _player.global_position.y):
        _player.global_position = Vector2(clamped_x, clamped_y)

func _offer_name(offer: Dictionary) -> String:
    var offer_id: String = str(offer.get("offer_id", ""))
    return LocaleService.t_data("hub_offer", offer_id, "name", str(offer.get("name", "Offer")))

func _vendor_name(vendor_id: String) -> String:
    match vendor_id:
        "witch":
            return _tx("ui.hub.vendor_short.witch", "Witch")
        "traveler":
            return _tx("ui.hub.vendor_short.traveler", "Traveler")
        "seer":
            return _tx("ui.hub.vendor_short.seer", "Seer")
        "broker":
            return _tx("ui.hub.vendor_short.broker", "Broker")
        _:
            return _tx("ui.hub.vendor_short.default", "Vendor")

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
