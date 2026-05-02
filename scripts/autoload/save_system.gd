extends Node

const LEGACY_SAVE_PATH: String = "user://save_data.json"
const SAVE_SLOT_PATH: String = "user://save_slots.json"
const SLOT_IDS: PackedStringArray = ["slot_1", "slot_2", "slot_3"]
const XP_CURVE_LEVEL_OFFSET_DEFAULT: int = 3
const XP_CURVE_BASE_MULT_DEFAULT: float = 1.0
const XP_REQUIRED_MIN_DEFAULT: int = 1
const ATTACK_FLAT_TO_GLOBAL_ATTACK_PERCENT_DEFAULT: float = 3.0
const CRIT_MULTIPLIER_TO_CRIT_CHANCE_RATIO_DEFAULT: float = 0.12
const DEFAULT_SETTINGS: Dictionary = {
    "display": {
        "resolution": "1920x1080", 
        "window_mode": "fullscreen", 
        "vsync": true, 
        "fps_cap": 60, 
        "crt_intensity": "high", 
        "ui_scale": 100, 
    }, 
    "audio": {
        "master_volume": 80, 
        "music_volume": 70, 
        "sfx_volume": 90, 
        "ui_volume": 80, 
    }, 
    "input": {
        "right_click_skill": true, 
    }, 
    "accessibility": {
        "colorblind_mode": "off", 
        "high_contrast_ui": false, 
        "font_size": "medium", 
        "glitch_intensity": "mid", 
        "simple_ui": false, 
    }, 
    "system": {
        "language": "zh_CN", 
        "show_boss_test_entry": false,
    }, 
}

func load_save() -> Dictionary:
    var slot_data: Dictionary = load_from_slot(SLOT_IDS[0])
    if slot_data.is_empty():
        var fallback_save: Dictionary = _default_save()
        var root: Dictionary = _load_slot_root()
        var root_settings: Variant = root.get("settings", {})
        if root_settings is Dictionary:
            fallback_save["settings"] = _normalize_settings(root_settings)
        return fallback_save
    return slot_data

func write_save(data: Dictionary) -> void :
    save_to_slot(SLOT_IDS[0], data)
    _write_legacy_save(_normalize_save_data(data))

func get_settings() -> Dictionary:
    var save_data: Dictionary = load_save()
    return _normalize_settings(save_data.get("settings", {}))

func list_save_slots() -> Array[Dictionary]:
    var root: Dictionary = _load_slot_root()
    var slots: Dictionary = _extract_slots_dict(root)
    var list: Array[Dictionary] = []

    for slot_id: String in SLOT_IDS:
        var slot_entry_value: Variant = slots.get(slot_id, {})
        var slot_entry: Dictionary = {}
        if slot_entry_value is Dictionary:
            slot_entry = slot_entry_value
        var has_data: bool = not slot_entry.is_empty()
        var summary: Dictionary = {
            "slot_id": slot_id, 
            "has_data": has_data, 
        }
        if has_data:
            summary["stage_id"] = str(slot_entry.get("stage_id", "stage_001"))
            summary["wave"] = int(slot_entry.get("wave", 1))
            summary["selected_character"] = str(slot_entry.get("selected_character", "the_fool"))
            summary["difficulty"] = _normalize_difficulty(str(slot_entry.get("difficulty", "danger_1")))
            summary["saved_at"] = str(slot_entry.get("saved_at", ""))
        list.append(summary)

    return list

func load_from_slot(slot_id: String) -> Dictionary:
    if not _is_valid_slot_id(slot_id):
        return {}

    var root: Dictionary = _load_slot_root()
    var slots: Dictionary = _extract_slots_dict(root)
    var raw_value: Variant = slots.get(slot_id, {})
    if not (raw_value is Dictionary):
        return {}

    var raw_slot: Dictionary = raw_value
    if raw_slot.is_empty():
        return {}

    return _normalize_save_data(raw_slot)

func save_to_slot(slot_id: String, data: Dictionary) -> void :
    if not _is_valid_slot_id(slot_id):
        return

    var root: Dictionary = _load_slot_root()
    var slots: Dictionary = _extract_slots_dict(root)
    var normalized: Dictionary = _normalize_save_data(data)
    slots[slot_id] = normalized
    root["slots"] = slots
    root["settings"] = _normalize_settings(normalized.get("settings", {}))
    _write_slot_root(root)

    if slot_id == SLOT_IDS[0]:
        _write_legacy_save(normalized)

func _load_slot_root() -> Dictionary:
    if FileAccess.file_exists(SAVE_SLOT_PATH):
        var parsed_slot_root: Dictionary = _read_json_dict(SAVE_SLOT_PATH)
        if not parsed_slot_root.is_empty():
            return _normalize_slot_root(parsed_slot_root)

    if FileAccess.file_exists(LEGACY_SAVE_PATH):
        var legacy: Dictionary = _read_json_dict(LEGACY_SAVE_PATH)
        if not legacy.is_empty():
            var migrated_root: Dictionary = _normalize_slot_root({})
            var migrated_slots: Dictionary = _extract_slots_dict(migrated_root)
            migrated_slots[SLOT_IDS[0]] = _normalize_save_data(legacy)
            migrated_root["slots"] = migrated_slots
            _write_slot_root(migrated_root)
            return migrated_root

    return _normalize_slot_root({})

func _write_slot_root(root: Dictionary) -> void :
    var file: FileAccess = FileAccess.open(SAVE_SLOT_PATH, FileAccess.WRITE)
    if file == null:
        return
    file.store_string(JSON.stringify(root, "\t"))

func _write_legacy_save(data: Dictionary) -> void :
    var file: FileAccess = FileAccess.open(LEGACY_SAVE_PATH, FileAccess.WRITE)
    if file == null:
        return
    file.store_string(JSON.stringify(data, "\t"))

func _read_json_dict(path: String) -> Dictionary:
    var file: FileAccess = FileAccess.open(path, FileAccess.READ)
    if file == null:
        return {}

    var raw_text: String = file.get_as_text()
    var parsed: Variant = JSON.parse_string(raw_text)
    if parsed is Dictionary:
        var parsed_dict: Dictionary = parsed
        return parsed_dict
    return {}

func _normalize_slot_root(raw_root: Dictionary) -> Dictionary:
    var slots: Dictionary = _extract_slots_dict(raw_root)
    var normalized: Dictionary = {"slots": slots}
    var settings_value: Variant = raw_root.get("settings", {})
    if settings_value is Dictionary:
        normalized["settings"] = _normalize_settings(settings_value)
    return normalized

func _extract_slots_dict(root: Dictionary) -> Dictionary:
    var slots_value: Variant = root.get("slots", {})
    if slots_value is Dictionary:
        var slots: Dictionary = slots_value
        return slots
    return {}

func _normalize_save_data(input_data: Dictionary) -> Dictionary:
    var normalized: Dictionary = _default_save()
    var unlocked_characters: Array[String] = _normalize_character_array(input_data.get("unlocked_characters", ["the_fool"]))
    var default_character: String = unlocked_characters[0] if not unlocked_characters.is_empty() else "the_fool"
    normalized["unlocked_characters"] = unlocked_characters
    normalized["best_stage"] = str(input_data.get("best_stage", "stage_001"))
    normalized["total_kills"] = int(input_data.get("total_kills", 0))
    normalized["total_gold"] = int(input_data.get("total_gold", 0))
    normalized["total_play_time"] = float(input_data.get("total_play_time", 0.0))
    normalized["run_survival_time"] = max(0.0, float(input_data.get("run_survival_time", 0.0)))
    normalized["selected_character"] = str(input_data.get("selected_character", default_character))
    normalized["selected_starter_weapon_id"] = str(input_data.get("selected_starter_weapon_id", ""))
    normalized["difficulty"] = _normalize_difficulty(str(input_data.get("difficulty", "normal")))
    var best_stage: String = str(normalized.get("best_stage", "stage_001"))
    normalized["stage_id"] = str(input_data.get("stage_id", best_stage))
    normalized["wave"] = max(1, int(input_data.get("wave", 1)))
    normalized["wave_progress_index"] = max(0, int(input_data.get("wave_progress_index", normalized["wave"] - 1)))
    normalized["player_hp"] = int(input_data.get("player_hp", 100))
    normalized["player_max_hp"] = int(input_data.get("player_max_hp", 100))
    normalized["player_stamina"] = float(input_data.get("player_stamina", 100.0))
    normalized["player_stamina_max"] = float(input_data.get("player_stamina_max", 100.0))
    normalized["player_move_speed"] = float(input_data.get("player_move_speed", 220.0))
    normalized["bonus_target_range"] = float(input_data.get("bonus_target_range", 0.0))
    var legacy_bonus_attack_damage: int = int(input_data.get("bonus_attack_damage", 0))
    normalized["bonus_attack_damage"] = legacy_bonus_attack_damage
    var player_stats_value: Variant = input_data.get("player_stats", {})
    if player_stats_value is Dictionary:
        normalized["player_stats"] = (player_stats_value as Dictionary).duplicate(true)
    else:
        normalized["player_stats"] = {}
    var normalized_player_stats: Dictionary = normalized.get("player_stats", {})
    if (
        legacy_bonus_attack_damage != 0
        and not normalized_player_stats.has("global_attack_percent")
    ):
        normalized_player_stats["global_attack_percent"] = (
            float(legacy_bonus_attack_damage) * _get_attack_flat_to_global_attack_percent()
        )
    if not normalized_player_stats.has("global_attack_percent"):
        normalized_player_stats["global_attack_percent"] = 0.0
    if not normalized_player_stats.has("luck"):
        normalized_player_stats["luck"] = 0.0
    if not normalized_player_stats.has("harvest"):
        normalized_player_stats["harvest"] = 0.0
    if not normalized_player_stats.has("hp_regen"):
        normalized_player_stats["hp_regen"] = 0.0
    if normalized_player_stats.has("crit_multiplier"):
        var selected_character_id: String = str(normalized.get("selected_character", "the_fool"))
        var character_profile: Dictionary = BalanceService.get_character_profile(selected_character_id)
        var base_crit_multiplier: float = max(1.0, float(character_profile.get("crit_multiplier", 1.5)))
        var legacy_crit_multiplier: float = max(1.0, float(normalized_player_stats.get("crit_multiplier", base_crit_multiplier)))
        var delta_crit_multiplier: float = legacy_crit_multiplier - base_crit_multiplier
        if absf(delta_crit_multiplier) > 0.0001:
            var base_crit_chance: float = float(character_profile.get("crit_chance", 0.05))
            var existing_crit_chance: float = float(normalized_player_stats.get("crit_chance", base_crit_chance))
            normalized_player_stats["crit_chance"] = existing_crit_chance + delta_crit_multiplier * _get_crit_multiplier_to_crit_chance_ratio()
        normalized_player_stats.erase("crit_multiplier")
    normalized["player_stats"] = normalized_player_stats
    var current_level: int = max(1, int(input_data.get("current_level", 1)))
    normalized["current_level"] = current_level
    normalized["current_xp"] = max(0, int(input_data.get("current_xp", 0)))
    normalized["current_gold"] = max(0, int(input_data.get("current_gold", 0)))
    normalized["shop_runtime_state"] = _normalize_shop_runtime_state(input_data.get("shop_runtime_state", {}))
    normalized["equipped_weapons"] = _normalize_variant_array(input_data.get("equipped_weapons", []))
    normalized["locked_shop_offers"] = _normalize_variant_array(input_data.get("locked_shop_offers", []))
    normalized["reward_history"] = _normalize_string_array(input_data.get("reward_history", []))
    normalized["recent_categories"] = _normalize_string_array(input_data.get("recent_categories", []))
    normalized["build_tags"] = _normalize_string_array(input_data.get("build_tags", []))
    var pity_value: Variant = input_data.get("reward_pity_state", {"no_output_streak": 0})
    if pity_value is Dictionary:
        normalized["reward_pity_state"] = pity_value
    else:
        normalized["reward_pity_state"] = {"no_output_streak": 0}
    var reward_owned_value: Variant = input_data.get("reward_owned", {})
    if reward_owned_value is Dictionary:
        normalized["reward_owned"] = reward_owned_value
    else:
        normalized["reward_owned"] = {}
    normalized["auto_attack_interval_multiplier"] = float(input_data.get("auto_attack_interval_multiplier", 1.0))
    normalized["gold_gain_multiplier"] = float(input_data.get("gold_gain_multiplier", 1.0))
    normalized["is_endless_mode"] = bool(input_data.get("is_endless_mode", false))
    normalized["endless_elapsed"] = max(0.0, float(input_data.get("endless_elapsed", 0.0)))
    normalized["endless_level"] = max(0, int(input_data.get("endless_level", 0)))
    normalized["endless_shop_timer"] = max(0.0, float(input_data.get("endless_shop_timer", 0.0)))
    normalized["endless_base_max_enemy_count"] = max(0, int(input_data.get("endless_base_max_enemy_count", 0)))
    var selected_character_id: String = str(normalized.get("selected_character", "the_fool"))
    var xp_required_mult: float = _resolve_character_xp_required_multiplier(selected_character_id)
    var xp_to_next_default: int = _xp_required_for_level(current_level, xp_required_mult)
    if input_data.has("xp_to_next_level"):
        var raw_xp_to_next: int = max(1, int(input_data.get("xp_to_next_level", xp_to_next_default)))
        if current_level == 1 and raw_xp_to_next == 10:
            raw_xp_to_next = xp_to_next_default
        normalized["xp_to_next_level"] = raw_xp_to_next
    else:
        normalized["xp_to_next_level"] = xp_to_next_default
    normalized["player_pos_x"] = float(input_data.get("player_pos_x", 0.0))
    normalized["player_pos_y"] = float(input_data.get("player_pos_y", 0.0))
    normalized["settings"] = _normalize_settings(input_data.get("settings", {}))
    normalized["saved_at"] = str(input_data.get("saved_at", _build_timestamp()))
    return normalized

func _normalize_settings(settings_value: Variant) -> Dictionary:
    var settings_root: Dictionary = {}
    if settings_value is Dictionary:
        settings_root = settings_value

    var normalized: Dictionary = DEFAULT_SETTINGS.duplicate(true)

    var display_input: Dictionary = {}
    var display_value: Variant = settings_root.get("display", {})
    if display_value is Dictionary:
        display_input = display_value
    var display_root: Dictionary = normalized["display"]
    display_root["resolution"] = str(display_input.get("resolution", display_root["resolution"]))
    display_root["window_mode"] = str(display_input.get("window_mode", display_root["window_mode"]))
    display_root["vsync"] = bool(display_input.get("vsync", display_root["vsync"]))
    display_root["fps_cap"] = int(display_input.get("fps_cap", display_root["fps_cap"]))
    # CRT intensity is fixed at runtime and exposed as read-only in settings.
    display_root["crt_intensity"] = "high"
    display_root["ui_scale"] = clamp(int(display_input.get("ui_scale", display_root["ui_scale"])), 80, 120)

    var audio_input: Dictionary = {}
    var audio_value: Variant = settings_root.get("audio", {})
    if audio_value is Dictionary:
        audio_input = audio_value
    var audio_root: Dictionary = normalized["audio"]
    audio_root["master_volume"] = clamp(int(audio_input.get("master_volume", audio_root["master_volume"])), 0, 100)
    audio_root["music_volume"] = clamp(int(audio_input.get("music_volume", audio_root["music_volume"])), 0, 100)
    audio_root["sfx_volume"] = clamp(int(audio_input.get("sfx_volume", audio_root["sfx_volume"])), 0, 100)
    audio_root["ui_volume"] = clamp(int(audio_input.get("ui_volume", audio_root["ui_volume"])), 0, 100)

    var input_input: Dictionary = {}
    var input_value: Variant = settings_root.get("input", {})
    if input_value is Dictionary:
        input_input = input_value
    var input_root: Dictionary = normalized["input"]
    input_root["right_click_skill"] = bool(input_input.get("right_click_skill", input_root["right_click_skill"]))

    var accessibility_input: Dictionary = {}
    var accessibility_value: Variant = settings_root.get("accessibility", {})
    if accessibility_value is Dictionary:
        accessibility_input = accessibility_value
    var accessibility_root: Dictionary = normalized["accessibility"]
    accessibility_root["colorblind_mode"] = str(accessibility_input.get("colorblind_mode", accessibility_root["colorblind_mode"]))
    accessibility_root["high_contrast_ui"] = bool(accessibility_input.get("high_contrast_ui", accessibility_root["high_contrast_ui"]))
    accessibility_root["font_size"] = str(accessibility_input.get("font_size", accessibility_root["font_size"]))
    accessibility_root["glitch_intensity"] = str(accessibility_input.get("glitch_intensity", accessibility_root["glitch_intensity"]))
    accessibility_root["simple_ui"] = bool(accessibility_input.get("simple_ui", accessibility_root["simple_ui"]))

    var system_input: Dictionary = {}
    var system_value: Variant = settings_root.get("system", {})
    if system_value is Dictionary:
        system_input = system_value
    var system_root: Dictionary = normalized["system"]
    system_root["language"] = _normalize_language(str(system_input.get("language", system_root["language"])))
    system_root["show_boss_test_entry"] = bool(system_input.get("show_boss_test_entry", system_root["show_boss_test_entry"]))

    return normalized

func _normalize_character_array(value: Variant) -> Array[String]:
    var characters: Array[String] = []
    if value is Array:
        var raw: Array = value
        for item: Variant in raw:
            var character_id: String = str(item)
            if character_id.is_empty():
                continue
            if not characters.has(character_id):
                characters.append(character_id)

    if characters.is_empty():
        characters.append("the_fool")
    return characters

func _build_timestamp() -> String:
    var dt: Dictionary = Time.get_datetime_dict_from_system()
    var year: int = int(dt.get("year", 1970))
    var month: int = int(dt.get("month", 1))
    var day: int = int(dt.get("day", 1))
    var hour: int = int(dt.get("hour", 0))
    var minute: int = int(dt.get("minute", 0))
    var second: int = int(dt.get("second", 0))
    return "%04d-%02d-%02d %02d:%02d:%02d" % [year, month, day, hour, minute, second]

func _is_valid_slot_id(slot_id: String) -> bool:
    return SLOT_IDS.has(slot_id)

func _xp_required_for_level(current_level: int, xp_required_mult: float = 1.0) -> int:
    var combat_params: Dictionary = BalanceService.get_global_combat_params()
    var target_level: int = max(1, current_level)
    var level_offset: int = int(combat_params.get("xp_curve_level_offset", XP_CURVE_LEVEL_OFFSET_DEFAULT))
    var base_multiplier: float = max(0.01, float(combat_params.get("xp_curve_base_multiplier", XP_CURVE_BASE_MULT_DEFAULT)))
    var min_required: int = max(1, int(combat_params.get("xp_required_min", XP_REQUIRED_MIN_DEFAULT)))
    var curve_value: float = float(target_level + level_offset)
    var required: int = int(round(curve_value * curve_value * base_multiplier * clampf(xp_required_mult, 0.2, 5.0)))
    return max(min_required, required)

func _resolve_character_xp_required_multiplier(character_id: String) -> float:
    if character_id.is_empty():
        return 1.0
    var character_profile: Dictionary = BalanceService.get_character_profile(character_id)
    return clampf(float(character_profile.get("xp_required_mult", 1.0)), 0.2, 5.0)

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

func _default_save() -> Dictionary:
    return {
        "unlocked_characters": ["the_fool"], 
        "best_stage": "stage_001", 
        "total_kills": 0, 
        "total_gold": 0, 
        "total_play_time": 0.0, 
        "run_survival_time": 0.0,
        "selected_character": "the_fool", 
        "selected_starter_weapon_id": "",
        "difficulty": "danger_1",
        "stage_id": "stage_001", 
        "wave": 1, 
        "wave_progress_index": 0,
        "player_hp": 100, 
        "player_max_hp": 100, 
        "player_stamina": 100.0, 
        "player_stamina_max": 100.0, 
        "player_move_speed": 220.0, 
        "bonus_target_range": 0.0, 
        "bonus_attack_damage": 0, 
        "player_stats": {
            "global_attack_percent": 0.0,
            "harvest": 0.0,
            "hp_regen": 0.0,
        },
        "current_level": 1, 
        "current_xp": 0, 
        "current_gold": 0, 
        "shop_runtime_state": {
            "equipped_weapons": [],
            "inventory_overflow": [],
            "locked_shop_offers": [],
            "refresh_count": 0,
            "shop_locked": false,
            "owned_items": [],
        },
        "equipped_weapons": [],
        "locked_shop_offers": [],
        "reward_history": [],
        "recent_categories": [],
        "build_tags": [],
        "reward_pity_state": {"no_output_streak": 0},
        "reward_owned": {},
          "auto_attack_interval_multiplier": 1.0,
          "gold_gain_multiplier": 1.0,
          "is_endless_mode": false,
          "endless_elapsed": 0.0,
          "endless_level": 0,
          "endless_shop_timer": 0.0,
          "endless_base_max_enemy_count": 0,
          "xp_to_next_level": _xp_required_for_level(1),
          "player_pos_x": 0.0,
          "player_pos_y": 0.0,
          "settings": DEFAULT_SETTINGS.duplicate(true),
          "saved_at": "",
    }

func _normalize_difficulty(raw_value: String) -> String:
    var lowered: String = raw_value.to_lower()
    if lowered.begins_with("danger_"):
        var danger_value: String = lowered.substr(7)
        if not danger_value.is_valid_int():
            return "danger_1"
        var danger_level: int = clampi(int(danger_value), 0, 5)
        return "danger_%d" % danger_level
    if lowered == "easy":
        return "danger_0"
    if lowered == "hard":
        return "danger_4"
    if lowered == "normal":
        return "danger_1"
    if lowered.is_valid_int():
        var numeric_level: int = clampi(int(lowered), 0, 5)
        return "danger_%d" % numeric_level
    if lowered == "d0" or lowered == "d1" or lowered == "d2" or lowered == "d3" or lowered == "d4" or lowered == "d5":
        return "danger_%s" % lowered.substr(1)
    if lowered == "danger0" or lowered == "danger1" or lowered == "danger2" or lowered == "danger3" or lowered == "danger4" or lowered == "danger5":
        return "danger_%s" % lowered.substr(6)
    return "danger_1"

func _normalize_string_array(value: Variant) -> Array[String]:
    var result: Array[String] = []
    if value is Array:
        var raw: Array = value
        for item in raw:
            var text: String = str(item)
            if text.is_empty():
                continue
            result.append(text)
    return result

func _normalize_variant_array(value: Variant) -> Array:
    if value is Array:
        var raw: Array = value
        return raw.duplicate(true)
    return []

func _normalize_shop_runtime_state(value: Variant) -> Dictionary:
    var normalized: Dictionary = {
        "equipped_weapons": [],
        "inventory_overflow": [],
        "locked_shop_offers": [],
        "refresh_count": 0,
        "shop_locked": false,
        "owned_items": [],
    }
    if value is Dictionary:
        var source: Dictionary = value
        normalized["equipped_weapons"] = _normalize_variant_array(source.get("equipped_weapons", []))
        normalized["inventory_overflow"] = _normalize_variant_array(source.get("inventory_overflow", []))
        normalized["locked_shop_offers"] = _normalize_variant_array(source.get("locked_shop_offers", []))
        normalized["refresh_count"] = max(0, int(source.get("refresh_count", 0)))
        normalized["owned_items"] = _normalize_variant_array(source.get("owned_items", []))
    normalized["shop_locked"] = false
    return normalized

func _normalize_language(raw_value: String) -> String:
    if raw_value == "en_US":
        return "en_US"
    return "zh_CN"
