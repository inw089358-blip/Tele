class_name TheHangedMan
extends Player

func _ready() -> void :
    var profile: Dictionary = BalanceService.get_character_profile("the_hanged_man")
    apply_profile(profile)
    super._ready()
