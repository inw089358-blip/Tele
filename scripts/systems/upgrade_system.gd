class_name UpgradeSystem
extends Node

static func build_reward_context(run_state: Dictionary) -> Dictionary:
    return {
        "stage_id": str(run_state.get("stage_id", "stage_001")),
        "level": int(run_state.get("level", 1)),
        "hp_ratio": float(run_state.get("hp_ratio", 1.0)),
        "difficulty": str(run_state.get("difficulty", "normal")),
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
    var level: int = int(context.get("level", 1))
    var recent_categories: Array = context.get("recent_categories", [])
    var pity_state: Dictionary = context.get("pity_state", {"no_output_streak": 0})
    var no_output_streak: int = int(pity_state.get("no_output_streak", 0))
    var owned_rewards: Dictionary = context.get("owned_rewards", {})

    var rarity_weights_by_stage: Dictionary = catalog.get("rarity_weights_by_stage", {})
    var stage_rarity_weights: Dictionary = rarity_weights_by_stage.get(stage_id, rarity_weights_by_stage.get("stage_001", {"common": 1.0}))
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

        var rarity: String = str(reward.get("rarity", "common"))
        var rarity_weight: float = max(0.0, float(stage_rarity_weights.get(rarity, 0.0)))
        if rarity_weight <= 0.0:
            continue
        var category_weight: float = max(0.01, float(pool_weights.get(category, 1.0)))
        var final_weight: float = rarity_weight * category_weight
        reward["_weight"] = final_weight
        candidates.append(reward)

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
            candidates.erase(output_candidate)

    while selected.size() < choices_count and not candidates.is_empty():
        var picked: Dictionary = _pick_weighted(candidates)
        if picked.is_empty():
            break
        selected.append(picked)
        candidates.erase(picked)

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
        result.append({
            "id": str(reward.get("id", "")),
            "name": str(reward.get("name", "Unknown")),
            "desc": str(reward.get("desc", "")),
            "category": str(reward.get("category", "basic_growth")),
            "rarity": str(reward.get("rarity", "common")),
            "tags": reward.get("tags", []),
            "effects": reward.get("effects", []),
        })
    return result

static func apply_reward(reward_id: String, player: Player, run_state: Dictionary) -> Dictionary:
    var catalog: Dictionary = BalanceService.get_reward_catalog()
    var rewards: Array = catalog.get("rewards", [])
    var selected: Dictionary = {}
    for reward_value in rewards:
        if not (reward_value is Dictionary):
            continue
        var reward: Dictionary = reward_value
        if str(reward.get("id", "")) == reward_id:
            selected = reward
            break
    if selected.is_empty() or player == null:
        return run_state

    var effects: Array = selected.get("effects", [])
    for effect_value in effects:
        if not (effect_value is Dictionary):
            continue
        var effect: Dictionary = effect_value
        var effect_type: String = str(effect.get("type", ""))
        match effect_type:
            "attack_damage_flat":
                player.add_attack_damage(int(effect.get("value", 0)))
            "target_range_flat":
                player.add_target_range(float(effect.get("value", 0.0)))
            "move_speed_flat":
                player.add_move_speed(float(effect.get("value", 0.0)) )
            "max_hp_flat":
                var delta: int = int(effect.get("value", 0))
                player.max_hp = max(1, player.max_hp + delta)
                player.current_hp = clampi(player.current_hp + delta, 0, player.max_hp)
            "heal_flat":
                var heal: int = int(effect.get("value", 0))
                player.current_hp = clampi(player.current_hp + heal, 0, player.max_hp)
            "stamina_recover_mult":
                var mult: float = float(effect.get("value", 1.0))
                player.stamina_recover_per_sec = max(1.0, player.stamina_recover_per_sec * mult)
            "auto_attack_interval_mult":
                var current_mult: float = float(run_state.get("auto_attack_interval_multiplier", 1.0))
                var new_mult: float = current_mult * float(effect.get("value", 1.0))
                run_state["auto_attack_interval_multiplier"] = clampf(new_mult, 0.45, 1.5)
            "xp_gain_mult":
                var xp_mult: float = float(run_state.get("xp_gain_multiplier", 1.0))
                run_state["xp_gain_multiplier"] = clampf(xp_mult * float(effect.get("value", 1.0)), 1.0, 2.5)
            "gold_gain_mult":
                var gold_mult: float = float(run_state.get("gold_gain_multiplier", 1.0))
                run_state["gold_gain_multiplier"] = clampf(gold_mult * float(effect.get("value", 1.0)), 1.0, 2.5)

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
    owned_rewards[reward_id] = int(owned_rewards.get(reward_id, 0)) + 1
    run_state["owned_rewards"] = owned_rewards

    var build_tags: Array = run_state.get("build_tags", [])
    for tag in tags:
        var tag_str: String = str(tag)
        if not build_tags.has(tag_str):
            build_tags.append(tag_str)
    run_state["build_tags"] = build_tags

    return run_state

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

static func _fallback_choices() -> Array[Dictionary]:
    return [
        {"id":"atk_flat_1", "name":"攻击+1", "desc":"基础攻击伤害 +1", "category":"basic_growth", "rarity":"common", "tags":["output"], "effects":[{"type":"attack_damage_flat","value":1}]},
        {"id":"hp_up_2", "name":"生命+2", "desc":"最大生命 +2 并治疗 2", "category":"survival_counter", "rarity":"common", "tags":["survival"], "effects":[{"type":"max_hp_flat","value":2},{"type":"heal_flat","value":2}]},
        {"id":"move_up_6", "name":"移速+6", "desc":"移动速度 +6", "category":"basic_growth", "rarity":"common", "tags":["utility"], "effects":[{"type":"move_speed_flat","value":6}]}
    ]
