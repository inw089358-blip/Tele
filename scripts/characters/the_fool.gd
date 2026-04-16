class_name TheFool
extends Player

func _ready() -> void :
    var profile: Dictionary = BalanceService.get_character_profile("the_fool")
    move_speed = float(profile.get("move_speed", move_speed))
    max_hp = int(profile.get("max_hp", max_hp))
    base_target_range = float(profile.get("base_target_range", base_target_range))
    super._ready()
