extends Control

func _ready() -> void :
    %BackToMenuButton.pressed.connect(_on_back_to_menu_pressed)

func _on_back_to_menu_pressed() -> void :
    GameManager.go_to_menu()
