class_name SniperEnemy
extends Enemy

const ENEMY_WARNING_ZONE_SCRIPT: Script = preload("res://scripts/effects/enemy_warning_zone.gd")

@export var desired_min_distance: float = 330.0
@export var desired_max_distance: float = 440.0
@export var attack_cooldown: float = 3.4
@export var attack_windup: float = 0.82
@export var attack_damage: int = 2
@export var projectile_speed: float = 420.0
@export var projectile_radius: float = 4.0
@export var projectile_life_time: float = 3.2
@export var warning_length: float = 720.0
@export var warning_width: float = 22.0
@export var projectile_tint: Color = Color(0.58, 0.92, 1.0, 1.0)

var _attack_cooldown_timer: float = 0.0
var _windup_timer: float = 0.0
var _aim_direction: Vector2 = Vector2.RIGHT
var _strafing_sign: float = 1.0

func _ready() -> void:
    enemy_type = EnemyType.SNIPER
    _strafing_sign = -1.0 if randi() % 2 == 0 else 1.0
    super._ready()
    _attack_cooldown_timer = attack_cooldown * randf_range(0.35, 0.8)

func _apply_profile_from_balance() -> void:
    var profile: Dictionary = BalanceService.get_enemy_profile("sniper")
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
    warning_length = float(profile.get("warning_length", warning_length))
    warning_width = float(profile.get("warning_width", warning_width))
    var tint_raw: Variant = profile.get("projectile_tint", "")
    if tint_raw is String and not str(tint_raw).is_empty():
        projectile_tint = Color(str(tint_raw))
    _hit_sfx_path = str(profile.get("hit_sfx_path", _hit_sfx_path))
    _hit_sfx_volume_db = float(profile.get("hit_sfx_volume_db", _hit_sfx_volume_db))
    _hit_sfx_cooldown = max(0.0, float(profile.get("hit_sfx_cooldown", _hit_sfx_cooldown)))

func tick_ai(delta: float) -> void:
    if _target == null:
        velocity = Vector2.ZERO
        return

    var to_player: Vector2 = _target.global_position - global_position
    var distance: float = to_player.length()
    if distance > 0.001:
        var dir_to_player: Vector2 = to_player / distance
        if _windup_timer <= 0.0:
            if distance < desired_min_distance:
                velocity = -dir_to_player * move_speed
            elif distance > desired_max_distance:
                velocity = dir_to_player * move_speed
            else:
                velocity = dir_to_player.orthogonal() * _strafing_sign * move_speed * 0.55
        else:
            velocity = Vector2.ZERO

    if _windup_timer > 0.0:
        _windup_timer = max(0.0, _windup_timer - delta)
        if _windup_timer <= 0.0:
            try_fire_projectile(_aim_direction, projectile_speed, attack_damage, projectile_radius, projectile_life_time, projectile_tint)
        return

    _attack_cooldown_timer = max(0.0, _attack_cooldown_timer - delta)
    if _attack_cooldown_timer <= 0.0 and to_player.length_squared() > 0.0001:
        _attack_cooldown_timer = attack_cooldown
        _windup_timer = attack_windup
        _aim_direction = to_player.normalized()
        _spawn_warning_line()

func _spawn_warning_line() -> void:
    if ENEMY_WARNING_ZONE_SCRIPT == null or get_parent() == null:
        return
    var zone: Node2D = ENEMY_WARNING_ZONE_SCRIPT.new() as Node2D
    if zone == null:
        return
    zone.global_position = global_position + _aim_direction * (warning_length * 0.5)
    get_parent().add_child(zone)
    zone.call("setup_line", warning_length, warning_width, attack_windup, _aim_direction.angle(), Color(0.48, 0.92, 1.0, 1.0))

func get_display_name() -> String:
    return "Sniper Glitch"

func _draw() -> void:
    if not _visual_has_sprite:
        draw_circle(Vector2.ZERO, body_radius + 2.0, Color(0.03, 0.08, 0.16, 0.92))
        draw_circle(Vector2.ZERO, body_radius, Color(0.48, 0.92, 1.0, 1.0))
        if _windup_timer > 0.0:
            draw_line(Vector2.ZERO, _aim_direction * (body_radius + 10.0), Color(0.88, 1.0, 1.0, 0.82), 2.0)
    if not _should_draw_health_bar():
        return
    var hp_ratio: float = float(current_hp) / float(max(max_hp, 1))
    var bar_width: float = 22.0
    var bar_height: float = 3.0
    var bar_pos: Vector2 = Vector2(-bar_width * 0.5, body_radius + 6.0)
    draw_rect(Rect2(bar_pos, Vector2(bar_width, bar_height)), Color(0.04, 0.12, 0.18, 0.9), true)
    draw_rect(Rect2(bar_pos, Vector2(bar_width * hp_ratio, bar_height)), Color(0.48, 0.92, 1.0, 1.0), true)
