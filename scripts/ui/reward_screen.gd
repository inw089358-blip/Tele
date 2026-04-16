extends Control

@onready var info_label: Label = %InfoLabel

func _ready() -> void :
    info_label.text = "奖励占位界面：后续接入三选一卡片。"
    %ContinueButton.pressed.connect(_on_continue_button_pressed)

func _on_continue_button_pressed() -> void :
    GameManager.start_game(GameManager.current_stage_id)
