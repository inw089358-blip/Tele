class_name TheFool
extends Player

func _ready() -> void :
    var profile: Dictionary = BalanceService.get_character_profile("the_fool")
    apply_profile(profile)
    setup_visual_from_config(
        {
            "sprite_sheet_path": "res://sprite/characters/the_fool/battle_sheet.png",
            "hframes": 8,
            "vframes": 8,
            "idle_frame": 0,
            "move_frames": [0, 1, 2, 3, 4, 5, 6, 7],
            "directional_idle_frames": {
                "down": 0,
                "side": 8,
                "up": 16,
            },
            "directional_move_frames": {
                "down": [0, 1, 2, 3, 4, 5, 6, 7],
                "side": [8, 9, 10, 11, 12, 13, 14, 15],
                "up": [16, 17, 18, 19, 20, 21, 22, 23],
            },
            "default_direction": "down",
            "anim_fps": 8.0,
            "flip_with_velocity": true,
            "scale": 1.1,
        }
    )
    super._ready()
