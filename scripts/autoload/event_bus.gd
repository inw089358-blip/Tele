extends Node

signal game_state_changed(from: int, to: int)
signal player_died
signal level_up(new_level: int)
signal wave_started(wave_id: int)
signal wave_cleared(wave_id: int)
signal reward_offered(choices: Array)
signal reward_selected(upgrade_id: String, payload: Dictionary)
signal stage_cleared(stage_id: String)
signal game_over(is_victory: bool)
