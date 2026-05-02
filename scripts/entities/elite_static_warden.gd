class_name EliteStaticWarden
extends Enemy

const ENEMY_WARNING_ZONE_SCRIPT: Script = preload("res://scripts/effects/enemy_warning_zone.gd")

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
@export var static_mine_interval: float = 7.5
@export var static_mine_warning: float = 1.0
@export var static_mine_radius: float = 46.0
@export var static_mine_damage: int = 2
@export var shield_shock_projectile_count: int = 8
@export var shield_shock_damage: int = 1
@export var shield_shock_speed: float = 180.0

var _shield_cooldown_timer: float = 0.0
var _shield_timer: float = 0.0
var _heavy_bolt_timer: float = 0.0
var _tri_burst_timer: float = 0.0
var _static_mine_timer: float = 0.0
var _pending_mechanic_attacks: Array[Dictionary] = []

func _ready() -> void :
    enemy_type = EnemyType.ELITE_WARDEN
    is_elite = true
    super._ready()
    _shield_cooldown_timer = shield_interval
    _heavy_bolt_timer = heavy_bolt_interval * 0.6
    _tri_burst_timer = tri_burst_interval
    _static_mine_timer = static_mine_interval * 0.5
    _pending_mechanic_attacks.clear()

func _apply_profile_from_balance() -> void:
    var profile: Dictionary = BalanceService.get_enemy_profile("elite_warden")
    move_speed = float(profile.get("move_speed", move_speed))
    max_hp = int(profile.get("max_hp", max_hp))
    body_radius = float(profile.get("body_radius", 22.0))
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
    static_mine_interval = float(profile.get("static_mine_interval", static_mine_interval))
    static_mine_warning = float(profile.get("static_mine_warning", static_mine_warning))
    static_mine_radius = float(profile.get("static_mine_radius", static_mine_radius))
    static_mine_damage = int(profile.get("static_mine_damage", static_mine_damage))
    shield_shock_projectile_count = int(profile.get("shield_shock_projectile_count", shield_shock_projectile_count))
    shield_shock_damage = int(profile.get("shield_shock_damage", shield_shock_damage))
    shield_shock_speed = float(profile.get("shield_shock_speed", shield_shock_speed))
    _hit_sfx_path = str(profile.get("hit_sfx_path", _hit_sfx_path))
    _hit_sfx_volume_db = float(profile.get("hit_sfx_volume_db", _hit_sfx_volume_db))
    _hit_sfx_cooldown = max(0.0, float(profile.get("hit_sfx_cooldown", _hit_sfx_cooldown)))

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

    _tick_pending_mechanic_attacks(delta)

    _shield_cooldown_timer = max(0.0, _shield_cooldown_timer - delta)
    if _shield_timer > 0.0:
        _shield_timer = max(0.0, _shield_timer - delta)
    elif _shield_cooldown_timer <= 0.0:
        _shield_timer = shield_duration
        _shield_cooldown_timer = shield_interval
        _fire_shield_shock()

    damage_reduction_ratio = shield_damage_reduction if _shield_timer > 0.0 else 0.0

    _static_mine_timer = max(0.0, _static_mine_timer - delta)
    if _static_mine_timer <= 0.0:
        _static_mine_timer = static_mine_interval
        _schedule_static_mine()

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

func _schedule_static_mine() -> void:
    if _target == null or not is_instance_valid(_target):
        return
    var offset: Vector2 = Vector2.RIGHT.rotated(randf() * TAU) * randf_range(12.0, 86.0)
    var center: Vector2 = _target.global_position + offset
    _spawn_warning_circle(center, static_mine_radius, static_mine_warning, Color(0.34, 0.95, 1.0, 1.0))
    _pending_mechanic_attacks.append({
        "delay": static_mine_warning,
        "center": center,
        "radius": static_mine_radius,
        "damage": static_mine_damage,
    })

func _fire_shield_shock() -> void:
    var count: int = max(1, shield_shock_projectile_count)
    for i: int in range(count):
        var direction: Vector2 = Vector2.RIGHT.rotated(float(i) * TAU / float(count))
        try_fire_projectile(direction, shield_shock_speed, shield_shock_damage, 4.5, 3.8, Color(0.34, 0.95, 1.0, 1.0))

func _tick_pending_mechanic_attacks(delta: float) -> void:
    var index: int = 0
    while index < _pending_mechanic_attacks.size():
        var attack: Dictionary = _pending_mechanic_attacks[index]
        attack["delay"] = float(attack.get("delay", 0.0)) - delta
        if float(attack["delay"]) <= 0.0:
            _damage_player_in_circle(
                attack.get("center", global_position),
                float(attack.get("radius", static_mine_radius)),
                int(attack.get("damage", static_mine_damage))
            )
            _pending_mechanic_attacks.remove_at(index)
        else:
            _pending_mechanic_attacks[index] = attack
            index += 1

func _spawn_warning_circle(center: Vector2, radius: float, duration: float, tint: Color) -> void:
    if ENEMY_WARNING_ZONE_SCRIPT == null or get_parent() == null:
        return
    var zone: Node2D = ENEMY_WARNING_ZONE_SCRIPT.new() as Node2D
    if zone == null:
        return
    zone.global_position = center
    get_parent().add_child(zone)
    zone.call("setup_circle", radius, duration, tint)

func _damage_player_in_circle(center: Vector2, radius: float, damage: int) -> void:
    if _target == null or not is_instance_valid(_target) or not (_target is Player):
        return
    var player: Player = _target as Player
    if player.global_position.distance_squared_to(center) <= pow(radius + player.body_radius, 2.0):
        player.take_damage(scale_outgoing_damage(damage))

func get_display_name() -> String:
    return "Static Warden"

func _draw() -> void :
    if not _visual_has_sprite:
        draw_circle(Vector2.ZERO, body_radius + 6.0, Color(0.08, 0.01, 0.02, 0.96))
        draw_circle(Vector2.ZERO, body_radius + 3.0, Color(0.72, 0.08, 0.1, 0.96))
        draw_circle(Vector2.ZERO, body_radius, Color(1.0, 0.22, 0.18, 1.0))
    draw_arc(Vector2.ZERO, body_radius + 5.0, 0.0, TAU, 64, Color(1.0, 0.85, 0.4, 1.0), 3.0)

    if _shield_timer > 0.0:
        draw_arc(Vector2.ZERO, body_radius + 10.0, 0.0, TAU, 64, Color(0.34, 0.95, 1.0, 0.98), 4.0)

    var hp_ratio: float = float(current_hp) / float(max(max_hp, 1))
    var bar_width: float = 84.0
    var bar_height: float = 9.0
    var bar_pos: Vector2 = Vector2(-bar_width * 0.5, body_radius + 16.0)
    draw_rect(Rect2(bar_pos - Vector2(1.0, 1.0), Vector2(bar_width + 2.0, bar_height + 2.0)), Color(0.02, 0.0, 0.0, 0.96), true)
    draw_rect(Rect2(bar_pos, Vector2(bar_width, bar_height)), Color(0.16, 0.02, 0.03, 0.96), true)
    draw_rect(Rect2(bar_pos, Vector2(bar_width * hp_ratio, bar_height)), Color(1.0, 0.3, 0.2, 1.0), true)
