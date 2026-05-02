class_name TheChariot
extends Player

func _ready() -> void :
    var profile: Dictionary = BalanceService.get_character_profile("the_chariot")
    apply_profile(profile)
    setup_visual_from_config(
        {
            "sprite_sheet_path": "res://sprite/characters/the_chariot/battle_sheet.png",
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
            "frame_offsets": {
                0: [-4, 0],
                1: [-2, 0],
                2: [-1, 0],
                4: [1, 0],
                5: [2, 0],
                6: [4, 0],
                7: [5, 0],
                8: [-2, 0],
                9: [-1, 0],
                10: [1, 0],
                11: [1, 0],
                12: [4, 0],
                13: [4, 0],
                14: [5, 0],
                15: [6, 0],
                16: [-4, 0],
                17: [-2, 0],
                18: [-1, 0],
                20: [1, 0],
                21: [2, 0],
                22: [4, 0],
                23: [5, 0],
            },
            "default_direction": "down",
            "anim_fps": 8.0,
            "flip_with_velocity": true,
            "scale": 1.15,
        }
    )
    super._ready()
