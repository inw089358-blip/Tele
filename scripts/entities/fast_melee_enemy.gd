class_name FastMeleeEnemy
extends Enemy

func _ready() -> void:
    enemy_type = EnemyType.FAST_MELEE
    super._ready()

func _apply_profile_from_balance() -> void:
    var profile: Dictionary = BalanceService.get_enemy_profile("fast_melee")
    move_speed = float(profile.get("move_speed", move_speed))
    max_hp = int(profile.get("max_hp", max_hp))
    body_radius = float(profile.get("body_radius", body_radius))
    xp_drop_amount = int(profile.get("xp_drop", xp_drop_amount))
    _hit_sfx_path = str(profile.get("hit_sfx_path", _hit_sfx_path))
    _hit_sfx_volume_db = float(profile.get("hit_sfx_volume_db", _hit_sfx_volume_db))
    _hit_sfx_cooldown = max(0.0, float(profile.get("hit_sfx_cooldown", _hit_sfx_cooldown)))

func get_display_name() -> String:
    return "Pixel Stalker"

func _draw() -> void:
    if not _visual_has_sprite:
        draw_circle(Vector2.ZERO, body_radius + 2.0, Color(0.08, 0.03, 0.16, 0.92))
        draw_circle(Vector2.ZERO, body_radius, Color(0.66, 0.36, 1.0, 1.0))
    if not _should_draw_health_bar():
        return
    var hp_ratio: float = float(current_hp) / float(max(max_hp, 1))
    var bar_width: float = 20.0
    var bar_height: float = 3.0
    var bar_pos: Vector2 = Vector2(-bar_width * 0.5, body_radius + 6.0)
    draw_rect(Rect2(bar_pos, Vector2(bar_width, bar_height)), Color(0.16, 0.08, 0.2, 0.9), true)
    draw_rect(Rect2(bar_pos, Vector2(bar_width * hp_ratio, bar_height)), Color(0.72, 0.48, 1.0, 1.0), true)
