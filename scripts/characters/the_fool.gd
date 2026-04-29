class_name TheFool
extends Player

func _ready() -> void :
    var profile: Dictionary = BalanceService.get_character_profile("the_fool")
    apply_profile(profile)
    setup_visual_from_config(
        {
            "sprite_sheet_path": "res://sprite/characters/the_fool/battle_sheet.png",
            "hframes": 6,
            "vframes": 2,
            "idle_frame": 0,
            "move_frames": [0, 1, 2, 3, 4, 5],
            "anim_fps": 10.0,
            "flip_with_velocity": true,
            "scale": 1.1,
        }
    )
    super._ready()
