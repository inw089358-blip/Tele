class_name MineSeederEnemy
extends Enemy

const ENEMY_WARNING_ZONE_SCRIPT: Script = preload("res://scripts/effects/enemy_warning_zone.gd")

@export var desired_min_distance: float = 170.0
@export var desired_max_distance: float = 260.0
@export var mine_interval: float = 4.2
@export var mine_warning: float = 1.05
@export var mine_radius: float = 42.0
@export var mine_damage: int = 1
@export var mine_offset_min: float = 20.0
@export var mine_offset_max: float = 110.0

var _mine_timer: float = 0.0
var _strafe_sign: float = 1.0
var _pending_mines: Array[Dictionary] = []

func _ready() -> void:
    enemy_type = EnemyType.MINE_SEEDER
    _strafe_sign = -1.0 if randi() % 2 == 0 else 1.0
    super._ready()
    _mine_timer = mine_interval * randf_range(0.35, 0.85)

func _apply_profile_from_balance() -> void:
    var profile: Dictionary = BalanceService.get_enemy_profile("mine_seeder")
    move_speed = float(profile.get("move_speed", move_speed))
    max_hp = int(profile.get("max_hp", max_hp))
    body_radius = float(profile.get("body_radius", body_radius))
    xp_drop_amount = int(profile.get("xp_drop", xp_drop_amount))
    desired_min_distance = float(profile.get("desired_min_distance", desired_min_distance))
    desired_max_distance = float(profile.get("desired_max_distance", desired_max_distance))
    mine_interval = float(profile.get("mine_interval", mine_interval))
    mine_warning = float(profile.get("mine_warning", mine_warning))
    mine_radius = float(profile.get("mine_radius", mine_radius))
    mine_damage = int(profile.get("mine_damage", mine_damage))
    mine_offset_min = float(profile.get("mine_offset_min", mine_offset_min))
    mine_offset_max = float(profile.get("mine_offset_max", mine_offset_max))
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
            velocity = dir_to_player.orthogonal() * _strafe_sign * move_speed * 0.7

    _tick_pending_mines(delta)
    _mine_timer = max(0.0, _mine_timer - delta)
    if _mine_timer <= 0.0:
        _mine_timer = mine_interval
        _schedule_mine()

func _schedule_mine() -> void:
    if _target == null or not is_instance_valid(_target):
        return
    var offset: Vector2 = Vector2.RIGHT.rotated(randf() * TAU) * randf_range(mine_offset_min, mine_offset_max)
    var center: Vector2 = _target.global_position + offset
    _spawn_warning_circle(center, mine_radius, mine_warning)
    _pending_mines.append({
        "delay": mine_warning,
        "center": center,
        "radius": mine_radius,
        "damage": mine_damage,
    })

func _spawn_warning_circle(center: Vector2, radius: float, duration: float) -> void:
    if ENEMY_WARNING_ZONE_SCRIPT == null or get_parent() == null:
        return
    var zone: Node2D = ENEMY_WARNING_ZONE_SCRIPT.new() as Node2D
    if zone == null:
        return
    zone.global_position = center
    get_parent().add_child(zone)
    zone.call("setup_circle", radius, duration, Color(0.72, 1.0, 0.34, 1.0))

func _tick_pending_mines(delta: float) -> void:
    var index: int = 0
    while index < _pending_mines.size():
        var mine: Dictionary = _pending_mines[index]
        mine["delay"] = float(mine.get("delay", 0.0)) - delta
        if float(mine["delay"]) <= 0.0:
            _damage_player_in_circle(mine.get("center", global_position), float(mine.get("radius", mine_radius)), int(mine.get("damage", mine_damage)))
            _pending_mines.remove_at(index)
        else:
            _pending_mines[index] = mine
            index += 1

func _damage_player_in_circle(center: Vector2, radius: float, damage: int) -> void:
    if _target == null or not is_instance_valid(_target) or not (_target is Player):
        return
    var player: Player = _target as Player
    if player.global_position.distance_squared_to(center) <= pow(radius + player.body_radius, 2.0):
        player.take_damage(scale_outgoing_damage(damage))

func get_display_name() -> String:
    return "Mine Seeder"

func _draw() -> void:
    if not _visual_has_sprite:
        draw_circle(Vector2.ZERO, body_radius + 2.0, Color(0.05, 0.14, 0.05, 0.92))
        draw_circle(Vector2.ZERO, body_radius, Color(0.62, 1.0, 0.28, 1.0))
        draw_arc(Vector2.ZERO, body_radius + 4.0, 0.0, TAU, 24, Color(0.9, 1.0, 0.5, 0.72), 1.4)
    if not _should_draw_health_bar():
        return
    var hp_ratio: float = float(current_hp) / float(max(max_hp, 1))
    var bar_width: float = 22.0
    var bar_height: float = 3.0
    var bar_pos: Vector2 = Vector2(-bar_width * 0.5, body_radius + 6.0)
    draw_rect(Rect2(bar_pos, Vector2(bar_width, bar_height)), Color(0.08, 0.16, 0.06, 0.9), true)
    draw_rect(Rect2(bar_pos, Vector2(bar_width * hp_ratio, bar_height)), Color(0.72, 1.0, 0.34, 1.0), true)
