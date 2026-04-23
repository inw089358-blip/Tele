extends Control

@onready var title_label: Label = %TitleLabel
@onready var subtitle_label: Label = %SubtitleLabel
@onready var stage_value_label: Label = %StageValueLabel
@onready var wave_value_label: Label = %WaveValueLabel
@onready var mode_value_label: Label = %ModeValueLabel
@onready var best_stage_value_label: Label = %BestStageValueLabel
@onready var total_kills_value_label: Label = %TotalKillsValueLabel
@onready var total_gold_value_label: Label = %TotalGoldValueLabel
@onready var retry_button: Button = %RetryButton
@onready var menu_button: Button = %BackToMenuButton

func _ready() -> void:
    _apply_result_copy()
    _apply_stat_values()
    retry_button.text = _tx("ui.game_over.retry", "Retry")
    menu_button.text = _tx("ui.game_over.back_to_menu", "Back to Menu")
    retry_button.pressed.connect(_on_retry_pressed)
    menu_button.pressed.connect(_on_back_to_menu_pressed)

func _apply_result_copy() -> void:
    if GameManager.current_state == GameManager.GameState.VICTORY:
        title_label.text = _tx("ui.game_over.victory_title", "Victory")
        subtitle_label.text = _tx("ui.game_over.victory_subtitle", "Dream cleared, signal route stabilized.")
        return
    title_label.text = _tx("ui.game_over.defeat_title", "Defeat")
    subtitle_label.text = _tx("ui.game_over.defeat_subtitle", "Signal interrupted, reconnect and try again.")

func _apply_stat_values() -> void:
    var save_data: Dictionary = SaveSystem.load_save()
    stage_value_label.text = str(GameManager.current_stage_id)
    wave_value_label.text = _tf("ui.common.wave_fmt", [max(1, int(GameManager.current_wave))], "WAVE %d")
    mode_value_label.text = _difficulty_label(str(GameManager.current_difficulty))
    best_stage_value_label.text = str(save_data.get("best_stage", "stage_001"))
    total_kills_value_label.text = str(int(save_data.get("total_kills", 0)))
    total_gold_value_label.text = str(int(save_data.get("total_gold", 0)))

func _on_retry_pressed() -> void:
    GameManager.start_game(GameManager.current_stage_id)

func _on_back_to_menu_pressed() -> void:
    GameManager.go_to_menu()

func _difficulty_label(raw: String) -> String:
    var value: String = raw.to_lower()
    match value:
        "easy":
            return _tx("ui.difficulty.easy", "Easy")
        "hard":
            return _tx("ui.difficulty.hard", "Hard")
        _:
            return _tx("ui.difficulty.normal", "Normal")

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
