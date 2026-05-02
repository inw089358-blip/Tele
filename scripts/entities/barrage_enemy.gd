class_name BarrageEnemy
extends Enemy

@export var desired_min_distance: float = 190.0
@export var desired_max_distance: float = 280.0
@export var ring_attack_cooldown: float = 3.0
@export var ring_windup: float = 0.35
@export var ring_projectile_count: int = 8
@export var ring_projectile_damage: int = 1
@export var ring_projectile_speed: float = 210.0
@export var ring_projectile_radius: float = 5.0
@export var ring_projectile_life_time: float = 4.2
@export var ring_rotation_step_deg: float = 14.0

var _attack_cooldown_timer: float = 0.0
var _windup_timer: float = 0.0
var _shot_rotation_rad: float = 0.0
var _strafe_sign: float = 1.0

func _ready() -> void :
    enemy_type = EnemyType.BARRAGE
    _strafe_sign = -1.0 if randi() % 2 == 0 else 1.0
    super._ready()
    _attack_cooldown_timer = ring_attack_cooldown * randf_range(0.35, 0.85)

func _apply_profile_from_balance() -> void:
    var profile: Dictionary = BalanceService.get_enemy_profile("barrage")
    move_speed = float(profile.get("move_speed", move_speed))
    max_hp = int(profile.get("max_hp", max_hp))
    body_radius = float(profile.get("body_radius", body_radius))
    xp_drop_amount = int(profile.get("xp_drop", xp_drop_amount))

    desired_min_distance = float(profile.get("desired_min_distance", desired_min_distance))
    desired_max_distance = float(profile.get("desired_max_distance", desired_max_distance))
    ring_attack_cooldown = float(profile.get("ring_attack_cooldown", ring_attack_cooldown))
    ring_windup = float(profile.get("ring_windup", ring_windup))
    ring_projectile_count = int(profile.get("ring_projectile_count", ring_projectile_count))
    ring_projectile_damage = int(profile.get("ring_projectile_damage", ring_projectile_damage))
    ring_projectile_speed = float(profile.get("ring_projectile_speed", ring_projectile_speed))
    ring_projectile_radius = float(profile.get("ring_projectile_radius", ring_projectile_radius))
    ring_projectile_life_time = float(profile.get("ring_projectile_life_time", ring_projectile_life_time))
    ring_rotation_step_deg = float(profile.get("ring_rotation_step_deg", ring_rotation_step_deg))
    _hit_sfx_path = str(profile.get("hit_sfx_path", _hit_sfx_path))
    _hit_sfx_volume_db = float(profile.get("hit_sfx_volume_db", _hit_sfx_volume_db))
    _hit_sfx_cooldown = max(0.0, float(profile.get("hit_sfx_cooldown", _hit_sfx_cooldown)))

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
            move_dir = dir_to_player.orthogonal() * _strafe_sign

    velocity = move_dir.normalized() * move_speed if move_dir.length_squared() > 0.0001 else Vector2.ZERO

    if _windup_timer > 0.0:
        _windup_timer = max(0.0, _windup_timer - delta)
        if _windup_timer <= 0.0:
            _fire_ring_barrage()
        return

    _attack_cooldown_timer = max(0.0, _attack_cooldown_timer - delta)
    if _attack_cooldown_timer <= 0.0:
        _attack_cooldown_timer = ring_attack_cooldown
        _windup_timer = ring_windup

func _fire_ring_barrage() -> void:
    var projectile_count: int = max(4, ring_projectile_count)
    var step: float = TAU / float(projectile_count)
    for i: int in range(projectile_count):
        var angle: float = _shot_rotation_rad + step * float(i)
        var fire_dir: Vector2 = Vector2.RIGHT.rotated(angle)
        try_fire_projectile(
            fire_dir,
            ring_projectile_speed,
            ring_projectile_damage,
            ring_projectile_radius,
            ring_projectile_life_time,
            Color(1.0, 0.22, 0.22, 1.0)
        )
    _shot_rotation_rad += deg_to_rad(ring_rotation_step_deg)
    queue_redraw()

func get_display_name() -> String:
    return "Pulse Idol"

func _draw() -> void :
    if not _visual_has_sprite:
        draw_circle(Vector2.ZERO, body_radius + 2.4, Color(0.18, 0.05, 0.09, 0.92))
        draw_circle(Vector2.ZERO, body_radius, Color(0.84, 0.18, 0.35, 1.0))
        draw_arc(Vector2.ZERO, body_radius + 4.0, _shot_rotation_rad, _shot_rotation_rad + PI * 1.4, 24, Color(1.0, 0.52, 0.62, 0.78), 1.4)
    if not _should_draw_health_bar():
        return
    var hp_ratio: float = float(current_hp) / float(max(max_hp, 1))
    var bar_width: float = 24.0
    var bar_height: float = 4.0
    var bar_pos: Vector2 = Vector2( - bar_width * 0.5, body_radius + 7.0)
    draw_rect(Rect2(bar_pos, Vector2(bar_width, bar_height)), Color(0.24, 0.1, 0.12, 0.9), true)
    draw_rect(Rect2(bar_pos, Vector2(bar_width * hp_ratio, bar_height)), Color(0.92, 0.26, 0.45, 1.0), true)
