class_name EliteRiftCharger
extends Enemy

const ENEMY_WARNING_ZONE_SCRIPT: Script = preload("res://scripts/effects/enemy_warning_zone.gd")

enum RiftState {
    CHASE,
    WINDUP,
    CHARGE,
    RECOVER,
}

@export var charge_trigger_distance: float = 300.0
@export var charge_cooldown: float = 5.2
@export var charge_windup: float = 1.0
@export var charge_duration: float = 0.72
@export var charge_recover: float = 0.7
@export var charge_speed: float = 430.0
@export var warning_length: float = 760.0
@export var warning_width: float = 58.0
@export var shock_projectile_count: int = 6
@export var shock_projectile_damage: int = 1
@export var shock_projectile_speed: float = 190.0
@export var flank_distance: float = 230.0
@export var flank_strength: float = 0.44
@export var charge_lead_factor: float = 0.42

var _rift_state: RiftState = RiftState.CHASE
var _state_timer: float = 0.0
var _cooldown_timer: float = 0.0
var _charge_direction: Vector2 = Vector2.RIGHT
var _flank_sign: float = 1.0
var _flank_timer: float = 0.0

func _ready() -> void:
    enemy_type = EnemyType.ELITE_RIFT_CHARGER
    is_elite = true
    _flank_sign = -1.0 if randi() % 2 == 0 else 1.0
    super._ready()
    _cooldown_timer = charge_cooldown * randf_range(0.35, 0.75)
    _flank_timer = randf_range(1.0, 2.4)

func _apply_profile_from_balance() -> void:
    var profile: Dictionary = BalanceService.get_enemy_profile("elite_rift_charger")
    move_speed = float(profile.get("move_speed", move_speed))
    max_hp = int(profile.get("max_hp", max_hp))
    body_radius = float(profile.get("body_radius", body_radius))
    xp_drop_amount = int(profile.get("xp_drop", xp_drop_amount))
    charge_trigger_distance = float(profile.get("charge_trigger_distance", charge_trigger_distance))
    charge_cooldown = float(profile.get("charge_cooldown", charge_cooldown))
    charge_windup = float(profile.get("charge_windup", charge_windup))
    charge_duration = float(profile.get("charge_duration", charge_duration))
    charge_recover = float(profile.get("charge_recover", charge_recover))
    charge_speed = float(profile.get("charge_speed", charge_speed))
    warning_length = float(profile.get("warning_length", warning_length))
    warning_width = float(profile.get("warning_width", warning_width))
    shock_projectile_count = int(profile.get("shock_projectile_count", shock_projectile_count))
    shock_projectile_damage = int(profile.get("shock_projectile_damage", shock_projectile_damage))
    shock_projectile_speed = float(profile.get("shock_projectile_speed", shock_projectile_speed))
    flank_distance = float(profile.get("flank_distance", flank_distance))
    flank_strength = float(profile.get("flank_strength", flank_strength))
    charge_lead_factor = float(profile.get("charge_lead_factor", charge_lead_factor))
    _hit_sfx_path = str(profile.get("hit_sfx_path", _hit_sfx_path))
    _hit_sfx_volume_db = float(profile.get("hit_sfx_volume_db", _hit_sfx_volume_db))
    _hit_sfx_cooldown = max(0.0, float(profile.get("hit_sfx_cooldown", _hit_sfx_cooldown)))

func tick_ai(delta: float) -> void:
    if _target == null:
        velocity = Vector2.ZERO
        return

    _cooldown_timer = max(0.0, _cooldown_timer - delta)
    match _rift_state:
        RiftState.WINDUP:
            _tick_windup(delta)
        RiftState.CHARGE:
            _tick_charge(delta)
        RiftState.RECOVER:
            _tick_recover(delta)
        _:
            _tick_chase(delta)
    queue_redraw()

func _tick_chase(delta: float) -> void:
    var to_player: Vector2 = _target.global_position - global_position
    var distance: float = to_player.length()
    if distance <= 0.001:
        velocity = Vector2.ZERO
        return
    var direction: Vector2 = to_player / distance
    _flank_timer = max(0.0, _flank_timer - delta)
    if _flank_timer <= 0.0:
        _flank_sign *= -1.0
        _flank_timer = randf_range(1.1, 2.6)

    var side: Vector2 = direction.orthogonal() * _flank_sign
    if distance > charge_trigger_distance:
        velocity = (direction + side * flank_strength).normalized() * move_speed
    elif distance > flank_distance:
        velocity = (direction * 0.72 + side * flank_strength).normalized() * move_speed
    else:
        velocity = side * move_speed * 0.58

    if _cooldown_timer <= 0.0 and distance <= charge_trigger_distance:
        _charge_direction = _resolve_charge_direction()
        _rift_state = RiftState.WINDUP
        _state_timer = charge_windup
        velocity = Vector2.ZERO
        _spawn_warning_line()

func _resolve_charge_direction() -> Vector2:
    if _target == null or not is_instance_valid(_target):
        return _charge_direction
    var target_position: Vector2 = _target.global_position
    if _target is CharacterBody2D:
        var body: CharacterBody2D = _target as CharacterBody2D
        var travel_time: float = global_position.distance_to(target_position) / max(1.0, charge_speed)
        target_position += body.velocity * clampf(travel_time * charge_lead_factor, 0.0, 0.45)
    var aim: Vector2 = target_position - global_position
    return aim.normalized() if aim.length_squared() > 0.0001 else _charge_direction

func _tick_windup(delta: float) -> void:
    velocity = Vector2.ZERO
    _state_timer = max(0.0, _state_timer - delta)
    if _state_timer <= 0.0:
        _rift_state = RiftState.CHARGE
        _state_timer = charge_duration
        velocity = _charge_direction * charge_speed

func _tick_charge(delta: float) -> void:
    velocity = _charge_direction * charge_speed
    _state_timer = max(0.0, _state_timer - delta)
    if _state_timer <= 0.0:
        _rift_state = RiftState.RECOVER
        _state_timer = charge_recover
        velocity = Vector2.ZERO
        _fire_shock_ring()

func _tick_recover(delta: float) -> void:
    velocity = Vector2.ZERO
    _state_timer = max(0.0, _state_timer - delta)
    if _state_timer <= 0.0:
        _rift_state = RiftState.CHASE
        _cooldown_timer = charge_cooldown
        _flank_timer = randf_range(0.8, 1.8)

func _spawn_warning_line() -> void:
    if ENEMY_WARNING_ZONE_SCRIPT == null or get_parent() == null:
        return
    var zone: Node2D = ENEMY_WARNING_ZONE_SCRIPT.new() as Node2D
    if zone == null:
        return
    zone.global_position = global_position + _charge_direction * (warning_length * 0.5)
    get_parent().add_child(zone)
    zone.call("setup_line", warning_length, warning_width, charge_windup, _charge_direction.angle(), Color(1.0, 0.34, 0.18, 1.0))

func _fire_shock_ring() -> void:
    var count: int = max(1, shock_projectile_count)
    for i: int in range(count):
        var direction: Vector2 = Vector2.RIGHT.rotated(float(i) * TAU / float(count))
        try_fire_projectile(direction, shock_projectile_speed, shock_projectile_damage, 4.5, 3.4, Color(1.0, 0.42, 0.18, 1.0))

func get_display_name() -> String:
    return "Elite Rift Charger"

func is_knockback_immune() -> bool:
    return _rift_state == RiftState.CHARGE or super.is_knockback_immune()

func _draw() -> void:
    if not _visual_has_sprite:
        draw_circle(Vector2.ZERO, body_radius + 6.0, Color(0.16, 0.02, 0.01, 0.96))
        draw_circle(Vector2.ZERO, body_radius, Color(1.0, 0.24, 0.12, 1.0))
    if _rift_state == RiftState.WINDUP:
        draw_arc(Vector2.ZERO, body_radius + 10.0, 0.0, TAU, 32, Color(1.0, 0.28, 0.12, 0.86), 4.0)
    elif _rift_state == RiftState.CHARGE:
        draw_line(-_charge_direction * (body_radius + 18.0), Vector2.ZERO, Color(1.0, 0.42, 0.18, 0.78), 5.0)

    var hp_ratio: float = float(current_hp) / float(max(max_hp, 1))
    var bar_width: float = 84.0
    var bar_height: float = 9.0
    var bar_pos: Vector2 = Vector2(-bar_width * 0.5, body_radius + 16.0)
    draw_rect(Rect2(bar_pos - Vector2(1.0, 1.0), Vector2(bar_width + 2.0, bar_height + 2.0)), Color(0.02, 0.0, 0.0, 0.96), true)
    draw_rect(Rect2(bar_pos, Vector2(bar_width, bar_height)), Color(0.16, 0.03, 0.02, 0.96), true)
    draw_rect(Rect2(bar_pos, Vector2(bar_width * hp_ratio, bar_height)), Color(1.0, 0.28, 0.12, 1.0), true)
