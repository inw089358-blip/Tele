class_name TheSun
extends Player

func _ready() -> void :
    var profile: Dictionary = BalanceService.get_character_profile("the_sun")
    apply_profile(profile)
    setup_visual_from_config(
        {
            "sprite_sheet_path": "res://sprite/characters/the_sun/battle_sheet.png",
            "hframes": 6,
            "vframes": 2,
            "idle_frame": 0,
            "move_frames": [0, 1, 2, 3, 4],
            "anim_fps": 5.0,
            "flip_with_velocity": true,
            "scale": 1.05,
        }
    )
    super._ready()
