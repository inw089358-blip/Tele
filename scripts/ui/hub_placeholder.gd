extends Control

@onready var continue_button: Button = %ContinueButton
@onready var stage_select_button: Button = %StageSelectButton

func _ready() -> void :
    continue_button.pressed.connect(_on_continue_pressed)
    stage_select_button.pressed.connect(_on_stage_select_pressed)

func _on_continue_pressed() -> void :
    GameManager.go_to_menu()

func _on_stage_select_pressed() -> void :
    var character_id: String = GameManager.selected_character
    if character_id.is_empty():
        character_id = "the_fool"
    GameManager.go_to_stage_select(character_id)
