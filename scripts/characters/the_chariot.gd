class_name TheChariot
extends Player

func _ready() -> void :
    var profile: Dictionary = BalanceService.get_character_profile("the_chariot")
    apply_profile(profile)
    super._ready()
