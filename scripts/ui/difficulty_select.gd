extends Control

@onready var easy_button: Button = %EasyButton
@onready var normal_button: Button = %NormalButton
@onready var hard_button: Button = %HardButton
@onready var back_button: Button = %BackButton

func _ready() -> void :
    easy_button.pressed.connect(_on_easy_pressed)
    normal_button.pressed.connect(_on_normal_pressed)
    hard_button.pressed.connect(_on_hard_pressed)
    back_button.pressed.connect(_on_back_pressed)

func _unhandled_input(event: InputEvent) -> void :
    if event.is_action_pressed("cancel"):
        _on_back_pressed()

func _on_easy_pressed() -> void :
    GameManager.start_new_run_with_difficulty("easy")

func _on_normal_pressed() -> void :
    GameManager.start_new_run_with_difficulty("normal")

func _on_hard_pressed() -> void :
    GameManager.start_new_run_with_difficulty("hard")

func _on_back_pressed() -> void :
    GameManager.go_to_weapon_select(GameManager.selected_character)
