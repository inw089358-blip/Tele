class_name ShopSystem
extends RefCounted

const WEAPON_SLOT_COUNT: int = 6
const DEFAULT_RARITY_ORDER: PackedStringArray = ["common", "uncommon", "rare", "epic", "legendary"]

var _catalog: Dictionary = {}

func setup(catalog: Dictionary) -> void:
	_catalog = catalog.duplicate(true)

func roll_shop_offers(context: Dictionary) -> Array[Dictionary]:
	var shop_state: Dictionary = _normalize_shop_state(context.get("shop_runtime_state", {}))
	var lock_enabled: bool = bool(shop_state.get("shop_locked", false))
	var locked_offers: Array = shop_state.get("locked_shop_offers", [])
	if lock_enabled and not locked_offers.is_empty():
		var cloned_locked: Array[Dictionary] = []
		for offer in locked_offers:
			if offer is Dictionary:
				cloned_locked.append((offer as Dictionary).duplicate(true))
		if not cloned_locked.is_empty():
			return cloned_locked

	var shop_rules: Dictionary = _catalog.get("shop_rules", {})
	var offer_count: int = max(1, int(shop_rules.get("offers_per_wave", 4)))
	var weapon_chance: float = clampf(float(shop_rules.get("weapon_chance", 0.5)), 0.0, 1.0)
	var wave_index: int = max(1, int(context.get("wave", 1)))
	var rolled: Array[Dictionary] = []
	for i: int in range(offer_count):
		var pick_weapon: bool = randf() < weapon_chance
		var offer: Dictionary = _roll_weapon_offer(wave_index) if pick_weapon else _roll_item_offer(wave_index)
		offer["offer_id"] = "offer_%d_%d_%d" % [wave_index, i, randi() % 100000]
		offer["sold"] = false
		rolled.append(offer)
	return rolled

func purchase_offer(offer_id: String, state: Dictionary) -> Dictionary:
	var runtime: Dictionary = state.duplicate(true)
	var offers: Array = runtime.get("shop_offers", [])
	var offer_index: int = -1
	var selected_offer: Dictionary = {}
	for i: int in range(offers.size()):
		var candidate: Variant = offers[i]
		if not (candidate is Dictionary):
			continue
		var offer: Dictionary = candidate
		if str(offer.get("offer_id", "")) == offer_id:
			offer_index = i
			selected_offer = offer
			break
	if selected_offer.is_empty() or offer_index < 0:
		return {"ok": false, "message": "msg.shop.offer_not_found", "state": runtime}
	if bool(selected_offer.get("sold", false)):
		return {"ok": false, "message": "msg.shop.offer_sold", "state": runtime}

	var current_gold: int = max(0, int(runtime.get("current_gold", 0)))
	var price: int = max(0, int(selected_offer.get("price", 0)))
	if current_gold < price:
		return {"ok": false, "message": "msg.shop.not_enough_gold", "state": runtime}

	runtime["current_gold"] = current_gold - price
	var shop_state: Dictionary = _normalize_shop_state(runtime.get("shop_runtime_state", {}))
	var kind: String = str(selected_offer.get("kind", "item"))
	if kind == "weapon":
		var weapon_payload: Variant = selected_offer.get("weapon", {})
		var replace_slot_index: int = int(runtime.get("replace_slot_index", -1))
		var weapon_result: Dictionary = _add_weapon_to_slots(weapon_payload, shop_state, replace_slot_index)
		runtime["shop_runtime_state"] = weapon_result.get("shop_state", shop_state)
		if bool(weapon_result.get("needs_replace", false)):
			runtime["current_gold"] = current_gold
			return {
				"ok": false,
				"needs_replace": true,
				"message": str(weapon_result.get("message", "msg.shop.choose_slot_replace")),
				"replace_candidates": weapon_result.get("replace_candidates", []),
				"state": runtime,
			}
	else:
		_apply_item_effect(runtime, selected_offer.get("effects", {}))
		runtime["shop_runtime_state"] = shop_state

	var final_offers: Array = offers.duplicate(true)
	var sold_offer: Dictionary = selected_offer.duplicate(true)
	sold_offer["sold"] = true
	final_offers[offer_index] = sold_offer
	runtime["shop_offers"] = final_offers

	var locked: Array = runtime.get("shop_runtime_state", {}).get("locked_shop_offers", [])
	if not locked.is_empty():
		runtime["shop_runtime_state"]["locked_shop_offers"] = final_offers.duplicate(true)
	return {"ok": true, "state": runtime, "message": "msg.shop.purchase_success"}

func merge_weapons_if_possible(state: Dictionary) -> Dictionary:
	var runtime: Dictionary = state.duplicate(true)
	var shop_state: Dictionary = _normalize_shop_state(runtime.get("shop_runtime_state", {}))
	var equipped: Array = _normalize_weapon_slots(shop_state.get("equipped_weapons", []))
	var rarity_order: PackedStringArray = _get_rarity_order()
	var merged_once: bool = false

	for i: int in range(equipped.size()):
		var left: Variant = equipped[i]
		if not _is_valid_weapon(left):
			continue
		for j: int in range(i + 1, equipped.size()):
			var right: Variant = equipped[j]
			if not _is_valid_weapon(right):
				continue
			var left_weapon: Dictionary = left
			var right_weapon: Dictionary = right
			if str(left_weapon.get("stack_key", "")) != str(right_weapon.get("stack_key", "")):
				continue
			if str(left_weapon.get("rarity", "common")) != str(right_weapon.get("rarity", "common")):
				continue
			var current_rarity: String = str(left_weapon.get("rarity", "common"))
			var next_rarity: String = _next_rarity(current_rarity, rarity_order)
			if next_rarity == current_rarity:
				continue
			left_weapon["rarity"] = next_rarity
			left_weapon["level"] = int(left_weapon.get("level", 1)) + 1
			equipped[i] = left_weapon
			equipped[j] = {}
			merged_once = true
			break
		if merged_once:
			break

	shop_state["equipped_weapons"] = equipped
	runtime["shop_runtime_state"] = shop_state
	runtime["merged"] = merged_once
	return runtime

func _roll_item_offer(wave_index: int) -> Dictionary:
	var item_pool: Array = _catalog.get("item_pool", [])
	if item_pool.is_empty():
		return {
			"kind": "item",
			"item_id": "item_damage_upgrade",
			"name": "Damage Upgrade",
			"price": 35 + wave_index * 2,
			"rarity": "common",
			"description": "+1 attack damage",
			"effects": {"bonus_attack_damage": 1},
		}
	var template: Dictionary = _pick_weighted(item_pool)
	var price_scale: float = float(template.get("price_wave_scale", 1.05))
	var base_price: int = max(1, int(template.get("base_price", 20)))
	var final_price: int = max(1, int(round(base_price * pow(price_scale, max(0, wave_index - 1)))))
	return {
		"kind": "item",
		"item_id": str(template.get("item_id", "")),
		"name": str(template.get("name", "Item")),
		"price": final_price,
		"rarity": str(template.get("rarity", "common")),
		"description": str(template.get("description", "")),
		"effects": template.get("effects", {}),
	}

func _roll_weapon_offer(wave_index: int) -> Dictionary:
	var weapon_pool: Array = _catalog.get("weapon_pool", [])
	if weapon_pool.is_empty():
		return {
			"kind": "weapon",
			"weapon_id": "starter_blade",
			"name": "Starter Blade",
			"price": 45 + wave_index * 3,
			"rarity": "common",
			"description": "Simple blade, stable DPS.",
			"weapon": {
				"weapon_id": "starter_blade",
				"rarity": "common",
				"level": 1,
				"tags": ["melee"],
				"effects": {"bonus_attack_damage": 1},
				"stack_key": "starter_blade",
			},
		}
	var template: Dictionary = _pick_weighted(weapon_pool)
	var rarity: String = _roll_rarity(template.get("rarity_weights", {}))
	var base_price: int = max(1, int(template.get("base_price", 35)))
	var rarity_multiplier: float = _rarity_price_multiplier(rarity)
	var wave_scale: float = float(template.get("price_wave_scale", 1.06))
	var final_price: int = max(1, int(round(base_price * rarity_multiplier * pow(wave_scale, max(0, wave_index - 1)))))
	var weapon: Dictionary = {
		"weapon_id": str(template.get("weapon_id", "weapon_unknown")),
		"rarity": rarity,
		"level": int(template.get("level", 1)),
		"tags": template.get("tags", []),
		"effects": template.get("effects", {}),
		"stack_key": str(template.get("stack_key", template.get("weapon_id", "weapon_unknown"))),
		"attack_profile": template.get("attack_profile", {}),
	}
	return {
		"kind": "weapon",
		"weapon_id": str(template.get("weapon_id", "weapon_unknown")),
		"name": str(template.get("name", "Weapon")),
		"price": final_price,
		"rarity": rarity,
		"description": str(template.get("description", "")),
		"weapon": weapon,
	}

func _add_weapon_to_slots(weapon_payload: Variant, shop_state: Dictionary, replace_slot_index: int = -1) -> Dictionary:
	if not (weapon_payload is Dictionary):
		return {"shop_state": shop_state, "needs_replace": false, "message": "msg.shop.invalid_weapon_data"}
	var weapon: Dictionary = (weapon_payload as Dictionary).duplicate(true)
	var equipped: Array = _normalize_weapon_slots(shop_state.get("equipped_weapons", []))
	var empty_slot: int = _find_empty_slot(equipped)
	if empty_slot >= 0:
		equipped[empty_slot] = weapon
		shop_state["equipped_weapons"] = equipped
		return {"shop_state": shop_state, "needs_replace": false}

	var merge_result: Dictionary = _try_merge_for_weapon(equipped, weapon)
	equipped = merge_result.get("equipped", equipped)
	if bool(merge_result.get("merged", false)):
		var post_merge_slot: int = _find_empty_slot(equipped)
		if post_merge_slot >= 0:
			equipped[post_merge_slot] = weapon
			shop_state["equipped_weapons"] = equipped
			return {"shop_state": shop_state, "needs_replace": false}

	if replace_slot_index >= 0 and replace_slot_index < equipped.size():
		equipped[replace_slot_index] = weapon
		shop_state["equipped_weapons"] = equipped
		return {"shop_state": shop_state, "needs_replace": false}

	var candidates: Array[int] = []
	for i: int in range(equipped.size()):
		candidates.append(i)
	shop_state["pending_replace_weapon"] = weapon
	return {
		"shop_state": shop_state,
		"needs_replace": true,
		"message": "msg.shop.weapon_slots_full",
		"replace_candidates": candidates,
	}

func _try_merge_for_weapon(equipped: Array, incoming_weapon: Dictionary) -> Dictionary:
	var stack_key: String = str(incoming_weapon.get("stack_key", incoming_weapon.get("weapon_id", "")))
	var rarity: String = str(incoming_weapon.get("rarity", "common"))
	var first_match: int = -1
	for i: int in range(equipped.size()):
		var slot_weapon: Variant = equipped[i]
		if not _is_valid_weapon(slot_weapon):
			continue
		var as_dict: Dictionary = slot_weapon
		if str(as_dict.get("stack_key", "")) != stack_key:
			continue
		if str(as_dict.get("rarity", "common")) != rarity:
			continue
		first_match = i
		break
	if first_match < 0:
		return {"equipped": equipped, "merged": false}
	var merged_weapon: Dictionary = (equipped[first_match] as Dictionary).duplicate(true)
	merged_weapon["rarity"] = _next_rarity(rarity, _get_rarity_order())
	merged_weapon["level"] = int(merged_weapon.get("level", 1)) + 1
	equipped[first_match] = merged_weapon
	return {"equipped": equipped, "merged": true}

func _apply_item_effect(runtime: Dictionary, effects_raw: Variant) -> void:
	if not (effects_raw is Dictionary):
		return
	var effects: Dictionary = effects_raw
	if effects.has("bonus_attack_damage"):
		runtime["bonus_attack_damage"] = int(runtime.get("bonus_attack_damage", 0)) + int(effects.get("bonus_attack_damage", 0))
	if effects.has("bonus_target_range"):
		runtime["bonus_target_range"] = float(runtime.get("bonus_target_range", 0.0)) + float(effects.get("bonus_target_range", 0.0))
	if effects.has("player_move_speed"):
		runtime["player_move_speed"] = float(runtime.get("player_move_speed", 220.0)) + float(effects.get("player_move_speed", 0.0))
	if effects.has("armor"):
		var stats: Dictionary = runtime.get("player_stats", {})
		stats["armor"] = float(stats.get("armor", 0.0)) + float(effects.get("armor", 0.0))
		runtime["player_stats"] = stats
	if effects.has("dodge_chance"):
		var stats_dodge: Dictionary = runtime.get("player_stats", {})
		stats_dodge["dodge_chance"] = float(stats_dodge.get("dodge_chance", 0.0)) + float(effects.get("dodge_chance", 0.0))
		runtime["player_stats"] = stats_dodge
	if effects.has("attack_speed_mult"):
		var stats_attack_speed: Dictionary = runtime.get("player_stats", {})
		stats_attack_speed["attack_speed_mult"] = float(stats_attack_speed.get("attack_speed_mult", 1.0)) * float(effects.get("attack_speed_mult", 1.0))
		runtime["player_stats"] = stats_attack_speed
	if effects.has("crit_chance"):
		var stats_crit_chance: Dictionary = runtime.get("player_stats", {})
		stats_crit_chance["crit_chance"] = float(stats_crit_chance.get("crit_chance", 0.05)) + float(effects.get("crit_chance", 0.0))
		runtime["player_stats"] = stats_crit_chance
	if effects.has("crit_multiplier"):
		var stats_crit_multi: Dictionary = runtime.get("player_stats", {})
		stats_crit_multi["crit_multiplier"] = float(stats_crit_multi.get("crit_multiplier", 1.5)) + float(effects.get("crit_multiplier", 0.0))
		runtime["player_stats"] = stats_crit_multi
	if effects.has("lifesteal"):
		var stats_lifesteal: Dictionary = runtime.get("player_stats", {})
		stats_lifesteal["lifesteal"] = float(stats_lifesteal.get("lifesteal", 0.0)) + float(effects.get("lifesteal", 0.0))
		runtime["player_stats"] = stats_lifesteal
	if effects.has("gold_gain_multiplier"):
		runtime["gold_gain_multiplier"] = max(0.1, float(runtime.get("gold_gain_multiplier", 1.0)) * float(effects.get("gold_gain_multiplier", 1.0)))

func _roll_rarity(weights_raw: Variant) -> String:
	var weights: Dictionary = {}
	if weights_raw is Dictionary:
		weights = weights_raw
	if weights.is_empty():
		return "common"
	var total: float = 0.0
	for key in weights.keys():
		total += max(0.0, float(weights[key]))
	if total <= 0.0:
		return "common"
	var ticket: float = randf() * total
	var passed: float = 0.0
	for key in weights.keys():
		passed += max(0.0, float(weights[key]))
		if ticket <= passed:
			return str(key)
	return "common"

func _rarity_price_multiplier(rarity: String) -> float:
	match rarity:
		"uncommon":
			return 1.35
		"rare":
			return 1.8
		"epic":
			return 2.5
		"legendary":
			return 3.4
		_:
			return 1.0

func _pick_weighted(pool: Array) -> Dictionary:
	if pool.is_empty():
		return {}
	var total_weight: float = 0.0
	for row in pool:
		if row is Dictionary:
			total_weight += max(0.0, float((row as Dictionary).get("weight", 1.0)))
	if total_weight <= 0.0:
		var fallback: Variant = pool[0]
		return fallback.duplicate(true) if fallback is Dictionary else {}
	var ticket: float = randf() * total_weight
	var passed: float = 0.0
	for row in pool:
		if not (row is Dictionary):
			continue
		var item: Dictionary = row
		passed += max(0.0, float(item.get("weight", 1.0)))
		if ticket <= passed:
			return item.duplicate(true)
	var tail: Variant = pool[pool.size() - 1]
	return tail.duplicate(true) if tail is Dictionary else {}

func _find_empty_slot(equipped: Array) -> int:
	for i: int in range(equipped.size()):
		var slot_value: Variant = equipped[i]
		if not _is_valid_weapon(slot_value):
			return i
	return -1

func _normalize_weapon_slots(raw_slots: Variant) -> Array:
	var slots: Array = []
	if raw_slots is Array:
		var src: Array = raw_slots
		for i: int in range(min(src.size(), WEAPON_SLOT_COUNT)):
			var slot_entry: Variant = src[i]
			slots.append(slot_entry.duplicate(true) if slot_entry is Dictionary else {})
	while slots.size() < WEAPON_SLOT_COUNT:
		slots.append({})
	return slots

func _is_valid_weapon(value: Variant) -> bool:
	if not (value is Dictionary):
		return false
	var weapon: Dictionary = value
	return not str(weapon.get("weapon_id", "")).is_empty()

func _normalize_shop_state(raw_state: Variant) -> Dictionary:
	var normalized: Dictionary = {
		"equipped_weapons": _normalize_weapon_slots([]),
		"inventory_overflow": [],
		"locked_shop_offers": [],
		"refresh_count": 0,
		"shop_locked": false,
	}
	if raw_state is Dictionary:
		var source: Dictionary = raw_state
		normalized["equipped_weapons"] = _normalize_weapon_slots(source.get("equipped_weapons", []))
		var overflow: Variant = source.get("inventory_overflow", [])
		if overflow is Array:
			normalized["inventory_overflow"] = overflow.duplicate(true)
		var locked: Variant = source.get("locked_shop_offers", [])
		if locked is Array:
			normalized["locked_shop_offers"] = locked.duplicate(true)
		normalized["refresh_count"] = max(0, int(source.get("refresh_count", 0)))
		normalized["shop_locked"] = bool(source.get("shop_locked", false))
	return normalized

func _get_rarity_order() -> PackedStringArray:
	var merge_rules: Dictionary = _catalog.get("merge_rules", {})
	var raw_order: Variant = merge_rules.get("rarity_order", DEFAULT_RARITY_ORDER)
	if raw_order is PackedStringArray:
		var order_packed: PackedStringArray = raw_order
		return order_packed
	if raw_order is Array:
		var result: PackedStringArray = []
		for entry: Variant in raw_order:
			result.append(str(entry))
		if not result.is_empty():
			return result
	return DEFAULT_RARITY_ORDER

func _next_rarity(current: String, order: PackedStringArray) -> String:
	var index: int = order.find(current)
	if index < 0:
		return current
	if index >= order.size() - 1:
		return current
	return order[index + 1]
