class_name ChargerEnemy
extends Enemy

enum ChargeState {
    CHASE,
    WINDUP,
    CHARGE,
    RECOVER,
}

@export var charge_trigger_distance: float = 220.0
@export var charge_cooldown: float = 4.2
@export var charge_windup: float = 0.65
@export var charge_duration: float = 0.52
@export var charge_recover: float = 0.45
@export var charge_speed: float = 340.0

var _charge_state: ChargeState = ChargeState.CHASE
var _state_timer: float = 0.0
var _cooldown_timer: float = 0.0
var _charge_direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
    enemy_type = EnemyType.CHARGER
    super._ready()
    _cooldown_timer = randf_range(charge_cooldown * 0.35, charge_cooldown * 0.85)

func _apply_profile_from_balance() -> void:
    var profile: Dictionary = BalanceService.get_enemy_profile("charger")
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
    _hit_sfx_path = str(profile.get("hit_sfx_path", _hit_sfx_path))
    _hit_sfx_volume_db = float(profile.get("hit_sfx_volume_db", _hit_sfx_volume_db))
    _hit_sfx_cooldown = max(0.0, float(profile.get("hit_sfx_cooldown", _hit_sfx_cooldown)))

func tick_ai(delta: float) -> void:
    if _target == null:
        velocity = Vector2.ZERO
        return

    _cooldown_timer = max(0.0, _cooldown_timer - delta)
    match _charge_state:
        ChargeState.WINDUP:
            _tick_windup(delta)
        ChargeState.CHARGE:
            _tick_charge(delta)
        ChargeState.RECOVER:
            _tick_recover(delta)
        _:
            _tick_chase()

func get_display_name() -> String:
    return "Crash Brute"

func _tick_chase() -> void:
    var to_player: Vector2 = _target.global_position - global_position
    var distance: float = to_player.length()
    if distance <= 0.001:
        velocity = Vector2.ZERO
        return

    var direction: Vector2 = to_player / distance
    velocity = direction * move_speed
    if _cooldown_timer <= 0.0 and distance <= charge_trigger_distance:
        _charge_direction = direction
        _charge_state = ChargeState.WINDUP
        _state_timer = charge_windup
        velocity = Vector2.ZERO
        queue_redraw()

func _tick_windup(delta: float) -> void:
    velocity = Vector2.ZERO
    var to_player: Vector2 = _target.global_position - global_position
    if to_player.length_squared() > 0.0001:
        _charge_direction = to_player.normalized()
    _state_timer = max(0.0, _state_timer - delta)
    if _state_timer <= 0.0:
        _charge_state = ChargeState.CHARGE
        _state_timer = charge_duration
        velocity = _charge_direction * charge_speed
        queue_redraw()

func _tick_charge(delta: float) -> void:
    velocity = _charge_direction * charge_speed
    _state_timer = max(0.0, _state_timer - delta)
    if _state_timer <= 0.0:
        _charge_state = ChargeState.RECOVER
        _state_timer = charge_recover
        velocity = Vector2.ZERO
        queue_redraw()

func _tick_recover(delta: float) -> void:
    velocity = Vector2.ZERO
    _state_timer = max(0.0, _state_timer - delta)
    if _state_timer <= 0.0:
        _charge_state = ChargeState.CHASE
        _cooldown_timer = charge_cooldown
        queue_redraw()

func _draw() -> void:
    if not _visual_has_sprite:
        draw_circle(Vector2.ZERO, body_radius + 3.0, Color(0.18, 0.04, 0.03, 0.94))
        draw_circle(Vector2.ZERO, body_radius, Color(0.86, 0.22, 0.18, 1.0))
    if _charge_state == ChargeState.WINDUP:
        draw_arc(Vector2.ZERO, body_radius + 6.0, 0.0, TAU, 24, Color(1.0, 0.2, 0.12, 0.78), 2.0)
    elif _charge_state == ChargeState.CHARGE:
        var tail: Vector2 = -_charge_direction * (body_radius + 10.0)
        draw_line(tail, Vector2.ZERO, Color(1.0, 0.36, 0.18, 0.72), 3.0)
    if not _should_draw_health_bar():
        return
    var hp_ratio: float = float(current_hp) / float(max(max_hp, 1))
    var bar_width: float = 26.0
    var bar_height: float = 4.0
    var bar_pos: Vector2 = Vector2(-bar_width * 0.5, body_radius + 8.0)
    draw_rect(Rect2(bar_pos, Vector2(bar_width, bar_height)), Color(0.18, 0.08, 0.07, 0.9), true)
    draw_rect(Rect2(bar_pos, Vector2(bar_width * hp_ratio, bar_height)), Color(1.0, 0.32, 0.22, 1.0), true)
