class_name RangedEnemy
extends Enemy

@export var desired_min_distance: float = 260.0
@export var desired_max_distance: float = 340.0
@export var attack_cooldown: float = 2.2
@export var attack_windup: float = 0.45
@export var attack_damage: int = 10
@export var projectile_speed: float = 260.0
@export var projectile_radius: float = 5.0
@export var projectile_life_time: float = 4.0
@export var projectile_tint: Color = Color("#b3001a")

var _attack_cooldown_timer: float = 0.0
var _windup_timer: float = 0.0
var _strafing_sign: float = 1.0

func _ready() -> void :
    enemy_type = EnemyType.RANGED
    _strafing_sign = -1.0 if randi() % 2 == 0 else 1.0
    super._ready()

func _apply_profile_from_balance() -> void:
    var profile: Dictionary = BalanceService.get_enemy_profile("ranged")
    move_speed = float(profile.get("move_speed", move_speed))
    max_hp = int(profile.get("max_hp", max_hp))
    body_radius = float(profile.get("body_radius", body_radius))
    xp_drop_amount = int(profile.get("xp_drop", xp_drop_amount))
    desired_min_distance = float(profile.get("desired_min_distance", desired_min_distance))
    desired_max_distance = float(profile.get("desired_max_distance", desired_max_distance))
    attack_cooldown = float(profile.get("attack_cooldown", attack_cooldown))
    attack_windup = float(profile.get("attack_windup", attack_windup))
    attack_damage = int(profile.get("attack_damage", attack_damage))
    projectile_speed = float(profile.get("projectile_speed", projectile_speed))
    projectile_radius = float(profile.get("projectile_radius", projectile_radius))
    projectile_life_time = float(profile.get("projectile_life_time", projectile_life_time))
    var tint_raw: Variant = profile.get("projectile_tint", "")
    if tint_raw is String and not str(tint_raw).is_empty():
        projectile_tint = Color(str(tint_raw))

func tick_ai(delta: float) -> void :
    if _target == null:
        velocity = Vector2.ZERO
        return

    var to_player: Vector2 = _target.global_position - global_position
    var distance: float = to_player.length()
    var move_dir: Vector2 = Vector2.ZERO

    if distance > 0.001:
        var dir_to_player: Vector2 = to_player / distance
        if distance < desired_min_distance:
            move_dir = -dir_to_player
        elif distance > desired_max_distance:
            move_dir = dir_to_player
        else:
            move_dir = dir_to_player.orthogonal() * _strafing_sign

    velocity = move_dir.normalized() * move_speed if move_dir.length_squared() > 0.0001 else Vector2.ZERO

    if _windup_timer > 0.0:
        _windup_timer = max(0.0, _windup_timer - delta)
        if _windup_timer <= 0.0 and to_player.length_squared() > 0.0001:
            try_fire_projectile(
                to_player.normalized(),
                projectile_speed,
                attack_damage,
                projectile_radius,
                projectile_life_time,
                projectile_tint
            )
        return

    _attack_cooldown_timer = max(0.0, _attack_cooldown_timer - delta)
    if _attack_cooldown_timer <= 0.0:
        _attack_cooldown_timer = attack_cooldown
        _windup_timer = attack_windup

func get_display_name() -> String:
    return "Static Sprite"

func _draw() -> void :
    if not _visual_has_sprite:
        draw_circle(Vector2.ZERO, body_radius + 2.0, Color(0.16, 0.06, 0.07, 0.92))
        draw_circle(Vector2.ZERO, body_radius, Color(0.96, 0.55, 0.46, 1.0))
    if not _should_draw_health_bar():
        return
    var hp_ratio: float = float(current_hp) / float(max(max_hp, 1))
    var bar_width: float = 24.0
    var bar_height: float = 4.0
    var bar_pos: Vector2 = Vector2( - bar_width * 0.5, body_radius + 7.0)
    draw_rect(Rect2(bar_pos, Vector2(bar_width, bar_height)), Color(0.24, 0.1, 0.1, 0.9), true)
    draw_rect(Rect2(bar_pos, Vector2(bar_width * hp_ratio, bar_height)), Color(1.0, 0.54, 0.46, 1.0), true)
