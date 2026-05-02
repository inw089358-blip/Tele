class_name UpgradeSystem
extends Node

const REWARD_ID_RARITY_SEPARATOR: String = "::"
const DEFAULT_RARITY_SCALING: Dictionary = {
    "common": 1.0,
    "uncommon": 1.18,
    "rare": 1.4,
    "epic": 1.72,
    "legendary": 2.05,
}
const LEVELUP_ALLOWED_EFFECT_TYPES: Dictionary = {
    "attack_damage_flat": true,
    "melee_damage_flat": true,
    "ranged_damage_flat": true,
    "auto_attack_interval_mult": true,
    "crit_chance_flat": true,
    "crit_multiplier_flat": true,
    "armor_flat": true,
    "dodge_chance_flat": true,
    "max_hp_flat": true,
    "lifesteal_flat": true,
    "luck_flat": true,
    "harvest_flat": true,
    "move_speed_flat": true,
    "target_range_flat": true,
    "stamina_recover_mult": true,
    "xp_gain_mult": true,
    "gold_gain_mult": true,
}
const LEVELUP_ALLOWED_REWARD_IDS: Dictionary = {
    "atk_flat_1": true,
    "melee_damage_flat_2": true,
    "ranged_damage_flat_2": true,
    "range_up_40": true,
    "move_up_6": true,
    "hp_flat_3": true,
    "armor_up_2": true,
    "dodge_up_5": true,
    "atk_rate_10": true,
    "atk_rate_8": true,
    "crit_chance_8": true,
    "crit_damage_25": true,
    "lifesteal_3": true,
    "luck_up_8": true,
    "xp_gain_10": true,
    "gold_gain_10": true,
    "fortune_protocol": true,
    "stamina_regen_10": true,
}

static func build_reward_context(run_state: Dictionary) -> Dictionary:
    return {
        "stage_id": str(run_state.get("stage_id", "stage_001")),
        "level": int(run_state.get("level", 1)),
        "hp_ratio": float(run_state.get("hp_ratio", 1.0)),
        "difficulty": str(run_state.get("difficulty", "normal")),
        "luck": float(run_state.get("luck", 0.0)),
        "build_tags": run_state.get("build_tags", []),
        "history": run_state.get("history", []),
        "recent_categories": run_state.get("recent_categories", []),
        "pity_state": run_state.get("pity_state", {"no_output_streak": 0}),
        "owned_rewards": run_state.get("owned_rewards", {}),
    }

static func get_reward_choices(context: Dictionary) -> Array[Dictionary]:
    var catalog: Dictionary = BalanceService.get_reward_catalog()
    var rewards: Array = catalog.get("rewards", [])
    var rules: Dictionary = catalog.get("rules", {})
    var choices_count: int = max(1, int(rules.get("choices_count", 3)))
    var same_category_max_streak: int = max(1, int(rules.get("same_category_max_streak", 2)))
    var no_output_soft_pity: int = max(1, int(rules.get("no_output_soft_pity", 3)))
    var require_two_axes: bool = bool(rules.get("require_two_axes", true))

    var stage_id: String = str(context.get("stage_id", "stage_001"))
    var stage_index: int = _parse_stage_index(stage_id)
    var level: int = int(context.get("level", 1))
    var recent_categories: Array = context.get("recent_categories", [])
    var pity_state: Dictionary = context.get("pity_state", {"no_output_streak": 0})
    var no_output_streak: int = int(pity_state.get("no_output_streak", 0))
    var owned_rewards: Dictionary = context.get("owned_rewards", {})
    var luck_value: float = float(context.get("luck", 0.0))
    var luck_rarity_step: float = _get_luck_rarity_step()

    var rarity_weights_raw: Variant = catalog.get("rarity_weights", {"common": 1.0})
    var rarity_stage_gates_raw: Variant = catalog.get("rarity_stage_gates", {})
    var reward_rarity_weights: Dictionary = _filter_rarity_weights_by_stage(
        rarity_weights_raw,
        stage_index,
        rarity_stage_gates_raw
    )
    var pool_weights: Dictionary = {}
    var raw_pools: Dictionary = catalog.get("pools", {})
    for pool_name: String in raw_pools.keys():
        var pool_entry: Dictionary = raw_pools.get(pool_name, {})
        pool_weights[pool_name] = max(0.0, float(pool_entry.get("weight", 0.0)))

    var candidates: Array[Dictionary] = []
    for reward_value in rewards:
        if not (reward_value is Dictionary):
            continue
        var reward: Dictionary = reward_value
        var reward_id: String = str(reward.get("id", ""))
        if reward_id.is_empty():
            continue
        if not _is_levelup_reward_candidate(reward):
            continue

        var max_stacks: int = max(1, int(reward.get("max_stacks", 1)))
        var owned_count: int = int(owned_rewards.get(reward_id, 0))
        if owned_count >= max_stacks:
            continue

        var require_rule: Dictionary = reward.get("require", {})
        if not require_rule.is_empty():
            var min_level: int = int(require_rule.get("min_level", 1))
            if level < min_level:
                continue

        var category: String = str(reward.get("category", "basic_growth"))
        if recent_categories.size() >= same_category_max_streak:
            var all_same: bool = true
            var start_index: int = recent_categories.size() - same_category_max_streak
            for i in range(start_index, recent_categories.size()):
                if str(recent_categories[i]) != category:
                    all_same = false
                    break
            if all_same:
                continue

        var rarity_tiers: Array[String] = _resolve_reward_rarity_tiers(reward, stage_index, rarity_stage_gates_raw)
        var category_weight: float = max(0.01, float(pool_weights.get(category, 1.0)))
        for rarity_tier: String in rarity_tiers:
            var rarity_weight: float = _adjust_rarity_weight_by_luck(
                rarity_tier,
                max(0.0, float(reward_rarity_weights.get(rarity_tier, 0.0))),
                luck_value,
                luck_rarity_step
            )
            if rarity_weight <= 0.0:
                continue
            var runtime_reward: Dictionary = reward.duplicate(true)
            runtime_reward["rarity"] = rarity_tier
            runtime_reward["effects"] = _scale_effects_by_rarity(
                _extract_effects_array(reward.get("effects", [])),
                rarity_tier,
                reward.get("rarity_scaling", {})
            )
            runtime_reward["_base_id"] = reward_id
            runtime_reward["_resolved_id"] = _compose_reward_choice_id(reward_id, rarity_tier)
            runtime_reward["_weight"] = rarity_weight * category_weight
            candidates.append(runtime_reward)

    if candidates.is_empty():
        return _fallback_choices()

    var selected: Array[Dictionary] = []
    var require_output: bool = no_output_streak >= no_output_soft_pity
    if require_output:
        var output_candidate: Dictionary = _pick_weighted(candidates, func(r: Dictionary) -> bool:
            var tags: Array = r.get("tags", [])
            return tags.has("output")
        )
        if not output_candidate.is_empty():
            selected.append(output_candidate)
            _remove_candidates_with_base_id(candidates, str(output_candidate.get("_base_id", output_candidate.get("id", ""))))

    while selected.size() < choices_count and not candidates.is_empty():
        var picked: Dictionary = _pick_weighted(candidates)
        if picked.is_empty():
            break
        selected.append(picked)
        _remove_candidates_with_base_id(candidates, str(picked.get("_base_id", picked.get("id", ""))))

    if require_two_axes and selected.size() >= 2:
        var axes: Dictionary = {}
        for reward in selected:
            var tags: Array = reward.get("tags", [])
            if tags.has("output"):
                axes["output"] = true
            if tags.has("survival"):
                axes["survival"] = true
            if tags.has("utility") or tags.has("economy"):
                axes["utility"] = true
        if axes.size() < 2:
            for candidate in candidates:
                var tags: Array = candidate.get("tags", [])
                var would_add_axis: bool = false
                if tags.has("output") and not axes.has("output"):
                    would_add_axis = true
                elif tags.has("survival") and not axes.has("survival"):
                    would_add_axis = true
                elif (tags.has("utility") or tags.has("economy")) and not axes.has("utility"):
                    would_add_axis = true
                if would_add_axis:
                    selected[selected.size() - 1] = candidate
                    break

    if selected.size() < choices_count:
        var fallback: Array[Dictionary] = _fallback_choices()
        for item in fallback:
            if selected.size() >= choices_count:
                break
            selected.append(item)

    var result: Array[Dictionary] = []
    for reward in selected:
        var base_id: String = str(reward.get("_base_id", reward.get("id", "")))
        var localized_name: String = _localize_reward_name(base_id, str(reward.get("name", "Unknown")))
        var localized_desc: String = _localize_reward_desc(base_id, str(reward.get("desc", "")))
        result.append({
            "id": str(reward.get("_resolved_id", reward.get("id", ""))),
            "base_id": base_id,
            "name": localized_name,
            "desc": localized_desc,
            "category": str(reward.get("category", "basic_growth")),
            "rarity": str(reward.get("rarity", "common")),
            "tags": reward.get("tags", []),
            "effects": reward.get("effects", []),
        })
    return result

static func apply_reward(reward_id: String, player: Player, run_state: Dictionary) -> Dictionary:
    var catalog: Dictionary = BalanceService.get_reward_catalog()
    var rewards: Array = catalog.get("rewards", [])
    var parsed_id: Dictionary = _parse_reward_choice_id(reward_id)
    var base_reward_id: String = str(parsed_id.get("base_id", reward_id))
    var selected_rarity: String = str(parsed_id.get("rarity", ""))
    var selected: Dictionary = {}
    for reward_value in rewards:
        if not (reward_value is Dictionary):
            continue
        var reward: Dictionary = reward_value
        if str(reward.get("id", "")) == base_reward_id:
            selected = reward
            break
    if selected.is_empty() or player == null:
        return run_state

    var effective_rarity: String = selected_rarity
    if effective_rarity.is_empty():
        effective_rarity = str(selected.get("rarity", "common"))

    var effects: Array = _scale_effects_by_rarity(
        _extract_effects_array(selected.get("effects", [])),
        effective_rarity,
        selected.get("rarity_scaling", {})
    )
    for effect_value in effects:
        if not (effect_value is Dictionary):
            continue
        var effect: Dictionary = effect_value
        var effect_type: String = str(effect.get("type", ""))
        var effect_value_raw: Variant = effect.get("value", 0)
        if player.apply_effect(effect_type, effect_value_raw):
            continue
        match effect_type:
            "gold_gain_mult":
                var gold_mult: float = float(run_state.get("gold_gain_multiplier", 1.0))
                run_state["gold_gain_multiplier"] = clampf(gold_mult * float(effect_value_raw), 1.0, 2.5)

    var reward_history: Array = run_state.get("reward_history", [])
    reward_history.append(reward_id)
    run_state["reward_history"] = reward_history

    var recent_categories: Array = run_state.get("recent_categories", [])
    recent_categories.append(str(selected.get("category", "basic_growth")))
    if recent_categories.size() > 5:
        recent_categories = recent_categories.slice(recent_categories.size() - 5)
    run_state["recent_categories"] = recent_categories

    var pity_state: Dictionary = run_state.get("reward_pity_state", {"no_output_streak": 0})
    var tags: Array = selected.get("tags", [])
    if tags.has("output"):
        pity_state["no_output_streak"] = 0
    else:
        pity_state["no_output_streak"] = int(pity_state.get("no_output_streak", 0)) + 1
    run_state["reward_pity_state"] = pity_state

    var owned_rewards: Dictionary = run_state.get("owned_rewards", {})
    owned_rewards[base_reward_id] = int(owned_rewards.get(base_reward_id, 0)) + 1
    run_state["owned_rewards"] = owned_rewards

    var build_tags: Array = run_state.get("build_tags", [])
    for tag in tags:
        var tag_str: String = str(tag)
        if not build_tags.has(tag_str):
            build_tags.append(tag_str)
    run_state["build_tags"] = build_tags

    return run_state

static func _resolve_reward_rarity_tiers(reward: Dictionary, stage_index: int = 1, rarity_stage_gates_raw: Variant = {}) -> Array[String]:
    var result: Array[String] = []
    var tiers_raw: Variant = reward.get("rarity_tiers", [])
    if tiers_raw is Array:
        for entry in tiers_raw:
            var tier: String = str(entry).strip_edges().to_lower()
            if tier.is_empty():
                continue
            if not result.has(tier):
                result.append(tier)
    if result.is_empty():
        var fallback_rarity: String = str(reward.get("rarity", "common")).to_lower()
        if fallback_rarity.is_empty():
            fallback_rarity = "common"
        result.append(fallback_rarity)
    if result.has("epic") and _is_rarity_unlocked("legendary", stage_index, rarity_stage_gates_raw) and not result.has("legendary"):
        result.append("legendary")
    return _filter_rarity_tiers_by_stage(result, stage_index, rarity_stage_gates_raw)

static func _filter_rarity_weights_by_stage(weights_raw: Variant, stage_index: int, rarity_stage_gates_raw: Variant) -> Dictionary:
    var weights: Dictionary = {}
    if weights_raw is Dictionary:
        weights = weights_raw
    if weights.is_empty():
        return {"common": 1.0}
    var filtered: Dictionary = {}
    var safe_stage_index: int = max(1, stage_index)
    for key: Variant in weights.keys():
        var rarity_key: String = str(key).strip_edges().to_lower()
        if rarity_key.is_empty():
            continue
        if not _is_rarity_unlocked(rarity_key, safe_stage_index, rarity_stage_gates_raw):
            continue
        filtered[rarity_key] = max(0.0, float(weights[key]))
    if filtered.is_empty():
        filtered["common"] = 1.0
    return filtered

static func _filter_rarity_tiers_by_stage(rarity_tiers: Array[String], stage_index: int, rarity_stage_gates_raw: Variant) -> Array[String]:
    var filtered: Array[String] = []
    for rarity_tier: String in rarity_tiers:
        var rarity_key: String = rarity_tier.strip_edges().to_lower()
        if rarity_key.is_empty():
            continue
        if not _is_rarity_unlocked(rarity_key, stage_index, rarity_stage_gates_raw):
            continue
        if not filtered.has(rarity_key):
            filtered.append(rarity_key)
    return filtered

static func _is_rarity_unlocked(rarity_tier: String, stage_index: int, rarity_stage_gates_raw: Variant) -> bool:
    if not (rarity_stage_gates_raw is Dictionary):
        return true
    var gates: Dictionary = rarity_stage_gates_raw
    var rarity_key: String = rarity_tier.strip_edges().to_lower()
    var min_stage: int = max(1, int(gates.get(rarity_key, 1)))
    return max(1, stage_index) >= min_stage

static func _parse_stage_index(stage_id: String) -> int:
    var parts: PackedStringArray = stage_id.strip_edges().split("_")
    for i: int in range(parts.size() - 1, -1, -1):
        if parts[i].is_valid_int():
            return max(1, int(parts[i]))
    return 1

static func _adjust_rarity_weight_by_luck(rarity_tier: String, base_weight: float, luck_value: float, luck_step: float) -> float:
    if base_weight <= 0.0:
        return 0.0
    var tier_index: int = _rarity_tier_index(rarity_tier)
    var modifier: float = max(0.1, 1.0 + luck_value * luck_step * float(tier_index))
    return max(0.0, base_weight * modifier)

static func _rarity_tier_index(rarity_tier: String) -> int:
    match rarity_tier.to_lower():
        "common":
            return 0
        "uncommon":
            return 1
        "rare":
            return 2
        "epic":
            return 3
        "legendary":
            return 4
        _:
            return 0

static func _get_luck_rarity_step() -> float:
    var combat_params: Dictionary = BalanceService.get_global_combat_params()
    return max(0.0, float(combat_params.get("luck_rarity_step", 0.012)))

static func _extract_effects_array(raw_effects: Variant) -> Array:
    if raw_effects is Array:
        return (raw_effects as Array).duplicate(true)
    return []

static func _get_rarity_multiplier(rarity: String, scaling_raw: Variant) -> float:
    var rarity_key: String = rarity.strip_edges().to_lower()
    var scaling: Dictionary = DEFAULT_RARITY_SCALING
    if scaling_raw is Dictionary:
        scaling = (scaling_raw as Dictionary)
    return max(0.01, float(scaling.get(rarity_key, DEFAULT_RARITY_SCALING.get(rarity_key, 1.0))))

static func _scale_effects_by_rarity(effects: Array, rarity: String, scaling_raw: Variant) -> Array:
    var multiplier: float = _get_rarity_multiplier(rarity, scaling_raw)
    if is_equal_approx(multiplier, 1.0):
        return effects.duplicate(true)
    var scaled_effects: Array = []
    for effect_value in effects:
        if not (effect_value is Dictionary):
            continue
        var effect: Dictionary = (effect_value as Dictionary).duplicate(true)
        if effect.has("value"):
            var effect_type: String = str(effect.get("type", ""))
            var raw_value: Variant = effect.get("value")
            if raw_value is float and _is_multiplier_effect_type(effect_type):
                var base_multiplier: float = float(raw_value)
                if base_multiplier >= 1.0:
                    effect["value"] = 1.0 + (base_multiplier - 1.0) * multiplier
                else:
                    effect["value"] = max(0.05, 1.0 - (1.0 - base_multiplier) * multiplier)
            elif raw_value is int:
                var base_int: int = int(raw_value)
                var scaled_int: int = int(round(float(base_int) * multiplier))
                if scaled_int == 0 and base_int != 0:
                    scaled_int = 1 if base_int > 0 else -1
                effect["value"] = scaled_int
            elif raw_value is float:
                effect["value"] = float(raw_value) * multiplier
        scaled_effects.append(effect)
    return scaled_effects

static func _is_multiplier_effect_type(effect_type: String) -> bool:
    return (
        effect_type == "auto_attack_interval_mult"
        or effect_type == "attack_speed_mult"
        or effect_type == "xp_gain_mult"
        or effect_type == "gold_gain_mult"
        or effect_type == "stamina_recover_mult"
    )

static func _compose_reward_choice_id(base_id: String, rarity: String) -> String:
    var rarity_key: String = rarity.strip_edges().to_lower()
    if rarity_key.is_empty():
        return base_id
    return "%s%s%s" % [base_id, REWARD_ID_RARITY_SEPARATOR, rarity_key]

static func _parse_reward_choice_id(choice_id: String) -> Dictionary:
    var parsed: Dictionary = {
        "base_id": choice_id,
        "rarity": "",
    }
    if choice_id.find(REWARD_ID_RARITY_SEPARATOR) < 0:
        return parsed
    var parts: PackedStringArray = choice_id.split(REWARD_ID_RARITY_SEPARATOR, false, 1)
    if parts.size() >= 1:
        parsed["base_id"] = parts[0]
    if parts.size() >= 2:
        parsed["rarity"] = parts[1].to_lower()
    return parsed

static func _remove_candidates_with_base_id(candidates: Array[Dictionary], base_id: String) -> void:
    if base_id.is_empty():
        return
    for i: int in range(candidates.size() - 1, -1, -1):
        var candidate: Dictionary = candidates[i]
        var candidate_base_id: String = str(candidate.get("_base_id", candidate.get("id", "")))
        if candidate_base_id == base_id:
            candidates.remove_at(i)

static func _pick_weighted(candidates: Array[Dictionary], predicate: Callable = Callable()) -> Dictionary:
    var filtered: Array[Dictionary] = []
    for candidate in candidates:
        if not predicate.is_null() and not predicate.call(candidate):
            continue
        filtered.append(candidate)
    if filtered.is_empty():
        return {}
    var total_weight: float = 0.0
    for item in filtered:
        total_weight += max(0.0, float(item.get("_weight", 1.0)))
    if total_weight <= 0.0001:
        return filtered[randi() % filtered.size()]
    var roll: float = randf() * total_weight
    var acc: float = 0.0
    for item in filtered:
        acc += max(0.0, float(item.get("_weight", 1.0)))
        if roll <= acc:
            return item
    return filtered[filtered.size() - 1]

static func _is_levelup_reward_candidate(reward: Dictionary) -> bool:
    var reward_id: String = str(reward.get("id", ""))
    if reward_id.is_empty():
        return false
    if not bool(LEVELUP_ALLOWED_REWARD_IDS.get(reward_id, false)):
        return false
    var effects: Array = _extract_effects_array(reward.get("effects", []))
    if effects.size() != 1:
        return false
    var effect_value: Variant = effects[0]
    if not (effect_value is Dictionary):
        return false
    var effect: Dictionary = effect_value
    var effect_type: String = str(effect.get("type", ""))
    return bool(LEVELUP_ALLOWED_EFFECT_TYPES.get(effect_type, false))

static func _fallback_choices() -> Array[Dictionary]:
    return [
        {"id":"atk_flat_1", "name":"Attack +1 [COMMON]", "desc":"Base attack damage +1", "category":"basic_growth", "rarity":"common", "tags":["output"], "effects":[{"type":"attack_damage_flat","value":1}]},
        {"id":"hp_flat_3", "name":"Max HP +3 [COMMON]", "desc":"Max HP +3", "category":"survival_counter", "rarity":"common", "tags":["survival"], "effects":[{"type":"max_hp_flat","value":3}]},
        {"id":"move_up_6", "name":"Move Speed +6 [COMMON]", "desc":"Move speed +6", "category":"basic_growth", "rarity":"common", "tags":["utility"], "effects":[{"type":"move_speed_flat","value":6}]}
    ]

static func _localize_reward_name(reward_id: String, fallback: String) -> String:
    if LocaleService == null:
        return fallback
    return LocaleService.t_data("reward", reward_id, "name", fallback)

static func _localize_reward_desc(reward_id: String, fallback: String) -> String:
    if LocaleService == null:
        return fallback
    return LocaleService.t_data("reward", reward_id, "desc", fallback)
