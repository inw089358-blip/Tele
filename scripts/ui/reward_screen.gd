extends Control

@onready var info_label: Label = %InfoLabel

func _ready() -> void :
    info_label.text = _tx("ui.reward.placeholder", "Reward placeholder: integrate 3-choice cards later.")
    %ContinueButton.pressed.connect(_on_continue_button_pressed)

func _on_continue_button_pressed() -> void :
    GameManager.start_game(GameManager.current_stage_id)

func _tx(key: String, fallback: String = "") -> String:
    if LocaleService != null:
        return LocaleService.tx(key, fallback if not fallback.is_empty() else key)
    if fallback.is_empty():
        return key
    return fallback
