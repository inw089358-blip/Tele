extends Control

const CHARACTER_IDS: PackedStringArray = [
    "the_fool", 
    "the_chariot", 
    "the_hanged_man", 
]

const CHARACTER_NAMES: PackedStringArray = [
    "愚者", 
    "战车", 
    "倒吊人", 
]

const CHARACTER_HINTS: PackedStringArray = [
    "高机动，容错较低", 
    "高生命，稳健推进", 
    "均衡属性，节奏控制", 
]

const CHARACTER_COLORS: Array[Color] = [
    Color(0.756863, 0.690196, 0.545098, 1), 
    Color(0.666667, 0.4, 0.356863, 1), 
    Color(0.54902, 0.647059, 0.780392, 1), 
]

@onready var left_arrow_button: Button = %LeftArrowButton
@onready var right_arrow_button: Button = %RightArrowButton
@onready var select_button: Button = %SelectButton
@onready var back_button: Button = %BackButton
@onready var character_name_label: Label = %CharacterNameLabel
@onready var character_hint_label: Label = %CharacterHintLabel
@onready var character_silhouette: ColorRect = %CharacterSilhouette

var _current_index: int = 0

func _ready() -> void :
    left_arrow_button.pressed.connect(_on_left_arrow_pressed)
    right_arrow_button.pressed.connect(_on_right_arrow_pressed)
    select_button.pressed.connect(_on_select_button_pressed)
    back_button.pressed.connect(_on_back_button_pressed)
    _refresh_character_view()

func _unhandled_input(event: InputEvent) -> void :
    if event.is_action_pressed("move_left"):
        _on_left_arrow_pressed()
    elif event.is_action_pressed("move_right"):
        _on_right_arrow_pressed()
    elif event.is_action_pressed("confirm"):
        _on_select_button_pressed()
    elif event.is_action_pressed("cancel"):
        _on_back_button_pressed()

func _on_left_arrow_pressed() -> void :
    var character_count: int = CHARACTER_IDS.size()
    _current_index = (_current_index - 1 + character_count) % character_count
    _refresh_character_view()

func _on_right_arrow_pressed() -> void :
    var character_count: int = CHARACTER_IDS.size()
    _current_index = (_current_index + 1) % character_count
    _refresh_character_view()

func _on_select_button_pressed() -> void :
    GameManager.go_to_weapon_select(CHARACTER_IDS[_current_index])

func _on_back_button_pressed() -> void :
    GameManager.go_to_menu()

func _refresh_character_view() -> void :
    character_name_label.text = CHARACTER_NAMES[_current_index]
    character_hint_label.text = CHARACTER_HINTS[_current_index]
    character_silhouette.color = CHARACTER_COLORS[_current_index]
