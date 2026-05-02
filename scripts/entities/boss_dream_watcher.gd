class_name BossDreamWatcher
extends Enemy

const ENEMY_WARNING_ZONE_SCRIPT: Script = preload("res://scripts/effects/enemy_warning_zone.gd")

signal summon_requested(count: int)
signal phase_changed(phase: int)

var phase: int = 1
var _skill_timers: Dictionary = {}
var _boss_config: Dictionary = {}
var _pending_mechanic_attacks: Array[Dictionary] = []

func _ready() -> void :
    move_speed = 84.0
    max_hp = 1600
    body_radius = 18.0
    xp_drop_amount = 220
    enemy_type = EnemyType.ELITE_WARDEN
    is_elite = true
    _skill_timers = {}
    _boss_config = {}
    _update_visual_for_phase()
    super._ready()

func configure_from_stage(config: Dictionary) -> void :
    _boss_config = config.duplicate(true)
    max_hp = max(1, int(_boss_config.get("hp", 1600)))
    current_hp = max_hp
    _skill_timers = {
        "p1_beam": 1.2,
        "p1_gaze": 3.0,
        "p1_summon": float(_boss_config.get("p1_summon_interval", 40.0)),
        "p2_sweep": 1.6,
        "p2_scan": 2.8,
        "p2_tracking": 3.0,
        "p2_summon": float(_boss_config.get("p2_summon_interval", 35.0)),
        "p3_laser": 2.4,
        "p3_storm": 2.0,
        "p3_collapse": 3.2,
        "p3_despair": float(_boss_config.get("p3_despair_interval", 12.0)),
    }
    _pending_mechanic_attacks.clear()
    phase = 1
    queue_redraw()

func _apply_profile_from_balance() -> void:
    pass

func _configure_visual_from_balance() -> void:
    pass

func set_phase_by_hp() -> void :
    var hp_ratio: float = float(current_hp) / float(max(max_hp, 1))
    var next_phase: int = phase
    if hp_ratio <= 0.32:
        next_phase = 3
    elif hp_ratio <= 0.65:
        next_phase = 2
    else:
        next_phase = 1
    if next_phase != phase:
        phase = next_phase
        _update_visual_for_phase()
        _fire_phase_change_ring()
        phase_changed.emit(phase)

func tick_ai(delta: float) -> void :
    if _target == null:
        velocity = Vector2.ZERO
        return
    var to_player: Vector2 = _target.global_position - global_position
    var dist: float = to_player.length()
    if dist > 0.001:
        var dir_to_player: Vector2 = to_player / dist
        if dist > 360.0:
            velocity = dir_to_player * move_speed
        elif dist < 220.0:
            velocity = -dir_to_player * move_speed * 0.5
        else:
            velocity = dir_to_player.orthogonal() * move_speed * 0.35
    else:
        velocity = Vector2.ZERO
    set_phase_by_hp()
    tick_skills(delta)
    queue_redraw()

func tick_skills(delta: float) -> void :
    if _target == null:
        return
    for key: String in _skill_timers.keys():
        _skill_timers[key] = max(0.0, float(_skill_timers[key]) - delta)
    _tick_pending_mechanic_attacks(delta)
    match phase:
        1:
            _tick_phase_one()
        2:
            _tick_phase_two()
        _:
            _tick_phase_three()

func _tick_phase_one() -> void :
    var to_player: Vector2 = (_target.global_position - global_position).normalized()
    if _skill_timers["p1_beam"] <= 0.0:
        _skill_timers["p1_beam"] = float(_boss_config.get("p1_beam_cd", 2.4))
        try_fire_projectile(to_player, 430.0, int(_boss_config.get("p1_beam_damage", 4)), 6.0, 4.2, Color(1.0, 0.25, 0.22, 1.0))
    if _skill_timers["p1_gaze"] <= 0.0:
        _skill_timers["p1_gaze"] = float(_boss_config.get("p1_gaze_cd", 5.5))
        _schedule_gaze_strike()
    if _skill_timers["p1_summon"] <= 0.0:
        _skill_timers["p1_summon"] = float(_boss_config.get("p1_summon_interval", 40.0))
        summon_requested.emit(int(_boss_config.get("p1_summon_count", 2)))

func _tick_phase_two() -> void :
    var to_player: Vector2 = (_target.global_position - global_position).normalized()
    if _skill_timers["p2_sweep"] <= 0.0:
        _skill_timers["p2_sweep"] = float(_boss_config.get("p2_sweep_cd", 3.0))
        var arc_step: float = deg_to_rad(10.0)
        for i: int in range( - 2, 3):
            try_fire_projectile(to_player.rotated(arc_step * float(i)), 290.0, int(_boss_config.get("p2_sweep_damage", 4)), 5.0, 3.8, Color(1.0, 0.38, 0.2, 1.0))
    if _skill_timers["p2_scan"] <= 0.0:
        _skill_timers["p2_scan"] = float(_boss_config.get("p2_scan_cd", 6.5))
        _schedule_scan_line()
    if _skill_timers["p2_tracking"] <= 0.0:
        _skill_timers["p2_tracking"] = float(_boss_config.get("p2_tracking_interval", 8.0))
        var tracking_count: int = max(1, int(_boss_config.get("p2_tracking_count", 3)))
        for i: int in range(tracking_count):
            var offset_center: float = float(i) - (float(tracking_count) / 2.0)
            var offset: float = deg_to_rad(offset_center * 7.0)
            try_fire_projectile(to_player.rotated(offset), 320.0, int(_boss_config.get("p2_tracking_damage", 4)), 5.0, 4.0, Color(1.0, 0.62, 0.28, 1.0))
    if _skill_timers["p2_summon"] <= 0.0:
        _skill_timers["p2_summon"] = float(_boss_config.get("p2_summon_interval", 35.0))
        summon_requested.emit(int(_boss_config.get("p2_summon_count", 3)))

func _tick_phase_three() -> void :
    var to_player: Vector2 = (_target.global_position - global_position).normalized()
    if _skill_timers["p3_laser"] <= 0.0:
        _skill_timers["p3_laser"] = float(_boss_config.get("p3_death_laser_interval", 10.0))
        var scan_step: float = deg_to_rad(8.0)
        for i: int in range( - 3, 4):
            try_fire_projectile(to_player.rotated(scan_step * float(i)), 390.0, int(_boss_config.get("p3_laser_damage", 5)), 6.0, 4.4, Color(1.0, 0.16, 0.16, 1.0))
    if _skill_timers["p3_storm"] <= 0.0:
        _skill_timers["p3_storm"] = float(_boss_config.get("p3_storm_interval", 7.0))
        for i: int in range(6):
            var storm_dir: Vector2 = Vector2.RIGHT.rotated(float(i) * TAU / 6.0 + randf_range(-0.18, 0.18))
            try_fire_projectile(storm_dir, 255.0, int(_boss_config.get("p3_storm_damage", 3)), 4.0, 3.2, Color(1.0, 0.5, 0.2, 1.0))
    if _skill_timers["p3_collapse"] <= 0.0:
        _skill_timers["p3_collapse"] = float(_boss_config.get("p3_collapse_cd", 8.0))
        _schedule_dream_collapse()
    var hp_ratio: float = float(current_hp) / float(max(max_hp, 1))
    var despair_hp_ratio: float = float(_boss_config.get("p3_despair_hp_ratio", 0.15))
    if hp_ratio <= despair_hp_ratio and _skill_timers["p3_despair"] <= 0.0:
        _skill_timers["p3_despair"] = float(_boss_config.get("p3_despair_interval", 12.0))
        for i: int in range(10):
            var pulse_dir: Vector2 = Vector2.RIGHT.rotated(float(i) * TAU / 10.0)
            try_fire_projectile(pulse_dir, 275.0, int(_boss_config.get("p3_despair_damage", 3)), 4.5, 3.5, Color(1.0, 0.3, 0.3, 1.0))

func _schedule_gaze_strike() -> void:
    if _target == null:
        return
    var warn_time: float = float(_boss_config.get("p1_gaze_warning", 0.9))
    var radius: float = float(_boss_config.get("p1_gaze_radius", 58.0))
    var center: Vector2 = _target.global_position
    _spawn_warning_circle(center, radius, warn_time, Color(1.0, 0.18, 0.28, 1.0))
    _pending_mechanic_attacks.append({
        "kind": "circle_burst",
        "delay": warn_time,
        "center": center,
        "radius": radius,
        "damage": int(_boss_config.get("p1_gaze_damage", 2)),
        "burst_count": int(_boss_config.get("p1_gaze_burst_count", 6)),
        "projectile_speed": 230.0,
        "projectile_damage": 1,
        "tint": Color(1.0, 0.22, 0.34, 1.0),
    })

func _schedule_scan_line() -> void:
    if _target == null:
        return
    var warn_time: float = float(_boss_config.get("p2_scan_warning", 1.1))
    var length: float = float(_boss_config.get("p2_scan_length", 920.0))
    var width: float = float(_boss_config.get("p2_scan_width", 64.0))
    var angle: float = 0.0 if randi() % 2 == 0 else PI * 0.5
    var center: Vector2 = _target.global_position
    _spawn_warning_line(center, length, width, angle, warn_time, Color(1.0, 0.42, 0.18, 1.0))
    _pending_mechanic_attacks.append({
        "kind": "line_sweep",
        "delay": warn_time,
        "center": center,
        "angle": angle,
        "length": length,
        "width": width,
        "damage": int(_boss_config.get("p2_scan_damage", 2)),
        "projectile_count": int(_boss_config.get("p2_scan_projectile_count", 5)),
        "projectile_speed": 390.0,
        "projectile_damage": 1,
        "tint": Color(1.0, 0.54, 0.24, 1.0),
    })

func _schedule_dream_collapse() -> void:
    if _target == null:
        return
    var warn_time: float = float(_boss_config.get("p3_collapse_warning", 1.0))
    var radius: float = float(_boss_config.get("p3_collapse_radius", 62.0))
    var damage: int = int(_boss_config.get("p3_collapse_damage", 3))
    var base_center: Vector2 = _target.global_position
    var player_velocity: Vector2 = Vector2.ZERO
    if _target is CharacterBody2D:
        var target_body: CharacterBody2D = _target as CharacterBody2D
        player_velocity = target_body.velocity
    var forward: Vector2 = player_velocity.normalized() if player_velocity.length_squared() > 1.0 else Vector2.RIGHT.rotated(randf() * TAU)
    var side: Vector2 = forward.orthogonal()
    var centers: Array[Vector2] = [
        base_center,
        base_center + side * 92.0 + forward * 40.0,
        base_center - side * 92.0 + forward * 80.0,
    ]
    for i: int in range(centers.size()):
        var stagger: float = float(i) * float(_boss_config.get("p3_collapse_stagger", 0.25))
        _spawn_warning_circle(centers[i], radius, warn_time + stagger, Color(1.0, 0.1, 0.16, 1.0))
        _pending_mechanic_attacks.append({
            "kind": "circle",
            "delay": warn_time + stagger,
            "center": centers[i],
            "radius": radius,
            "damage": damage,
            "tint": Color(1.0, 0.18, 0.2, 1.0),
        })

func _fire_phase_change_ring() -> void:
    var count: int = int(_boss_config.get("phase_ring_count", 12))
    var damage: int = int(_boss_config.get("phase_ring_damage", 1))
    var speed: float = float(_boss_config.get("phase_ring_speed", 230.0))
    for i: int in range(max(1, count)):
        var direction: Vector2 = Vector2.RIGHT.rotated(float(i) * TAU / float(max(1, count)))
        try_fire_projectile(direction, speed, damage, 4.0, 3.4, Color(1.0, 0.38, 0.42, 1.0))

func _tick_pending_mechanic_attacks(delta: float) -> void:
    var index: int = 0
    while index < _pending_mechanic_attacks.size():
        var attack: Dictionary = _pending_mechanic_attacks[index]
        attack["delay"] = float(attack.get("delay", 0.0)) - delta
        if float(attack["delay"]) <= 0.0:
            _execute_mechanic_attack(attack)
            _pending_mechanic_attacks.remove_at(index)
        else:
            _pending_mechanic_attacks[index] = attack
            index += 1

func _execute_mechanic_attack(attack: Dictionary) -> void:
    var kind: String = str(attack.get("kind", "circle"))
    match kind:
        "circle_burst":
            var center: Vector2 = attack.get("center", global_position)
            var radius: float = float(attack.get("radius", 48.0))
            _damage_player_in_circle(center, radius, int(attack.get("damage", 1)))
            _fire_radial_projectiles_from(center, int(attack.get("burst_count", 6)), int(attack.get("projectile_damage", 1)), float(attack.get("projectile_speed", 230.0)), attack.get("tint", Color(1.0, 0.22, 0.34, 1.0)))
        "line_sweep":
            _damage_player_in_line(
                attack.get("center", global_position),
                float(attack.get("angle", 0.0)),
                float(attack.get("length", 900.0)),
                float(attack.get("width", 64.0)),
                int(attack.get("damage", 1))
            )
            _fire_scan_projectiles(attack)
        _:
            _damage_player_in_circle(attack.get("center", global_position), float(attack.get("radius", 48.0)), int(attack.get("damage", 1)))

func _spawn_warning_circle(center: Vector2, radius: float, duration: float, tint: Color) -> void:
    if ENEMY_WARNING_ZONE_SCRIPT == null or get_parent() == null:
        return
    var zone: Node2D = ENEMY_WARNING_ZONE_SCRIPT.new() as Node2D
    if zone == null:
        return
    zone.global_position = center
    get_parent().add_child(zone)
    zone.call("setup_circle", radius, duration, tint)

func _spawn_warning_line(center: Vector2, length: float, width: float, angle: float, duration: float, tint: Color) -> void:
    if ENEMY_WARNING_ZONE_SCRIPT == null or get_parent() == null:
        return
    var zone: Node2D = ENEMY_WARNING_ZONE_SCRIPT.new() as Node2D
    if zone == null:
        return
    zone.global_position = center
    get_parent().add_child(zone)
    zone.call("setup_line", length, width, duration, angle, tint)

func _damage_player_in_circle(center: Vector2, radius: float, damage: int) -> void:
    if _target == null or not is_instance_valid(_target) or not (_target is Player):
        return
    var player: Player = _target as Player
    if player.global_position.distance_squared_to(center) <= pow(radius + player.body_radius, 2.0):
        player.take_damage(scale_outgoing_damage(damage))

func _damage_player_in_line(center: Vector2, angle: float, length: float, width: float, damage: int) -> void:
    if _target == null or not is_instance_valid(_target) or not (_target is Player):
        return
    var player: Player = _target as Player
    var local_pos: Vector2 = (player.global_position - center).rotated(-angle)
    if absf(local_pos.x) <= length * 0.5 + player.body_radius and absf(local_pos.y) <= width * 0.5 + player.body_radius:
        player.take_damage(scale_outgoing_damage(damage))

func _fire_radial_projectiles_from(center: Vector2, count: int, damage: int, speed: float, tint: Color) -> void:
    var safe_count: int = max(1, count)
    for i: int in range(safe_count):
        var direction: Vector2 = Vector2.RIGHT.rotated(float(i) * TAU / float(safe_count))
        fire_projectile_from(center, direction, speed, damage, 4.0, 3.2, tint)

func _fire_scan_projectiles(attack: Dictionary) -> void:
    var count: int = max(1, int(attack.get("projectile_count", 5)))
    var center: Vector2 = attack.get("center", global_position)
    var angle: float = float(attack.get("angle", 0.0))
    var length: float = float(attack.get("length", 900.0))
    var line_dir: Vector2 = Vector2.RIGHT.rotated(angle)
    var fire_dir: Vector2 = line_dir if randf() < 0.5 else -line_dir
    var spacing: float = length / float(count + 1)
    for i: int in range(count):
        var offset: float = -length * 0.5 + spacing * float(i + 1)
        var origin: Vector2 = center + line_dir * offset
        fire_projectile_from(origin, fire_dir, float(attack.get("projectile_speed", 390.0)), int(attack.get("projectile_damage", 1)), 4.0, 3.0, attack.get("tint", Color(1.0, 0.54, 0.24, 1.0)))

func _update_visual_for_phase() -> void:
    var path: String = "res://sprite/boss/dream_watcher/battle_sheet.png"
    
    _setup_visual_from_config({
        "sprite_sheet_path": path,
        "hframes": 6,
        "vframes": 6,
        "move_frames": [6, 7, 8, 9, 10, 11],
        "death_frames": [30, 31, 32, 33, 34, 35],
        "anim_fps": 10.0,
        "death_anim_fps": 12.0,
        "scale": 0.62,
        "flip_with_velocity": true,
        "elite_scale_multiplier": 1.0,
        "apply_elite_tint": false
    })

func on_defeated() -> void :
    pass

func get_display_name() -> String:
    return "Dream Watcher"

func _draw() -> void :
    if not _visual_has_sprite:
        draw_circle(Vector2.ZERO, body_radius + 4.0, Color(0.16, 0.05, 0.08, 0.95))
        draw_circle(Vector2.ZERO, body_radius, Color(0.95, 0.18, 0.3, 1.0))
    var hp_ratio: float = float(current_hp) / float(max(max_hp, 1))
    var bar_width: float = 56.0
    var bar_height: float = 6.0
    var bar_pos: Vector2 = Vector2(-bar_width * 0.5, body_radius + 12.0)
    draw_rect(Rect2(bar_pos, Vector2(bar_width, bar_height)), Color(0.18, 0.1, 0.1, 0.95), true)
    draw_rect(Rect2(bar_pos, Vector2(bar_width * hp_ratio, bar_height)), Color(1.0, 0.26, 0.36, 1.0), true)
