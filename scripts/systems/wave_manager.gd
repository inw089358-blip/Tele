class_name WaveManager
extends Node

@export var total_waves: int = 3

var current_wave: int = 0
var current_stage_balance: Dictionary = {}
var wave_definitions: Array[Dictionary] = []

func load_stage_balance(stage_id: String) -> Dictionary:
    current_stage_balance = BalanceService.get_stage_profile(stage_id)
    _rebuild_wave_definitions()
    return current_stage_balance.duplicate(true)

func start_stage() -> void :
    load_stage_balance(GameManager.current_stage_id)
    # Stage-only progression: each stage always runs as a single wave.
    current_wave = 1
    GameManager.current_wave = current_wave
    EventBus.wave_started.emit(current_wave)

func clear_current_wave() -> void :
    EventBus.wave_cleared.emit(current_wave)
    if current_wave >= total_waves:
        EventBus.stage_cleared.emit(GameManager.current_stage_id)
        return
    current_wave += 1
    GameManager.current_wave = current_wave
    EventBus.wave_started.emit(current_wave)

func advance_wave_or_open_shop(runtime_snapshot: Dictionary = {}) -> Dictionary:
    EventBus.wave_cleared.emit(current_wave)
    if is_final_wave():
        return {
            "action": "stage_complete",
            "wave": current_wave,
        }
    var wave_snapshot: Dictionary = runtime_snapshot.duplicate(true)
    wave_snapshot["wave"] = current_wave + 1
    wave_snapshot["wave_progress_index"] = current_wave
    GameManager.open_wave_shop(wave_snapshot)
    return {
        "action": "shop_opened",
        "wave": current_wave,
    }

func is_final_wave() -> bool:
    return current_wave >= max(1, wave_definitions.size())

func get_current_wave_definition() -> Dictionary:
    if wave_definitions.is_empty():
        _rebuild_wave_definitions()
    if wave_definitions.is_empty():
        return {}
    var index: int = clampi(current_wave - 1, 0, wave_definitions.size() - 1)
    return wave_definitions[index].duplicate(true)

func build_wave_runtime_snapshot(base_snapshot: Dictionary) -> Dictionary:
    var snapshot: Dictionary = base_snapshot.duplicate(true)
    snapshot["wave"] = current_wave
    snapshot["wave_progress_index"] = max(0, current_wave - 1)
    return snapshot

func _rebuild_wave_definitions() -> void:
    wave_definitions = []
    var raw_waves: Variant = current_stage_balance.get("waves", [])
    if raw_waves is Array:
        for wave_value in raw_waves:
            if wave_value is Dictionary:
                wave_definitions.append(wave_value.duplicate(true))
    if not wave_definitions.is_empty():
        total_waves = wave_definitions.size()
        return

    # Backward compatibility: generate waves from legacy target_duration.
    var spawn_profile: Dictionary = current_stage_balance.get("spawn_profile", {})
    var target_duration: float = max(1.0, float(spawn_profile.get("target_duration", 30.0)))
    total_waves = max(1, total_waves)
    for i in range(total_waves):
        wave_definitions.append({
            "wave_index": i + 1,
            "duration": target_duration,
            "shop_enabled": i < total_waves - 1,
            "reward_gold": 0,
            "reward_xp": 0,
        })
