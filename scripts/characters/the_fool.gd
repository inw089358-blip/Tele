class_name TheFool
extends Player

func _ready() -> void :
    var profile: Dictionary = BalanceService.get_character_profile("the_fool")
    apply_profile(profile)
    super._ready()
