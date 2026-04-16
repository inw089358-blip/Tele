extends Node

const COMBAT_BALANCE_PATH: String = "res://data/balance/combat_balance.json"
const REWARD_CATALOG_PATH: String = "res://data/balance/reward_catalog.json"

var _combat_balance: Dictionary = {}
var _reward_catalog: Dictionary = {}

func _ready() -> void:
    load_all()

func load_all() -> void:
    _combat_balance = _load_json_dict(COMBAT_BALANCE_PATH)
    _reward_catalog = _load_json_dict(REWARD_CATALOG_PATH)

func get_global_combat_params() -> Dictionary:
    var global_root: Dictionary = _extract_dict(_combat_balance.get("global", {}))
    return _extract_dict(global_root.get("combat", {})).duplicate(true)

func get_character_profile(character_id: String) -> Dictionary:
    var all_profiles: Dictionary = _extract_dict(_combat_balance.get("characters", {}))
    var fallback: Dictionary = _extract_dict(all_profiles.get("the_fool", {}))
    return _extract_dict(all_profiles.get(character_id, fallback)).duplicate(true)

func get_stage_profile(stage_id: String) -> Dictionary:
    var all_profiles: Dictionary = _extract_dict(_combat_balance.get("stages", {}))
    var fallback: Dictionary = _extract_dict(all_profiles.get("stage_001", {}))
    return _extract_dict(all_profiles.get(stage_id, fallback)).duplicate(true)

func get_enemy_profile(enemy_key: String) -> Dictionary:
    var all_profiles: Dictionary = _extract_dict(_combat_balance.get("enemies", {}))
    var fallback: Dictionary = _extract_dict(all_profiles.get("melee", {}))
    return _extract_dict(all_profiles.get(enemy_key, fallback)).duplicate(true)

func get_reward_catalog() -> Dictionary:
    return _reward_catalog.duplicate(true)

func _load_json_dict(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        return {}
    var file: FileAccess = FileAccess.open(path, FileAccess.READ)
    if file == null:
        return {}
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    if parsed is Dictionary:
        return parsed
    return {}

func _extract_dict(value: Variant) -> Dictionary:
    if value is Dictionary:
        return value
    return {}
