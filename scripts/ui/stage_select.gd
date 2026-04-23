extends Control

const TOTAL_STAGE_COUNT: int = 15

func _ready() -> void :
    _build_stage_buttons()
    %BackButton.pressed.connect(_on_back_button_pressed)

func _build_stage_buttons() -> void:
    var list_root: VBoxContainer = $VBoxContainer
    if list_root == null:
        return

    var stage_one_button: Button = %StageOneButton
    var insert_at: int = stage_one_button.get_index()
    stage_one_button.queue_free()

    var scroll := ScrollContainer.new()
    scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.custom_minimum_size = Vector2(0.0, 260.0)
    list_root.add_child(scroll)
    list_root.move_child(scroll, insert_at)

    var stage_list := VBoxContainer.new()
    stage_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    stage_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
    stage_list.add_theme_constant_override("separation", 8)
    scroll.add_child(stage_list)

    for stage_no: int in range(1, TOTAL_STAGE_COUNT + 1):
        var stage_id: String = "stage_%03d" % stage_no
        var button := Button.new()
        button.text = _tf("ui.stage_select.stage_fmt", [stage_no], "Stage %02d")
        button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        button.focus_mode = Control.FOCUS_ALL
        button.pressed.connect(_on_stage_button_pressed.bind(stage_id))
        stage_list.add_child(button)

func _on_stage_button_pressed(stage_id: String) -> void:
    GameManager.start_game(stage_id)

func _on_back_button_pressed() -> void :
    GameManager.go_to_character_select()

func _tf(key: String, args: Array, fallback: String = "") -> String:
    if LocaleService != null:
        return LocaleService.tf(key, args, fallback if not fallback.is_empty() else key)
    var base: String = fallback if not fallback.is_empty() else key
    return base % args
