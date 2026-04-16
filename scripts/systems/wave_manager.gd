class_name WaveManager
extends Node

@export var total_waves: int = 3

var current_wave: int = 0
var current_stage_balance: Dictionary = {}

func load_stage_balance(stage_id: String) -> Dictionary:
    current_stage_balance = BalanceService.get_stage_profile(stage_id)
    return current_stage_balance.duplicate(true)

func start_stage() -> void :
    load_stage_balance(GameManager.current_stage_id)
    current_wave = max(1, GameManager.current_wave)
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
