class_name EliteStaticWarden
extends Enemy

@export var shield_interval: float = 8.0
@export var shield_duration: float = 3.0
@export var shield_damage_reduction: float = 0.7
@export var heavy_bolt_interval: float = 2.8
@export var heavy_bolt_damage: int = 18
@export var heavy_bolt_speed: float = 240.0
@export var tri_burst_interval: float = 9.0
@export var tri_burst_damage: int = 12
@export var tri_burst_speed: float = 230.0
@export var tri_burst_angle_deg: float = 15.0

var _shield_cooldown_timer: float = 0.0
var _shield_timer: float = 0.0
var _heavy_bolt_timer: float = 0.0
var _tri_burst_timer: float = 0.0

func _ready() -> void :
    enemy_type = EnemyType.ELITE_WARDEN
    is_elite = true
    super._ready()
    _shield_cooldown_timer = shield_interval
    _heavy_bolt_timer = heavy_bolt_interval * 0.6
    _tri_burst_timer = tri_burst_interval

func _apply_profile_from_balance() -> void:
    var profile: Dictionary = BalanceService.get_enemy_profile("elite_warden")
    move_speed = float(profile.get("move_speed", move_speed))
    max_hp = int(profile.get("max_hp", max_hp))
    body_radius = float(profile.get("body_radius", body_radius))
    xp_drop_amount = int(profile.get("xp_drop", xp_drop_amount))
    shield_interval = float(profile.get("shield_interval", shield_interval))
    shield_duration = float(profile.get("shield_duration", shield_duration))
    shield_damage_reduction = float(profile.get("shield_damage_reduction", shield_damage_reduction))
    heavy_bolt_interval = float(profile.get("heavy_bolt_interval", heavy_bolt_interval))
    heavy_bolt_damage = int(profile.get("heavy_bolt_damage", heavy_bolt_damage))
    heavy_bolt_speed = float(profile.get("heavy_bolt_speed", heavy_bolt_speed))
    tri_burst_interval = float(profile.get("tri_burst_interval", tri_burst_interval))
    tri_burst_damage = int(profile.get("tri_burst_damage", tri_burst_damage))
    tri_burst_speed = float(profile.get("tri_burst_speed", tri_burst_speed))
    tri_burst_angle_deg = float(profile.get("tri_burst_angle_deg", tri_burst_angle_deg))

func tick_ai(delta: float) -> void :
    if _target == null:
        velocity = Vector2.ZERO
        return

    var to_player: Vector2 = _target.global_position - global_position
    var distance: float = to_player.length()
    if distance > 0.001:
        var dir_to_player: Vector2 = to_player / distance
        if distance > 300.0:
            velocity = dir_to_player * move_speed
        elif distance < 210.0:
            velocity = -dir_to_player * move_speed * 0.65
        else:
            velocity = dir_to_player.orthogonal() * move_speed * 0.4
    else:
        velocity = Vector2.ZERO

    _shield_cooldown_timer = max(0.0, _shield_cooldown_timer - delta)
    if _shield_timer > 0.0:
        _shield_timer = max(0.0, _shield_timer - delta)
    elif _shield_cooldown_timer <= 0.0:
        _shield_timer = shield_duration
        _shield_cooldown_timer = shield_interval

    damage_reduction_ratio = shield_damage_reduction if _shield_timer > 0.0 else 0.0

    _heavy_bolt_timer = max(0.0, _heavy_bolt_timer - delta)
    if _heavy_bolt_timer <= 0.0 and to_player.length_squared() > 0.0001:
        _heavy_bolt_timer = heavy_bolt_interval
        try_fire_projectile(
            to_player.normalized(),
            heavy_bolt_speed,
            heavy_bolt_damage,
            6.0,
            4.6,
            Color(1.0, 0.36, 0.3, 1.0)
        )

    _tri_burst_timer = max(0.0, _tri_burst_timer - delta)
    if _tri_burst_timer <= 0.0 and to_player.length_squared() > 0.0001:
        _tri_burst_timer = tri_burst_interval
        var base_dir: Vector2 = to_player.normalized()
        var angle: float = deg_to_rad(tri_burst_angle_deg)
        try_fire_projectile(base_dir, tri_burst_speed, tri_burst_damage, 5.0, 4.2, Color(0.94, 0.58, 0.34, 1.0))
        try_fire_projectile(base_dir.rotated(angle), tri_burst_speed, tri_burst_damage, 5.0, 4.2, Color(0.94, 0.58, 0.34, 1.0))
        try_fire_projectile(base_dir.rotated( - angle), tri_burst_speed, tri_burst_damage, 5.0, 4.2, Color(0.94, 0.58, 0.34, 1.0))

    queue_redraw()

func get_display_name() -> String:
    return "Static Warden"

func _draw() -> void :
    draw_circle(Vector2.ZERO, body_radius + 3.0, Color(0.18, 0.04, 0.04, 0.94))
    draw_circle(Vector2.ZERO, body_radius, Color(0.96, 0.2, 0.2, 1.0))

    if _shield_timer > 0.0:
        draw_arc(Vector2.ZERO, body_radius + 6.0, 0.0, TAU, 36, Color(0.4, 0.95, 1.0, 0.95), 2.0)

    var hp_ratio: float = float(current_hp) / float(max(max_hp, 1))
    var bar_width: float = 44.0
    var bar_height: float = 5.0
    var bar_pos: Vector2 = Vector2( - bar_width * 0.5, body_radius + 10.0)
    draw_rect(Rect2(bar_pos, Vector2(bar_width, bar_height)), Color(0.18, 0.1, 0.1, 0.94), true)
    draw_rect(Rect2(bar_pos, Vector2(bar_width * hp_ratio, bar_height)), Color(1.0, 0.3, 0.28, 1.0), true)
