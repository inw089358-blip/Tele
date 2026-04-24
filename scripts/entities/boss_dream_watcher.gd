class_name BossDreamWatcher
extends Enemy

signal summon_requested(count: int)
signal phase_changed(phase: int)

var phase: int = 1
var _skill_timers: Dictionary = {}
var _boss_config: Dictionary = {}

func _ready() -> void :
    move_speed = 84.0
    max_hp = 1600
    body_radius = 18.0
    xp_drop_amount = 220
    enemy_type = EnemyType.ELITE_WARDEN
    is_elite = true
    _skill_timers = {}
    _boss_config = {}
    super._ready()

func configure_from_stage(config: Dictionary) -> void :
    _boss_config = config.duplicate(true)
    max_hp = max(1, int(_boss_config.get("hp", 1600)))
    current_hp = max_hp
    _skill_timers = {
        "p1_beam": 1.2,
        "p1_summon": float(_boss_config.get("p1_summon_interval", 40.0)),
        "p2_sweep": 1.6,
        "p2_tracking": 3.0,
        "p2_summon": float(_boss_config.get("p2_summon_interval", 35.0)),
        "p3_laser": 2.4,
        "p3_storm": 2.0,
        "p3_despair": float(_boss_config.get("p3_despair_interval", 12.0)),
    }
    phase = 1
    queue_redraw()

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
        try_fire_projectile(to_player, 430.0, 14, 6.0, 4.2, Color(1.0, 0.25, 0.22, 1.0))
    if _skill_timers["p1_summon"] <= 0.0:
        _skill_timers["p1_summon"] = float(_boss_config.get("p1_summon_interval", 40.0))
        summon_requested.emit(int(_boss_config.get("p1_summon_count", 2)))

func _tick_phase_two() -> void :
    var to_player: Vector2 = (_target.global_position - global_position).normalized()
    if _skill_timers["p2_sweep"] <= 0.0:
        _skill_timers["p2_sweep"] = float(_boss_config.get("p2_sweep_cd", 3.0))
        var arc_step: float = deg_to_rad(10.0)
        for i: int in range( - 2, 3):
            try_fire_projectile(to_player.rotated(arc_step * float(i)), 290.0, 12, 5.0, 3.8, Color(1.0, 0.38, 0.2, 1.0))
    if _skill_timers["p2_tracking"] <= 0.0:
        _skill_timers["p2_tracking"] = float(_boss_config.get("p2_tracking_interval", 8.0))
        var tracking_count: int = max(1, int(_boss_config.get("p2_tracking_count", 3)))
        for i: int in range(tracking_count):
            var offset_center: float = float(i) - (float(tracking_count) / 2.0)
            var offset: float = deg_to_rad(offset_center * 7.0)
            try_fire_projectile(to_player.rotated(offset), 320.0, 13, 5.0, 4.0, Color(1.0, 0.62, 0.28, 1.0))
    if _skill_timers["p2_summon"] <= 0.0:
        _skill_timers["p2_summon"] = float(_boss_config.get("p2_summon_interval", 35.0))
        summon_requested.emit(int(_boss_config.get("p2_summon_count", 3)))

func _tick_phase_three() -> void :
    var to_player: Vector2 = (_target.global_position - global_position).normalized()
    if _skill_timers["p3_laser"] <= 0.0:
        _skill_timers["p3_laser"] = float(_boss_config.get("p3_death_laser_interval", 10.0))
        var scan_step: float = deg_to_rad(8.0)
        for i: int in range( - 3, 4):
            try_fire_projectile(to_player.rotated(scan_step * float(i)), 390.0, 18, 6.0, 4.4, Color(1.0, 0.16, 0.16, 1.0))
    if _skill_timers["p3_storm"] <= 0.0:
        _skill_timers["p3_storm"] = float(_boss_config.get("p3_storm_interval", 7.0))
        for i: int in range(6):
            var storm_dir: Vector2 = Vector2.RIGHT.rotated(float(i) * TAU / 6.0 + randf_range(-0.18, 0.18))
            try_fire_projectile(storm_dir, 255.0, 10, 4.0, 3.2, Color(1.0, 0.5, 0.2, 1.0))
    var hp_ratio: float = float(current_hp) / float(max(max_hp, 1))
    var despair_hp_ratio: float = float(_boss_config.get("p3_despair_hp_ratio", 0.15))
    if hp_ratio <= despair_hp_ratio and _skill_timers["p3_despair"] <= 0.0:
        _skill_timers["p3_despair"] = float(_boss_config.get("p3_despair_interval", 12.0))
        for i: int in range(10):
            var pulse_dir: Vector2 = Vector2.RIGHT.rotated(float(i) * TAU / 10.0)
            try_fire_projectile(pulse_dir, 275.0, 9, 4.5, 3.5, Color(1.0, 0.3, 0.3, 1.0))

func on_defeated() -> void :
    pass

func get_display_name() -> String:
    return "Dream Watcher"

func _draw() -> void :
    draw_circle(Vector2.ZERO, body_radius + 4.0, Color(0.16, 0.05, 0.08, 0.95))
    draw_circle(Vector2.ZERO, body_radius, Color(0.95, 0.18, 0.3, 1.0))
    var hp_ratio: float = float(current_hp) / float(max(max_hp, 1))
    var bar_width: float = 56.0
    var bar_height: float = 6.0
    var bar_pos: Vector2 = Vector2(-bar_width * 0.5, body_radius + 12.0)
    draw_rect(Rect2(bar_pos, Vector2(bar_width, bar_height)), Color(0.18, 0.1, 0.1, 0.95), true)
    draw_rect(Rect2(bar_pos, Vector2(bar_width * hp_ratio, bar_height)), Color(1.0, 0.26, 0.36, 1.0), true)
