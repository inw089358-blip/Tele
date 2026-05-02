class_name EliteClockworkSeer
extends Enemy

const ENEMY_WARNING_ZONE_SCRIPT: Script = preload("res://scripts/effects/enemy_warning_zone.gd")

@export var desired_min_distance: float = 260.0
@export var desired_max_distance: float = 380.0
@export var burst_interval: float = 3.2
@export var burst_damage: int = 1
@export var burst_speed: float = 230.0
@export var burst_angle_deg: float = 18.0
@export var strike_interval: float = 5.8
@export var strike_warning: float = 1.05
@export var strike_radius: float = 52.0
@export var strike_damage: int = 2
@export var radial_interval: float = 9.5
@export var radial_count: int = 8
@export var radial_damage: int = 1
@export var radial_speed: float = 190.0

var _burst_timer: float = 0.0
var _strike_timer: float = 0.0
var _radial_timer: float = 0.0
var _strafe_sign: float = 1.0
var _pending_strikes: Array[Dictionary] = []

func _ready() -> void:
    enemy_type = EnemyType.ELITE_CLOCKWORK_SEER
    is_elite = true
    _strafe_sign = -1.0 if randi() % 2 == 0 else 1.0
    super._ready()
    _burst_timer = burst_interval * 0.55
    _strike_timer = strike_interval * 0.4
    _radial_timer = radial_interval * 0.75

func _apply_profile_from_balance() -> void:
    var profile: Dictionary = BalanceService.get_enemy_profile("elite_clockwork_seer")
    move_speed = float(profile.get("move_speed", move_speed))
    max_hp = int(profile.get("max_hp", max_hp))
    body_radius = float(profile.get("body_radius", body_radius))
    xp_drop_amount = int(profile.get("xp_drop", xp_drop_amount))
    desired_min_distance = float(profile.get("desired_min_distance", desired_min_distance))
    desired_max_distance = float(profile.get("desired_max_distance", desired_max_distance))
    burst_interval = float(profile.get("burst_interval", burst_interval))
    burst_damage = int(profile.get("burst_damage", burst_damage))
    burst_speed = float(profile.get("burst_speed", burst_speed))
    burst_angle_deg = float(profile.get("burst_angle_deg", burst_angle_deg))
    strike_interval = float(profile.get("strike_interval", strike_interval))
    strike_warning = float(profile.get("strike_warning", strike_warning))
    strike_radius = float(profile.get("strike_radius", strike_radius))
    strike_damage = int(profile.get("strike_damage", strike_damage))
    radial_interval = float(profile.get("radial_interval", radial_interval))
    radial_count = int(profile.get("radial_count", radial_count))
    radial_damage = int(profile.get("radial_damage", radial_damage))
    radial_speed = float(profile.get("radial_speed", radial_speed))
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
        if distance < desired_min_distance:
            velocity = -dir_to_player * move_speed
        elif distance > desired_max_distance:
            velocity = dir_to_player * move_speed
        else:
            velocity = dir_to_player.orthogonal() * _strafe_sign * move_speed * 0.45

    _tick_pending_strikes(delta)
    _burst_timer = max(0.0, _burst_timer - delta)
    if _burst_timer <= 0.0 and to_player.length_squared() > 0.0001:
        _burst_timer = burst_interval
        _fire_triple_burst(to_player.normalized())

    _strike_timer = max(0.0, _strike_timer - delta)
    if _strike_timer <= 0.0:
        _strike_timer = strike_interval
        _schedule_orbital_strike()

    _radial_timer = max(0.0, _radial_timer - delta)
    if _radial_timer <= 0.0:
        _radial_timer = radial_interval
        _fire_radial_pulse()
    queue_redraw()

func _fire_triple_burst(base_dir: Vector2) -> void:
    var angle: float = deg_to_rad(burst_angle_deg)
    try_fire_projectile(base_dir, burst_speed, burst_damage, 5.0, 4.0, Color(0.44, 0.96, 1.0, 1.0))
    try_fire_projectile(base_dir.rotated(angle), burst_speed, burst_damage, 5.0, 4.0, Color(0.44, 0.96, 1.0, 1.0))
    try_fire_projectile(base_dir.rotated(-angle), burst_speed, burst_damage, 5.0, 4.0, Color(0.44, 0.96, 1.0, 1.0))

func _schedule_orbital_strike() -> void:
    if _target == null or not is_instance_valid(_target):
        return
    var center: Vector2 = _target.global_position + Vector2.RIGHT.rotated(randf() * TAU) * randf_range(0.0, 80.0)
    _spawn_warning_circle(center, strike_radius, strike_warning)
    _pending_strikes.append({
        "delay": strike_warning,
        "center": center,
        "radius": strike_radius,
        "damage": strike_damage,
    })

func _spawn_warning_circle(center: Vector2, radius: float, duration: float) -> void:
    if ENEMY_WARNING_ZONE_SCRIPT == null or get_parent() == null:
        return
    var zone: Node2D = ENEMY_WARNING_ZONE_SCRIPT.new() as Node2D
    if zone == null:
        return
    zone.global_position = center
    get_parent().add_child(zone)
    zone.call("setup_circle", radius, duration, Color(0.42, 0.96, 1.0, 1.0))

func _tick_pending_strikes(delta: float) -> void:
    var index: int = 0
    while index < _pending_strikes.size():
        var strike: Dictionary = _pending_strikes[index]
        strike["delay"] = float(strike.get("delay", 0.0)) - delta
        if float(strike["delay"]) <= 0.0:
            _damage_player_in_circle(strike.get("center", global_position), float(strike.get("radius", strike_radius)), int(strike.get("damage", strike_damage)))
            _pending_strikes.remove_at(index)
        else:
            _pending_strikes[index] = strike
            index += 1

func _damage_player_in_circle(center: Vector2, radius: float, damage: int) -> void:
    if _target == null or not is_instance_valid(_target) or not (_target is Player):
        return
    var player: Player = _target as Player
    if player.global_position.distance_squared_to(center) <= pow(radius + player.body_radius, 2.0):
        player.take_damage(scale_outgoing_damage(damage))

func _fire_radial_pulse() -> void:
    var count: int = max(4, radial_count)
    for i: int in range(count):
        var direction: Vector2 = Vector2.RIGHT.rotated(float(i) * TAU / float(count))
        try_fire_projectile(direction, radial_speed, radial_damage, 4.5, 3.8, Color(0.9, 0.78, 0.32, 1.0))

func get_display_name() -> String:
    return "Elite Clockwork Seer"

func _draw() -> void:
    if not _visual_has_sprite:
        draw_circle(Vector2.ZERO, body_radius + 6.0, Color(0.02, 0.1, 0.15, 0.96))
        draw_circle(Vector2.ZERO, body_radius, Color(0.36, 0.92, 1.0, 1.0))
        draw_arc(Vector2.ZERO, body_radius + 9.0, 0.0, TAU, 48, Color(1.0, 0.84, 0.28, 0.86), 3.0)

    var hp_ratio: float = float(current_hp) / float(max(max_hp, 1))
    var bar_width: float = 84.0
    var bar_height: float = 9.0
    var bar_pos: Vector2 = Vector2(-bar_width * 0.5, body_radius + 16.0)
    draw_rect(Rect2(bar_pos - Vector2(1.0, 1.0), Vector2(bar_width + 2.0, bar_height + 2.0)), Color(0.02, 0.0, 0.0, 0.96), true)
    draw_rect(Rect2(bar_pos, Vector2(bar_width, bar_height)), Color(0.02, 0.09, 0.13, 0.96), true)
    draw_rect(Rect2(bar_pos, Vector2(bar_width * hp_ratio, bar_height)), Color(0.44, 0.96, 1.0, 1.0), true)
