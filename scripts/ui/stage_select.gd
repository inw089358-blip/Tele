extends Control

func _ready() -> void :
    %StageOneButton.pressed.connect(_on_stage_one_pressed)
    %BackButton.pressed.connect(_on_back_button_pressed)

func _on_stage_one_pressed() -> void :
    GameManager.start_game("stage_001")

func _on_back_button_pressed() -> void :
    GameManager.go_to_character_select()
