class_name ShopSystem
extends RefCounted

const WEAPON_SLOT_COUNT: int = 6
const DEFAULT_RARITY_ORDER: PackedStringArray = ["common", "rare", "epic", "legendary"]
const DEFAULT_WEAPON_TAG_MAX_STACK: int = 6
const DEFAULT_WEAPON_TAG_TIER_STEPS: Array[int] = [2, 3, 4, 5, 6]
const LUCK_RARITY_STEP_DEFAULT: float = 0.012
const ATTACK_FLAT_TO_GLOBAL_ATTACK_PERCENT_DEFAULT: float = 3.0
const CRIT_MULTIPLIER_TO_CRIT_CHANCE_RATIO_DEFAULT: float = 0.12
const WEAPON_ICON_DIR: String = "res://sprite/weapons/generated_from_doc_v1_alpha_final_v2/"
const ITEM_ICON_DIR: String = "res://sprite/items/"
const WEAPON_RECYCLE_RATIO: float = 0.25
const ITEM_REWARD_RECYCLE_RATIO: float = 0.35
const WEAPON_RARITY_DAMAGE_MULTIPLIERS: Dictionary = {
    "common": 1.0,
    "rare": 1.25,
    "epic": 1.55,
    "legendary": 1.9,
}
const WEAPON_RARITY_INTERVAL_MULTIPLIERS: Dictionary = {
    "common": 1.0,
    "rare": 0.96,
    "epic": 0.91,
    "legendary": 0.86,
}
const WEAPON_RARITY_EFFECT_MULTIPLIERS: Dictionary = {
    "common": 1.0,
    "rare": 1.0,
    "epic": 1.25,
    "legendary": 1.5,
}
const WEAPON_RARITY_PRICE_MULTIPLIERS: Dictionary = {
    "common": 1.0,
    "rare": 1.45,
    "epic": 2.1,
    "legendary": 3.0,
}
const WEAPON_RARITY_EFFECT_SCALING_KEYS: Dictionary = {
    "bonus_attack_damage": true,
    "bonus_target_range": true,
}

var _catalog: Dictionary = {}

func setup(catalog: Dictionary) -> void:
    _catalog = catalog.duplicate(true)

func get_weapon_tag_bonus_rules() -> Dictionary:
    return _normalize_weapon_tag_rules(_catalog.get("weapon_tag_bonus_rules", {}))

func resolve_weapon_tag_state(shop_state_raw: Variant) -> Dictionary:
    var shop_state: Dictionary = _normalize_shop_state(shop_state_raw)
    var rules: Dictionary = _normalize_weapon_tag_rules(_catalog.get("weapon_tag_bonus_rules", {}))
    var max_stack: int = max(1, int(rules.get("max_stack_per_tag", DEFAULT_WEAPON_TAG_MAX_STACK)))
    var tier_steps: Array[int] = _extract_tier_steps(rules.get("tier_steps", DEFAULT_WEAPON_TAG_TIER_STEPS))
    var tag_defs: Dictionary = rules.get("tag_defs", {})
    var equipped: Array = _normalize_weapon_slots(shop_state.get("equipped_weapons", []))

    var counts: Dictionary = {}
    for slot_value: Variant in equipped:
        if not _is_valid_weapon(slot_value):
            continue
        var weapon: Dictionary = slot_value
        var weapon_tags: Array[String] = _extract_weapon_build_tags(weapon)
        var seen_in_weapon: Dictionary = {}
        for tag_id: String in weapon_tags:
            if seen_in_weapon.has(tag_id):
                continue
            seen_in_weapon[tag_id] = true
            counts[tag_id] = min(max_stack, int(counts.get(tag_id, 0)) + 1)

    var active_tiers: Dictionary = {}
    var next_tiers: Dictionary = {}
    var preview_effects: Array[Dictionary] = []
    var tag_meta: Dictionary = {}

    for tag_id: Variant in counts.keys():
        var tag_key: String = str(tag_id)
        var count: int = int(counts.get(tag_key, 0))
        var active_tier: int = _resolve_active_tier(count, tier_steps)
        if active_tier > 0:
            active_tiers[tag_key] = active_tier
            var tier_effects: Array[Dictionary] = _extract_tag_tier_effects(rules, tag_key, active_tier)
            for effect: Dictionary in tier_effects:
                preview_effects.append(effect.duplicate(true))

        next_tiers[tag_key] = _resolve_next_tier(count, tier_steps)
        var tag_def: Dictionary = {}
        var tag_def_raw: Variant = tag_defs.get(tag_key, {})
        if tag_def_raw is Dictionary:
            tag_def = (tag_def_raw as Dictionary)
        tag_meta[tag_key] = {
            "name": str(tag_def.get("name", tag_key)),
            "desc": str(tag_def.get("desc", "")),
        }

    return {
        "enabled": bool(rules.get("enabled", false)),
        "max_stack_per_tag": max_stack,
        "tier_steps": tier_steps.duplicate(),
        "counts": counts,
        "active_tiers": active_tiers,
        "next_tiers": next_tiers,
        "preview_effects": preview_effects,
        "tag_meta": tag_meta,
    }

func roll_shop_offers(context: Dictionary) -> Array[Dictionary]:
    var shop_state: Dictionary = _normalize_shop_state(context.get("shop_runtime_state", {}))
    var shop_rules: Dictionary = _catalog.get("shop_rules", {})
    var offer_count: int = max(1, int(shop_rules.get("offers_per_wave", 4)))
    var weapon_chance: float = clampf(float(shop_rules.get("weapon_chance", 0.5)), 0.0, 1.0)
    var stage_id: String = str(context.get("stage_id", "stage_001"))
    var wave_index: int = int(stage_id.split("_")[-1]) if "_" in stage_id else 1
    var luck_value: float = _get_context_luck(context)
    var locked_by_slot: Dictionary = _build_locked_offer_by_slot(
        shop_state.get("locked_shop_offers", []),
        bool(shop_state.get("shop_locked", false)),
        offer_count
    )
    var rolled: Array[Dictionary] = []
    for i: int in range(offer_count):
        if locked_by_slot.has(i):
            var preserved: Variant = locked_by_slot[i]
            if preserved is Dictionary:
                var locked_offer: Dictionary = (preserved as Dictionary).duplicate(true)
                locked_offer["slot_index"] = i
                locked_offer["locked"] = true
                locked_offer["sold"] = false
                if str(locked_offer.get("offer_id", "")).is_empty():
                    locked_offer["offer_id"] = _build_offer_id(wave_index, i)
                if str(locked_offer.get("icon_path", "")).is_empty():
                    locked_offer["icon_path"] = _resolve_offer_icon_path(locked_offer)
                rolled.append(locked_offer)
                continue
        rolled.append(_build_offer_for_slot(i, wave_index, weapon_chance, luck_value))
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
        var updated_shop_state: Dictionary = weapon_result.get("shop_state", shop_state)
        updated_shop_state["shop_locked"] = false
        updated_shop_state["weapon_tag_state"] = resolve_weapon_tag_state(updated_shop_state)
        runtime["shop_runtime_state"] = updated_shop_state
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
        _record_owned_item(shop_state, selected_offer)
        _apply_item_effect(runtime, selected_offer.get("effects", {}))
        shop_state["shop_locked"] = false
        shop_state["weapon_tag_state"] = resolve_weapon_tag_state(shop_state)
        runtime["shop_runtime_state"] = shop_state

    var final_offers: Array = offers.duplicate(true)
    var sold_offer: Dictionary = selected_offer.duplicate(true)
    sold_offer["slot_index"] = int(sold_offer.get("slot_index", offer_index))
    sold_offer["sold"] = true
    sold_offer["locked"] = false
    final_offers[offer_index] = sold_offer
    runtime["shop_offers"] = final_offers

    var finalized_shop_state: Dictionary = runtime.get("shop_runtime_state", {})
    finalized_shop_state = _sync_locked_state_from_offers(finalized_shop_state, final_offers)
    finalized_shop_state["weapon_tag_state"] = resolve_weapon_tag_state(finalized_shop_state)
    runtime["shop_runtime_state"] = finalized_shop_state
    return {"ok": true, "state": runtime, "message": "msg.shop.purchase_success"}

func merge_weapons_if_possible(state: Dictionary) -> Dictionary:
    var runtime: Dictionary = state.duplicate(true)
    var shop_state: Dictionary = _normalize_shop_state(runtime.get("shop_runtime_state", {}))
    var equipped: Array = _normalize_weapon_slots(shop_state.get("equipped_weapons", []))
    var merged_once: bool = false

    for i: int in range(equipped.size()):
        if not _is_valid_weapon(equipped[i]):
            continue
        var partner_index: int = _find_merge_partner(equipped, i)
        if partner_index >= 0:
            _merge_weapon_pair_into_left(equipped, i, partner_index)
            merged_once = true
            break

    shop_state["equipped_weapons"] = equipped
    shop_state["weapon_tag_state"] = resolve_weapon_tag_state(shop_state)
    runtime["shop_runtime_state"] = shop_state
    runtime["merged"] = merged_once
    return runtime

func combine_weapon_slot(slot_index: int, state: Dictionary) -> Dictionary:
    var runtime: Dictionary = state.duplicate(true)
    var shop_state: Dictionary = _normalize_shop_state(runtime.get("shop_runtime_state", {}))
    var equipped: Array = _normalize_weapon_slots(shop_state.get("equipped_weapons", []))
    if slot_index < 0 or slot_index >= equipped.size():
        runtime["shop_runtime_state"] = shop_state
        return {"ok": false, "message": "msg.shop.combine_invalid_slot", "state": runtime}
    if not _is_valid_weapon(equipped[slot_index]):
        runtime["shop_runtime_state"] = shop_state
        return {"ok": false, "message": "msg.shop.combine_empty_slot", "state": runtime}

    var partner_index: int = _find_merge_partner(equipped, slot_index)
    if partner_index < 0:
        runtime["shop_runtime_state"] = shop_state
        return {"ok": false, "message": "msg.shop.combine_no_match", "state": runtime}

    _merge_weapon_pair_into_left(equipped, slot_index, partner_index)
    shop_state["equipped_weapons"] = equipped
    shop_state["weapon_tag_state"] = resolve_weapon_tag_state(shop_state)
    runtime["shop_runtime_state"] = shop_state
    return {"ok": true, "message": "msg.shop.combine_success", "state": runtime}

func recycle_weapon_slot(slot_index: int, state: Dictionary) -> Dictionary:
    var runtime: Dictionary = state.duplicate(true)
    var shop_state: Dictionary = _normalize_shop_state(runtime.get("shop_runtime_state", {}))
    var equipped: Array = _normalize_weapon_slots(shop_state.get("equipped_weapons", []))
    if slot_index < 0 or slot_index >= equipped.size():
        runtime["shop_runtime_state"] = shop_state
        return {"ok": false, "message": "msg.shop.recycle_invalid_slot", "state": runtime}
    if not _is_valid_weapon(equipped[slot_index]):
        runtime["shop_runtime_state"] = shop_state
        return {"ok": false, "message": "msg.shop.recycle_empty_slot", "state": runtime}

    var weapon: Dictionary = equipped[slot_index]
    var refund: int = max(1, int(weapon.get("recycle_value", _estimate_weapon_recycle_value(weapon))))
    equipped[slot_index] = {}
    shop_state["equipped_weapons"] = equipped
    shop_state["weapon_tag_state"] = resolve_weapon_tag_state(shop_state)
    runtime["current_gold"] = max(0, int(runtime.get("current_gold", 0))) + refund
    runtime["shop_runtime_state"] = shop_state
    return {
        "ok": true,
        "message": "msg.shop.recycle_success",
        "refund": refund,
        "state": runtime,
    }

func roll_elite_chest_item(context: Dictionary) -> Dictionary:
    var wave_index: int = max(1, int(context.get("wave", 1)))
    var luck_value: float = _get_context_luck(context)
    if context.has("luck"):
        luck_value = float(context.get("luck", luck_value))
    var item_pool: Array = _catalog.get("item_pool", [])
    var template: Dictionary = _pick_chest_item_template(item_pool, luck_value)
    if template.is_empty():
        template = {
            "item_id": "item_damage_upgrade",
            "name": "Damage Upgrade",
            "description": "+1 attack damage",
            "rarity": "common",
            "base_price": 35,
            "effects": {"bonus_attack_damage": 1},
        }
    var wave_inflation: float = 1.0 + (max(0, wave_index - 1) * 0.06)
    var base_price: int = max(1, int(template.get("base_price", 20)))
    var final_price: int = max(1, int(round(float(base_price) * wave_inflation)))
    var offer: Dictionary = {
        "kind": "item",
        "item_id": str(template.get("item_id", "")),
        "name": str(template.get("name", "Item")),
        "price": final_price,
        "rarity": str(template.get("rarity", "common")),
        "description": str(template.get("description", "")),
        "effects": template.get("effects", {}),
        "icon_path": str(template.get("icon_path", "")),
    }
    if str(offer.get("icon_path", "")).is_empty():
        offer["icon_path"] = _resolve_offer_icon_path(offer)
    offer["recycle_value"] = max(1, int(round(float(final_price) * ITEM_REWARD_RECYCLE_RATIO)))
    return offer

func claim_item_reward(offer: Dictionary, state: Dictionary) -> Dictionary:
    var runtime: Dictionary = state.duplicate(true)
    var reward: Dictionary = offer.duplicate(true)
    reward["kind"] = "item"
    var shop_state: Dictionary = _normalize_shop_state(runtime.get("shop_runtime_state", {}))
    _record_owned_item(shop_state, reward)
    _apply_item_effect(runtime, reward.get("effects", {}))
    shop_state["weapon_tag_state"] = resolve_weapon_tag_state(shop_state)
    runtime["shop_runtime_state"] = shop_state
    return {"ok": true, "state": runtime, "message": "msg.elite_chest.claim_success"}

func recycle_item_reward(offer: Dictionary, state: Dictionary) -> Dictionary:
    var runtime: Dictionary = state.duplicate(true)
    var fallback_refund: int = int(round(float(max(1, int(offer.get("price", 1)))) * ITEM_REWARD_RECYCLE_RATIO))
    var refund: int = max(1, int(offer.get("recycle_value", fallback_refund)))
    runtime["current_gold"] = max(0, int(runtime.get("current_gold", 0))) + refund
    return {
        "ok": true,
        "state": runtime,
        "message": "msg.elite_chest.recycle_success",
        "refund": refund,
    }

func _build_offer_for_slot(slot_index: int, wave_index: int, weapon_chance: float, luck_value: float) -> Dictionary:
    var pick_weapon: bool = randf() < weapon_chance
    var offer: Dictionary = _roll_weapon_offer(wave_index, luck_value) if pick_weapon else _roll_item_offer(wave_index, luck_value)
    offer["offer_id"] = _build_offer_id(wave_index, slot_index)
    offer["slot_index"] = slot_index
    offer["sold"] = false
    offer["locked"] = false
    if str(offer.get("icon_path", "")).is_empty():
        offer["icon_path"] = _resolve_offer_icon_path(offer)
    return offer

func _build_offer_id(wave_index: int, slot_index: int) -> String:
    return "offer_%d_%d_%d" % [wave_index, slot_index, randi() % 100000]

func _roll_item_offer(wave_index: int, luck_value: float = 0.0) -> Dictionary:
    var item_pool: Array = _catalog.get("item_pool", [])
    if item_pool.is_empty():
        var fallback_offer: Dictionary = {
            "kind": "item",
            "item_id": "item_damage_upgrade",
            "name": "Damage Upgrade",
            "price": 35 + wave_index * 2,
            "rarity": "common",
            "description": "+1 attack damage",
            "effects": {"bonus_attack_damage": 1},
        }
        fallback_offer["icon_path"] = _resolve_offer_icon_path(fallback_offer)
        return fallback_offer
    var template: Dictionary = _pick_shop_item_template(item_pool, luck_value, wave_index)
    var wave_inflation: float = 1.0 + (max(0, wave_index - 1) * 0.06)
    var base_price: int = max(1, int(template.get("base_price", 20)))
    var final_price: int = max(1, int(round(base_price * wave_inflation)))
    var offer: Dictionary = {
        "kind": "item",
        "item_id": str(template.get("item_id", "")),
        "name": str(template.get("name", "Item")),
        "price": final_price,
        "rarity": str(template.get("rarity", "common")),
        "description": str(template.get("description", "")),
        "effects": template.get("effects", {}),
        "icon_path": str(template.get("icon_path", "")),
    }
    if str(offer.get("icon_path", "")).is_empty():
        offer["icon_path"] = _resolve_offer_icon_path(offer)
    return offer

func _pick_shop_item_template(item_pool: Array, luck_value: float, wave_index: int = 1) -> Dictionary:
    var shop_rules: Dictionary = _catalog.get("shop_rules", {})
    var rarity_weights_raw: Variant = shop_rules.get("item_rarity_weights", {})
    if not (rarity_weights_raw is Dictionary) or (rarity_weights_raw as Dictionary).is_empty():
        return _pick_weighted(item_pool)
    var rarity_stage_gates: Dictionary = {}
    var gates_raw: Variant = shop_rules.get("item_rarity_stage_gates", {})
    if gates_raw is Dictionary:
        rarity_stage_gates = gates_raw

    var pools_by_rarity: Dictionary = {}
    for row_value: Variant in item_pool:
        if not (row_value is Dictionary):
            continue
        var row: Dictionary = row_value
        var rarity: String = str(row.get("rarity", "common")).to_lower()
        if not pools_by_rarity.has(rarity):
            pools_by_rarity[rarity] = []
        var rarity_pool: Array = pools_by_rarity[rarity]
        rarity_pool.append(row)
        pools_by_rarity[rarity] = rarity_pool

    var rolled_rarity: String = _roll_rarity(rarity_weights_raw, luck_value, wave_index, rarity_stage_gates)
    var selected_pool: Array = pools_by_rarity.get(rolled_rarity, [])
    if selected_pool.is_empty():
        return _pick_weighted(item_pool)
    return _pick_weighted(selected_pool)

func _pick_chest_item_template(item_pool: Array, luck_value: float) -> Dictionary:
    if item_pool.is_empty():
        return {}
    var rarity_weights: Dictionary = {}
    var pools_by_rarity: Dictionary = {}
    for row_value: Variant in item_pool:
        if not (row_value is Dictionary):
            continue
        var row: Dictionary = row_value
        var rarity: String = str(row.get("rarity", "common")).to_lower()
        var weight: float = max(0.0, float(row.get("weight", 1.0)))
        rarity_weights[rarity] = float(rarity_weights.get(rarity, 0.0)) + weight
        if not pools_by_rarity.has(rarity):
            pools_by_rarity[rarity] = []
        var rarity_pool: Array = pools_by_rarity[rarity]
        rarity_pool.append(row)
        pools_by_rarity[rarity] = rarity_pool
    var rolled_rarity: String = _roll_rarity(rarity_weights, luck_value)
    var selected_pool: Array = pools_by_rarity.get(rolled_rarity, [])
    if selected_pool.is_empty():
        selected_pool = item_pool
    return _pick_weighted(selected_pool)

func _roll_weapon_offer(wave_index: int, luck_value: float = 0.0) -> Dictionary:
    var weapon_pool: Array = _catalog.get("weapon_pool", [])
    if weapon_pool.is_empty():
        var fallback_price: int = 45 + wave_index * 3
        var fallback_weapon: Dictionary = {
            "weapon_id": "starter_blade",
            "rarity": "common",
            "level": 1,
            "tags": ["melee"],
            "build_tags": ["berserker", "sustain"],
            "effects": {"bonus_attack_damage": 1},
            "_base_effects": {"bonus_attack_damage": 1},
            "stack_key": "starter_blade",
        }
        _prepare_weapon_economy(fallback_weapon, fallback_price)
        var fallback_weapon_offer: Dictionary = {
            "kind": "weapon",
            "weapon_id": "starter_blade",
            "name": "Starter Blade",
            "price": fallback_price,
            "rarity": "common",
            "description": "Simple blade, stable DPS.",
            "weapon": fallback_weapon,
        }
        fallback_weapon_offer["icon_path"] = _resolve_offer_icon_path(fallback_weapon_offer)
        return fallback_weapon_offer
    var template: Dictionary = _pick_weighted(weapon_pool)
    var shop_rules: Dictionary = _catalog.get("shop_rules", {})
    var weapon_rarity_stage_gates: Dictionary = {}
    var weapon_gates_raw: Variant = shop_rules.get("weapon_rarity_stage_gates", {})
    if weapon_gates_raw is Dictionary:
        weapon_rarity_stage_gates = weapon_gates_raw
    var weapon_unlocked_min_weights: Dictionary = {}
    var weapon_min_weights_raw: Variant = shop_rules.get("weapon_rarity_unlocked_min_weights", {})
    if weapon_min_weights_raw is Dictionary:
        weapon_unlocked_min_weights = weapon_min_weights_raw
    var rarity: String = _roll_rarity(
        template.get("rarity_weights", {}),
        luck_value,
        wave_index,
        weapon_rarity_stage_gates,
        weapon_unlocked_min_weights
    )
    var base_price: int = max(1, int(template.get("base_price", 35)))
    var rarity_multiplier: float = _rarity_price_multiplier(rarity)
    var wave_inflation: float = 1.0 + (max(0, wave_index - 1) * 0.06)
    var final_price: int = max(1, int(round(base_price * rarity_multiplier * wave_inflation)))
    var weapon: Dictionary = {
        "weapon_id": str(template.get("weapon_id", "weapon_unknown")),
        "rarity": rarity,
        "level": int(template.get("level", 1)),
        "tags": template.get("tags", []),
        "build_tags": template.get("build_tags", []),
        "effects": template.get("effects", {}).duplicate(true),
        "_base_effects": template.get("effects", {}).duplicate(true),
        "stack_key": str(template.get("stack_key", template.get("weapon_id", "weapon_unknown"))),
        "attack_profile": template.get("attack_profile", {}).duplicate(true),
        "_base_attack_profile": template.get("attack_profile", {}).duplicate(true),
    }
    _apply_rarity_scaling_to_weapon(weapon)
    _prepare_weapon_economy(weapon, final_price)
    var offer: Dictionary = {
        "kind": "weapon",
        "weapon_id": str(template.get("weapon_id", "weapon_unknown")),
        "name": str(template.get("name", "Weapon")),
        "price": final_price,
        "rarity": rarity,
        "description": str(template.get("description", "")),
        "weapon": weapon,
        "icon_path": str(template.get("icon_path", "")),
    }
    if str(offer.get("icon_path", "")).is_empty():
        offer["icon_path"] = _resolve_offer_icon_path(offer)
    return offer

func _add_weapon_to_slots(weapon_payload: Variant, shop_state: Dictionary, replace_slot_index: int = -1) -> Dictionary:
    if not (weapon_payload is Dictionary):
        return {"shop_state": shop_state, "needs_replace": false, "message": "msg.shop.invalid_weapon_data"}
    var weapon: Dictionary = (weapon_payload as Dictionary).duplicate(true)
    _prepare_weapon_economy(weapon, int(weapon.get("acquired_price", 0)))
    var equipped: Array = _normalize_weapon_slots(shop_state.get("equipped_weapons", []))
    var empty_slot: int = _find_empty_slot(equipped)
    if empty_slot >= 0:
        equipped[empty_slot] = weapon
        shop_state["equipped_weapons"] = equipped
        return {"shop_state": shop_state, "needs_replace": false}

    var merge_result: Dictionary = _try_merge_for_weapon(equipped, weapon)
    equipped = merge_result.get("equipped", equipped)
    if bool(merge_result.get("merged", false)):
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
        if str(as_dict.get("stack_key", as_dict.get("weapon_id", ""))) != stack_key:
            continue
        if str(as_dict.get("rarity", "common")) != rarity:
            continue
        first_match = i
        break
    if first_match < 0:
        return {"equipped": equipped, "merged": false}
    var incoming_slot: int = equipped.size()
    equipped.append(incoming_weapon)
    _merge_weapon_pair_into_left(equipped, first_match, incoming_slot)
    equipped.remove_at(incoming_slot)
    return {"equipped": equipped, "merged": true}

func _find_merge_partner(equipped: Array, source_index: int) -> int:
    if source_index < 0 or source_index >= equipped.size():
        return -1
    var source_value: Variant = equipped[source_index]
    if not _is_valid_weapon(source_value):
        return -1
    var source_weapon: Dictionary = source_value
    for i: int in range(equipped.size()):
        if i == source_index:
            continue
        var candidate_value: Variant = equipped[i]
        if not _is_valid_weapon(candidate_value):
            continue
        if _can_merge_weapons(source_weapon, candidate_value):
            return i
    return -1

func _can_merge_weapons(left_value: Variant, right_value: Variant) -> bool:
    if not _is_valid_weapon(left_value) or not _is_valid_weapon(right_value):
        return false
    var left: Dictionary = left_value
    var right: Dictionary = right_value
    var left_stack: String = str(left.get("stack_key", left.get("weapon_id", "")))
    var right_stack: String = str(right.get("stack_key", right.get("weapon_id", "")))
    if left_stack.is_empty() or left_stack != right_stack:
        return false
    var left_rarity: String = str(left.get("rarity", "common"))
    if left_rarity != str(right.get("rarity", "common")):
        return false
    return _next_rarity(left_rarity, _get_rarity_order()) != left_rarity

func _merge_weapon_pair_into_left(equipped: Array, left_index: int, right_index: int) -> void:
    if left_index < 0 or left_index >= equipped.size():
        return
    if right_index < 0 or right_index >= equipped.size():
        return
    if not _can_merge_weapons(equipped[left_index], equipped[right_index]):
        return
    var left_weapon: Dictionary = (equipped[left_index] as Dictionary).duplicate(true)
    var right_weapon: Dictionary = equipped[right_index]
    var current_rarity: String = str(left_weapon.get("rarity", "common"))
    left_weapon["rarity"] = _next_rarity(current_rarity, _get_rarity_order())
    left_weapon["level"] = int(left_weapon.get("level", 1)) + 1
    left_weapon["acquired_price"] = max(
        int(left_weapon.get("acquired_price", 0)),
        int(right_weapon.get("acquired_price", 0))
    )
    left_weapon["recycle_value"] = max(
        int(left_weapon.get("recycle_value", _estimate_weapon_recycle_value(left_weapon))),
        int(right_weapon.get("recycle_value", _estimate_weapon_recycle_value(right_weapon)))
    )
    _apply_rarity_scaling_to_weapon(left_weapon)
    _prepare_weapon_economy(left_weapon, int(left_weapon.get("acquired_price", 0)))
    equipped[left_index] = left_weapon
    equipped[right_index] = {}

func _cascade_merge_from_slot(equipped: Array, slot_index: int) -> void:
    var guard: int = 0
    while guard < 8:
        guard += 1
        var partner_index: int = _find_merge_partner(equipped, slot_index)
        if partner_index < 0:
            return
        _merge_weapon_pair_into_left(equipped, slot_index, partner_index)

func _apply_rarity_scaling_to_weapon(weapon: Dictionary) -> void:
    var rarity: String = str(weapon.get("rarity", "common"))
    var damage_multiplier: float = float(WEAPON_RARITY_DAMAGE_MULTIPLIERS.get(rarity, 1.0))
    var interval_multiplier: float = float(WEAPON_RARITY_INTERVAL_MULTIPLIERS.get(rarity, 1.0))
    var effect_multiplier: float = float(WEAPON_RARITY_EFFECT_MULTIPLIERS.get(rarity, 1.0))

    var template: Dictionary = _find_catalog_weapon_template(str(weapon.get("weapon_id", "")))
    var base_profile: Dictionary = {}
    if template.has("attack_profile") and template.get("attack_profile", {}) is Dictionary:
        base_profile = (template.get("attack_profile", {}) as Dictionary).duplicate(true)
    elif weapon.has("_base_attack_profile") and weapon.get("_base_attack_profile", {}) is Dictionary:
        base_profile = (weapon.get("_base_attack_profile", {}) as Dictionary).duplicate(true)
    elif weapon.get("attack_profile", {}) is Dictionary:
        base_profile = (weapon.get("attack_profile", {}) as Dictionary).duplicate(true)
    weapon["_base_attack_profile"] = base_profile.duplicate(true)

    var profile: Dictionary = base_profile.duplicate(true)
    if not profile.is_empty():
        if profile.has("base_damage"):
            profile["base_damage"] = int(round(float(profile["base_damage"]) * damage_multiplier))
        if profile.has("interval"):
            profile["interval"] = max(0.08, float(profile["interval"]) * interval_multiplier)
    weapon["attack_profile"] = profile

    var base_effects: Dictionary = {}
    if template.has("effects") and template.get("effects", {}) is Dictionary:
        base_effects = (template.get("effects", {}) as Dictionary).duplicate(true)
    elif weapon.has("_base_effects") and weapon.get("_base_effects", {}) is Dictionary:
        base_effects = (weapon.get("_base_effects", {}) as Dictionary).duplicate(true)
    elif weapon.get("effects", {}) is Dictionary:
        base_effects = (weapon.get("effects", {}) as Dictionary).duplicate(true)
    weapon["_base_effects"] = base_effects.duplicate(true)

    var effects: Dictionary = base_effects.duplicate(true)
    for key in effects.keys():
        var val = effects[key]
        if not WEAPON_RARITY_EFFECT_SCALING_KEYS.has(str(key)):
            continue
        if val is int:
            effects[key] = int(round(float(val) * effect_multiplier))
        elif val is float:
            effects[key] = float(val) * effect_multiplier
    weapon["effects"] = effects

func _prepare_weapon_economy(weapon: Dictionary, paid_price: int) -> void:
    var acquired_price: int = max(0, paid_price)
    if acquired_price <= 0:
        acquired_price = max(0, int(weapon.get("acquired_price", 0)))
    if acquired_price <= 0:
        acquired_price = _estimate_weapon_base_price(weapon)
    weapon["acquired_price"] = acquired_price
    weapon["recycle_value"] = max(1, int(weapon.get("recycle_value", round(float(acquired_price) * WEAPON_RECYCLE_RATIO))))

func _estimate_weapon_recycle_value(weapon: Dictionary) -> int:
    var recycle_value: int = int(weapon.get("recycle_value", 0))
    if recycle_value > 0:
        return recycle_value
    var acquired_price: int = int(weapon.get("acquired_price", 0))
    if acquired_price <= 0:
        acquired_price = _estimate_weapon_base_price(weapon)
    return max(1, int(round(float(acquired_price) * WEAPON_RECYCLE_RATIO)))

func _estimate_weapon_base_price(weapon: Dictionary) -> int:
    var template: Dictionary = _find_catalog_weapon_template(str(weapon.get("weapon_id", "")))
    var base_price: int = max(1, int(template.get("base_price", weapon.get("base_price", 35))))
    return max(1, int(round(float(base_price) * _rarity_price_multiplier(str(weapon.get("rarity", "common"))))))

func _find_catalog_weapon_template(weapon_id: String) -> Dictionary:
    var weapon_pool: Variant = _catalog.get("weapon_pool", [])
    if not (weapon_pool is Array):
        return {}
    for entry_value: Variant in weapon_pool:
        if not (entry_value is Dictionary):
            continue
        var entry: Dictionary = entry_value
        if str(entry.get("weapon_id", "")) == weapon_id:
            return entry
    return {}

func _record_owned_item(shop_state: Dictionary, offer: Dictionary) -> void:
    var item_id: String = str(offer.get("item_id", ""))
    if item_id.is_empty():
        return
    var owned_items: Array[Dictionary] = _normalize_owned_items(shop_state.get("owned_items", []))
    var rarity: String = str(offer.get("rarity", "common"))
    var icon_path: String = str(offer.get("icon_path", ""))
    if icon_path.is_empty():
        icon_path = _resolve_offer_icon_path(offer)
    for i: int in range(owned_items.size()):
        var row: Dictionary = owned_items[i]
        if str(row.get("item_id", "")) != item_id:
            continue
        row["count"] = max(1, int(row.get("count", 1)) + 1)
        if str(row.get("rarity", "")).is_empty():
            row["rarity"] = rarity
        if str(row.get("icon_path", "")).is_empty():
            row["icon_path"] = icon_path
        owned_items[i] = row
        shop_state["owned_items"] = owned_items
        return
    owned_items.append(
        {
            "item_id": item_id,
            "count": 1,
            "rarity": rarity,
            "icon_path": icon_path,
        }
    )
    shop_state["owned_items"] = owned_items

func _sync_locked_state_from_offers(shop_state: Dictionary, offers: Array) -> Dictionary:
    var normalized_state: Dictionary = _normalize_shop_state(shop_state)
    var locked_subset: Array[Dictionary] = []
    for i: int in range(offers.size()):
        var offer_value: Variant = offers[i]
        if not (offer_value is Dictionary):
            continue
        var offer: Dictionary = (offer_value as Dictionary).duplicate(true)
        var slot_index: int = int(offer.get("slot_index", i))
        if slot_index < 0:
            slot_index = i
        offer["slot_index"] = slot_index
        var is_locked: bool = bool(offer.get("locked", false))
        var is_sold: bool = bool(offer.get("sold", false))
        if is_locked and not is_sold:
            offer["locked"] = true
            locked_subset.append(offer)
    normalized_state["locked_shop_offers"] = locked_subset
    normalized_state["shop_locked"] = false
    return normalized_state

func _apply_item_effect(runtime: Dictionary, effects_raw: Variant) -> void:
    if not (effects_raw is Dictionary):
        return
    var effects: Dictionary = effects_raw
    var stats_raw: Variant = runtime.get("player_stats", {})
    var stats: Dictionary = {}
    if stats_raw is Dictionary:
        stats = (stats_raw as Dictionary).duplicate(true)
    if effects.has("bonus_attack_damage"):
        var legacy_bonus: int = int(effects.get("bonus_attack_damage", 0))
        runtime["bonus_attack_damage"] = int(runtime.get("bonus_attack_damage", 0)) + legacy_bonus
        stats["global_attack_percent"] = float(stats.get("global_attack_percent", 0.0)) + float(legacy_bonus) * _get_attack_flat_to_global_attack_percent()
    if effects.has("attack_damage_flat"):
        var legacy_flat: int = int(effects.get("attack_damage_flat", 0))
        runtime["bonus_attack_damage"] = int(runtime.get("bonus_attack_damage", 0)) + legacy_flat
        stats["global_attack_percent"] = float(stats.get("global_attack_percent", 0.0)) + float(legacy_flat) * _get_attack_flat_to_global_attack_percent()
    if effects.has("global_attack_percent"):
        stats["global_attack_percent"] = float(stats.get("global_attack_percent", 0.0)) + float(effects.get("global_attack_percent", 0.0))
    if effects.has("melee_damage_flat"):
        stats["bonus_melee_attack_damage"] = int(stats.get("bonus_melee_attack_damage", 0)) + int(effects.get("melee_damage_flat", 0))
    if effects.has("ranged_damage_flat"):
        stats["bonus_ranged_attack_damage"] = int(stats.get("bonus_ranged_attack_damage", 0)) + int(effects.get("ranged_damage_flat", 0))
    if effects.has("luck"):
        stats["luck"] = float(stats.get("luck", 0.0)) + float(effects.get("luck", 0.0))
    if effects.has("harvest"):
        stats["harvest"] = float(stats.get("harvest", 0.0)) + float(effects.get("harvest", 0.0))
    if effects.has("hp_regen"):
        stats["hp_regen"] = float(stats.get("hp_regen", 0.0)) + float(effects.get("hp_regen", 0.0))
    if effects.has("hp_regen_flat"):
        stats["hp_regen"] = float(stats.get("hp_regen", 0.0)) + float(effects.get("hp_regen_flat", 0.0))
    if effects.has("max_hp"):
        var hp_delta_alias: int = int(effects.get("max_hp", 0))
        var current_max_hp_alias: int = max(1, int(runtime.get("player_max_hp", 100)))
        var next_max_hp_alias: int = max(1, current_max_hp_alias + hp_delta_alias)
        var current_hp_alias: int = clampi(int(runtime.get("player_hp", current_max_hp_alias)), 0, current_max_hp_alias)
        runtime["player_max_hp"] = next_max_hp_alias
        runtime["player_hp"] = clampi(current_hp_alias + hp_delta_alias, 0, next_max_hp_alias)
    if effects.has("max_hp_flat"):
        var hp_delta: int = int(effects.get("max_hp_flat", 0))
        var current_max_hp: int = max(1, int(runtime.get("player_max_hp", 100)))
        var next_max_hp: int = max(1, current_max_hp + hp_delta)
        var current_hp: int = clampi(int(runtime.get("player_hp", current_max_hp)), 0, current_max_hp)
        runtime["player_max_hp"] = next_max_hp
        runtime["player_hp"] = clampi(current_hp + hp_delta, 0, next_max_hp)
    if effects.has("heal_flat"):
        var heal_value: int = int(effects.get("heal_flat", 0))
        var heal_max_hp: int = max(1, int(runtime.get("player_max_hp", 100)))
        var heal_current_hp: int = clampi(int(runtime.get("player_hp", heal_max_hp)), 0, heal_max_hp)
        runtime["player_hp"] = clampi(heal_current_hp + heal_value, 0, heal_max_hp)
    if effects.has("bonus_target_range"):
        runtime["bonus_target_range"] = float(runtime.get("bonus_target_range", 0.0)) + float(effects.get("bonus_target_range", 0.0))
    if effects.has("player_move_speed"):
        runtime["player_move_speed"] = float(runtime.get("player_move_speed", 220.0)) + float(effects.get("player_move_speed", 0.0))
    if effects.has("armor"):
        stats["armor"] = float(stats.get("armor", 0.0)) + float(effects.get("armor", 0.0))
    if effects.has("dodge_chance"):
        stats["dodge_chance"] = float(stats.get("dodge_chance", 0.0)) + float(effects.get("dodge_chance", 0.0))
    if effects.has("attack_speed_mult"):
        stats["attack_speed_mult"] = float(stats.get("attack_speed_mult", 1.0)) * float(effects.get("attack_speed_mult", 1.0))
    if effects.has("crit_chance"):
        stats["crit_chance"] = float(stats.get("crit_chance", 0.05)) + float(effects.get("crit_chance", 0.0))
    if effects.has("crit_multiplier"):
        stats["crit_chance"] = float(stats.get("crit_chance", 0.05)) + float(effects.get("crit_multiplier", 0.0)) * _get_crit_multiplier_to_crit_chance_ratio()
    if effects.has("crit_multiplier_flat"):
        stats["crit_chance"] = float(stats.get("crit_chance", 0.05)) + float(effects.get("crit_multiplier_flat", 0.0)) * _get_crit_multiplier_to_crit_chance_ratio()
    if effects.has("lifesteal"):
        stats["lifesteal"] = float(stats.get("lifesteal", 0.0)) + float(effects.get("lifesteal", 0.0))
    if effects.has("gold_gain_multiplier"):
        runtime["gold_gain_multiplier"] = max(0.1, float(runtime.get("gold_gain_multiplier", 1.0)) * float(effects.get("gold_gain_multiplier", 1.0)))
    if effects.has("pickup_radius"):
        runtime["pickup_radius"] = float(runtime.get("pickup_radius", 92.0)) + float(effects.get("pickup_radius", 0.0))
    if effects.has("xp_gain_mult"):
        runtime["xp_gain_mult"] = max(0.1, float(runtime.get("xp_gain_mult", 1.0)) * float(effects.get("xp_gain_mult", 1.0)))
    runtime["player_stats"] = stats

func _roll_rarity(
    weights_raw: Variant,
    luck_value: float = 0.0,
    wave_index: int = 1,
    rarity_stage_gates: Dictionary = {},
    unlocked_min_weights: Dictionary = {}
) -> String:
    var weights: Dictionary = {}
    if weights_raw is Dictionary:
        weights = weights_raw
    if weights.is_empty():
        return "common"
    weights = _filter_rarity_weights_by_stage(weights, wave_index, rarity_stage_gates)
    if weights.is_empty():
        return "common"
    weights = _apply_unlocked_min_rarity_weights(weights, wave_index, rarity_stage_gates, unlocked_min_weights)
    weights = _adjust_rarity_weights_by_luck(weights, luck_value)
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

func _filter_rarity_weights_by_stage(weights: Dictionary, wave_index: int, rarity_stage_gates: Dictionary) -> Dictionary:
    if rarity_stage_gates.is_empty():
        return weights.duplicate(true)
    var filtered: Dictionary = {}
    var safe_wave_index: int = max(1, wave_index)
    for key: Variant in weights.keys():
        var rarity_key: String = str(key).to_lower()
        var min_stage: int = max(1, int(rarity_stage_gates.get(rarity_key, 1)))
        if safe_wave_index < min_stage:
            continue
        filtered[key] = weights[key]
    return filtered

func _apply_unlocked_min_rarity_weights(
    weights: Dictionary,
    wave_index: int,
    rarity_stage_gates: Dictionary,
    unlocked_min_weights: Dictionary
) -> Dictionary:
    if unlocked_min_weights.is_empty():
        return weights
    var adjusted: Dictionary = weights.duplicate(true)
    var safe_wave_index: int = max(1, wave_index)
    for key: Variant in unlocked_min_weights.keys():
        var rarity_key: String = str(key).to_lower()
        var min_stage: int = max(1, int(rarity_stage_gates.get(rarity_key, 1)))
        if safe_wave_index < min_stage:
            continue
        if not adjusted.has(rarity_key):
            continue
        adjusted[rarity_key] = max(float(adjusted.get(rarity_key, 0.0)), float(unlocked_min_weights[key]))
    return adjusted

func _adjust_rarity_weights_by_luck(weights: Dictionary, luck_value: float) -> Dictionary:
    var adjusted: Dictionary = {}
    var luck_step: float = _get_luck_rarity_step()
    for key: Variant in weights.keys():
        var tier: String = str(key).to_lower()
        var base_weight: float = max(0.0, float(weights[key]))
        var tier_index: int = _rarity_tier_index(tier)
        var modifier: float = max(0.1, 1.0 + luck_value * luck_step * float(tier_index))
        adjusted[key] = base_weight * modifier
    return adjusted

func _rarity_tier_index(rarity_tier: String) -> int:
    match rarity_tier:
        "common":
            return 0
        "rare":
            return 1
        "epic":
            return 2
        "legendary":
            return 3
        _:
            return 0

func _get_context_luck(context: Dictionary) -> float:
    var stats_value: Variant = context.get("player_stats", {})
    if stats_value is Dictionary:
        return float((stats_value as Dictionary).get("luck", 0.0))
    return 0.0

func _get_luck_rarity_step() -> float:
    var combat_params: Dictionary = BalanceService.get_global_combat_params()
    return max(0.0, float(combat_params.get("luck_rarity_step", LUCK_RARITY_STEP_DEFAULT)))

func _get_attack_flat_to_global_attack_percent() -> float:
    var combat_params: Dictionary = BalanceService.get_global_combat_params()
    return max(
        0.0,
        float(combat_params.get("attack_flat_to_global_attack_percent", ATTACK_FLAT_TO_GLOBAL_ATTACK_PERCENT_DEFAULT))
    )

func _get_crit_multiplier_to_crit_chance_ratio() -> float:
    var combat_params: Dictionary = BalanceService.get_global_combat_params()
    return max(
        0.0,
        float(combat_params.get("crit_multiplier_to_crit_chance_ratio", CRIT_MULTIPLIER_TO_CRIT_CHANCE_RATIO_DEFAULT))
    )

func _rarity_price_multiplier(rarity: String) -> float:
    return float(WEAPON_RARITY_PRICE_MULTIPLIERS.get(rarity, 1.0))

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
        "owned_items": [],
        "weapon_tag_state": {},
    }
    if raw_state is Dictionary:
        var source: Dictionary = raw_state
        normalized["equipped_weapons"] = _normalize_weapon_slots(source.get("equipped_weapons", []))
        var overflow: Variant = source.get("inventory_overflow", [])
        if overflow is Array:
            normalized["inventory_overflow"] = overflow.duplicate(true)
        normalized["locked_shop_offers"] = _normalize_locked_offer_list(source.get("locked_shop_offers", []))
        normalized["refresh_count"] = max(0, int(source.get("refresh_count", 0)))
        normalized["shop_locked"] = bool(source.get("shop_locked", false))
        normalized["owned_items"] = _normalize_owned_items(source.get("owned_items", []))
        var weapon_tag_state_raw: Variant = source.get("weapon_tag_state", {})
        if weapon_tag_state_raw is Dictionary:
            normalized["weapon_tag_state"] = (weapon_tag_state_raw as Dictionary).duplicate(true)
    return normalized

func _normalize_weapon_tag_rules(raw_rules: Variant) -> Dictionary:
    var normalized: Dictionary = {
        "enabled": false,
        "max_stack_per_tag": DEFAULT_WEAPON_TAG_MAX_STACK,
        "tier_steps": DEFAULT_WEAPON_TAG_TIER_STEPS.duplicate(),
        "tag_defs": {},
    }
    if not (raw_rules is Dictionary):
        return normalized
    var source: Dictionary = raw_rules
    normalized["enabled"] = bool(source.get("enabled", false))
    normalized["max_stack_per_tag"] = max(1, int(source.get("max_stack_per_tag", DEFAULT_WEAPON_TAG_MAX_STACK)))
    var tier_steps: Array[int] = _extract_tier_steps(source.get("tier_steps", DEFAULT_WEAPON_TAG_TIER_STEPS))
    normalized["tier_steps"] = tier_steps.duplicate()

    var tag_defs: Dictionary = {}
    var raw_tag_defs: Variant = source.get("tag_defs", {})
    if raw_tag_defs is Dictionary:
        for tag_id: Variant in (raw_tag_defs as Dictionary).keys():
            var tag_key: String = str(tag_id)
            var raw_def_value: Variant = (raw_tag_defs as Dictionary).get(tag_id, {})
            if not (raw_def_value is Dictionary):
                continue
            var raw_def: Dictionary = raw_def_value
            var normalized_tiers: Dictionary = {}
            var raw_tiers_value: Variant = raw_def.get("tiers", {})
            var raw_tiers: Dictionary = {}
            if raw_tiers_value is Dictionary:
                raw_tiers = raw_tiers_value
            for tier_step: int in tier_steps:
                var tier_key: String = str(tier_step)
                var tier_value: Variant = raw_tiers.get(tier_key, raw_tiers.get(tier_step, {}))
                var tier_dict: Dictionary = {}
                if tier_value is Dictionary:
                    tier_dict = tier_value
                normalized_tiers[tier_key] = {
                    "effects": _normalize_tier_effects(tier_dict.get("effects", [])),
                    "note": str(tier_dict.get("note", "")),
                }
            tag_defs[tag_key] = {
                "name": str(raw_def.get("name", tag_key)),
                "desc": str(raw_def.get("desc", "")),
                "tiers": normalized_tiers,
            }
    normalized["tag_defs"] = tag_defs
    return normalized

func _extract_tier_steps(raw_steps: Variant) -> Array[int]:
    var result: Array[int] = []
    if raw_steps is Array:
        for raw_step: Variant in raw_steps:
            var parsed: int = int(raw_step)
            if parsed <= 0:
                continue
            if not result.has(parsed):
                result.append(parsed)
    if result.is_empty():
        result = DEFAULT_WEAPON_TAG_TIER_STEPS.duplicate()
    result.sort()
    return result

func _normalize_tier_effects(raw_effects: Variant) -> Array[Dictionary]:
    var normalized: Array[Dictionary] = []
    if not (raw_effects is Array):
        return normalized
    var src: Array = raw_effects
    for raw_effect in src:
        if not (raw_effect is Dictionary):
            continue
        var effect: Dictionary = raw_effect
        var effect_type: String = str(effect.get("type", "")).strip_edges()
        if effect_type.is_empty():
            continue
        normalized.append({
            "type": effect_type,
            "value": effect.get("value", 0),
        })
    return normalized

func _extract_weapon_build_tags(weapon: Dictionary) -> Array[String]:
    var tags: Array[String] = []
    var build_tags_raw: Variant = weapon.get("build_tags", [])
    if build_tags_raw is Array:
        for entry: Variant in (build_tags_raw as Array):
            var tag: String = str(entry).strip_edges().to_lower()
            if tag.is_empty():
                continue
            if tags.has(tag):
                continue
            tags.append(tag)
            if tags.size() >= 2:
                return tags

    var weapon_id: String = str(weapon.get("weapon_id", ""))
    if tags.is_empty() and not weapon_id.is_empty():
        var catalog_tags: Array[String] = _get_build_tags_from_catalog(weapon_id)
        for tag in catalog_tags:
            if tags.has(tag):
                continue
            tags.append(tag)
            if tags.size() >= 2:
                return tags

    if tags.is_empty():
        var legacy_tags_raw: Variant = weapon.get("tags", [])
        if legacy_tags_raw is Array:
            for legacy_tag_value: Variant in (legacy_tags_raw as Array):
                var mapped: String = _map_legacy_weapon_tag(str(legacy_tag_value))
                if mapped.is_empty() or tags.has(mapped):
                    continue
                tags.append(mapped)
                if tags.size() >= 2:
                    return tags
    return tags

func _get_build_tags_from_catalog(weapon_id: String) -> Array[String]:
    var result: Array[String] = []
    var weapon_pool_raw: Variant = _catalog.get("weapon_pool", [])
    if not (weapon_pool_raw is Array):
        return result
    var weapon_pool: Array = weapon_pool_raw
    for weapon_entry_value: Variant in weapon_pool:
        if not (weapon_entry_value is Dictionary):
            continue
        var weapon_entry: Dictionary = weapon_entry_value
        if str(weapon_entry.get("weapon_id", "")) != weapon_id:
            continue
        var build_tags_raw: Variant = weapon_entry.get("build_tags", [])
        if build_tags_raw is Array:
            for tag_value: Variant in (build_tags_raw as Array):
                var tag: String = str(tag_value).strip_edges().to_lower()
                if tag.is_empty() or result.has(tag):
                    continue
                result.append(tag)
        break
    return result

func _map_legacy_weapon_tag(legacy_tag_raw: String) -> String:
    match legacy_tag_raw.strip_edges().to_lower():
        "melee":
            return "berserker"
        "ranged":
            return "eagle_eye"
        "heavy":
            return "bulwark"
        "fast", "rapid", "tempo":
            return "rapid"
        "control", "pierce", "burst", "multi_hit", "dot":
            return "raider"
        "balanced", "basic":
            return "sustain"
        _:
            return ""

func _resolve_active_tier(count: int, tier_steps: Array[int]) -> int:
    var active: int = 0
    for tier_step: int in tier_steps:
        if count >= tier_step:
            active = tier_step
    return active

func _resolve_next_tier(count: int, tier_steps: Array[int]) -> int:
    for tier_step: int in tier_steps:
        if count < tier_step:
            return tier_step
    return 0

func _extract_tag_tier_effects(rules: Dictionary, tag_id: String, tier: int) -> Array[Dictionary]:
    var tag_defs: Dictionary = rules.get("tag_defs", {})
    var tag_def_raw: Variant = tag_defs.get(tag_id, {})
    if not (tag_def_raw is Dictionary):
        return []
    var tag_def: Dictionary = tag_def_raw
    var tiers_raw: Variant = tag_def.get("tiers", {})
    if not (tiers_raw is Dictionary):
        return []
    var tiers: Dictionary = tiers_raw
    var tier_key: String = str(tier)
    var tier_value: Variant = tiers.get(tier_key, {})
    if not (tier_value is Dictionary):
        return []
    return _normalize_tier_effects((tier_value as Dictionary).get("effects", []))

func _normalize_locked_offer_list(value: Variant) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    if not (value is Array):
        return result
    var raw_array: Array = value
    for i: int in range(raw_array.size()):
        var row_value: Variant = raw_array[i]
        if not (row_value is Dictionary):
            continue
        var row: Dictionary = (row_value as Dictionary).duplicate(true)
        row["slot_index"] = int(row.get("slot_index", i))
        row["locked"] = bool(row.get("locked", true))
        row["sold"] = bool(row.get("sold", false))
        if str(row.get("icon_path", "")).is_empty():
            row["icon_path"] = _resolve_offer_icon_path(row)
        result.append(row)
    return result

func _normalize_owned_items(value: Variant) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    if not (value is Array):
        return result
    var raw_array: Array = value
    for row_value: Variant in raw_array:
        if not (row_value is Dictionary):
            continue
        var row: Dictionary = row_value
        var item_id: String = str(row.get("item_id", ""))
        if item_id.is_empty():
            continue
        var normalized_row: Dictionary = {
            "item_id": item_id,
            "count": max(1, int(row.get("count", 1))),
            "rarity": str(row.get("rarity", "common")),
            "icon_path": str(row.get("icon_path", "")),
        }
        if str(normalized_row.get("icon_path", "")).is_empty():
            normalized_row["icon_path"] = "%s%s.png" % [ITEM_ICON_DIR, item_id]
        result.append(normalized_row)
    return result

func _build_locked_offer_by_slot(locked_offers_raw: Variant, legacy_global_lock: bool, offer_count: int) -> Dictionary:
    var result: Dictionary = {}
    var locked_rows: Array[Dictionary] = _normalize_locked_offer_list(locked_offers_raw)
    var legacy_cursor: int = 0
    for row: Dictionary in locked_rows:
        if bool(row.get("sold", false)):
            continue
        var slot_index: int = int(row.get("slot_index", -1))
        if slot_index < 0 or slot_index >= offer_count:
            if not legacy_global_lock:
                continue
            slot_index = legacy_cursor
            legacy_cursor += 1
        if slot_index < 0 or slot_index >= offer_count:
            continue
        row["slot_index"] = slot_index
        row["locked"] = true
        row["sold"] = false
        result[slot_index] = row
    if legacy_global_lock and result.is_empty() and locked_offers_raw is Array:
        var legacy_raw: Array = locked_offers_raw
        for i: int in range(min(legacy_raw.size(), offer_count)):
            var candidate: Variant = legacy_raw[i]
            if not (candidate is Dictionary):
                continue
            var legacy_row: Dictionary = (candidate as Dictionary).duplicate(true)
            legacy_row["slot_index"] = i
            legacy_row["locked"] = true
            legacy_row["sold"] = false
            if str(legacy_row.get("icon_path", "")).is_empty():
                legacy_row["icon_path"] = _resolve_offer_icon_path(legacy_row)
            result[i] = legacy_row
    return result

func _resolve_offer_icon_path(offer: Dictionary) -> String:
    var explicit_path: String = str(offer.get("icon_path", ""))
    if not explicit_path.is_empty():
        return explicit_path
    var kind: String = str(offer.get("kind", "item"))
    if kind == "weapon":
        var weapon_id: String = _extract_offer_weapon_id(offer)
        if weapon_id.is_empty():
            return ""
        return "%s%s.png" % [WEAPON_ICON_DIR, weapon_id]
    var item_id: String = str(offer.get("item_id", ""))
    if item_id.is_empty():
        return ""
    return "%s%s.png" % [ITEM_ICON_DIR, item_id]

func _extract_offer_weapon_id(offer: Dictionary) -> String:
    var weapon_id: String = str(offer.get("weapon_id", ""))
    if not weapon_id.is_empty():
        return weapon_id
    var weapon_value: Variant = offer.get("weapon", {})
    if weapon_value is Dictionary:
        return str((weapon_value as Dictionary).get("weapon_id", ""))
    return ""

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
