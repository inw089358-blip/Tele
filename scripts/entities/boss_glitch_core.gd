class_name BossGlitchCore
extends Enemy

signal summon_requested(count: int)
signal phase_changed(phase: int)

var phase: int = 1
var _skill_timers: Dictionary = {}
var _boss_config: Dictionary = {}

func _ready() -> void :
    move_speed = 92.0
    max_hp = 1800
    body_radius = 22.0
    xp_drop_amount = 250
    enemy_type = EnemyType.ELITE_WARDEN
    is_elite = true
    _skill_timers = {}
    _boss_config = {}
    _setup_visual()
    super._ready()

func _setup_visual() -> void:
    _setup_visual_from_config({
        "sprite_sheet_path": "res://sprite/boss/glitch_core/battle_sheet.png",
        "hframes": 6,
        "vframes": 6,
        "move_frames": [0, 1, 2, 3, 4, 5],
        "death_frames": [30, 31, 32, 33, 34, 35],
        "anim_fps": 12.0,
        "death_anim_fps": 14.0,
        "scale": 2.2,
        "flip_with_velocity": true
    })

func configure_from_stage(config: Dictionary) -> void :
    _boss_config = config.duplicate(true)
    max_hp = max(1, int(_boss_config.get("hp", 1800)))
    current_hp = max_hp
    _skill_timers = {
        "glitch_burst": 2.0,
        "screen_spam": 4.5,
        "system_crash": 12.0
    }
    phase = 1
    queue_redraw()

func tick_ai(delta: float) -> void :
    if _target == null:
        velocity = Vector2.ZERO
        return
    var to_player: Vector2 = _target.global_position - global_position
    var dist: float = to_player.length()
    
    # Stay at a medium distance
    if dist > 300.0:
        velocity = to_player.normalized() * move_speed
    elif dist < 150.0:
        velocity = -to_player.normalized() * move_speed
    else:
        velocity = to_player.normalized().orthogonal() * move_speed * 0.5
        
    tick_skills(delta)
    queue_redraw()

func tick_skills(delta: float) -> void :
    if _target == null:
        return
    for key: String in _skill_timers.keys():
        _skill_timers[key] = max(0.0, float(_skill_timers[key]) - delta)
    
    if _skill_timers["glitch_burst"] <= 0.0:
        _skill_timers["glitch_burst"] = 2.5
        _fire_burst()
        
    if _skill_timers["screen_spam"] <= 0.0:
        _skill_timers["screen_spam"] = 5.0
        summon_requested.emit(2)

func _fire_burst() -> void:
    var to_player: Vector2 = (_target.global_position - global_position).normalized()
    for i: int in range(-2, 3):
        var dir: Vector2 = to_player.rotated(deg_to_rad(float(i) * 15.0))
        try_fire_projectile(dir, 350.0, 15, 6.0, 3.5, Color(0.2, 0.8, 1.0, 1.0))

func get_display_name() -> String:
    return "Glitch Core"

func _draw() -> void :
    if not _visual_has_sprite:
        draw_circle(Vector2.ZERO, body_radius + 4.0, Color(0.05, 0.08, 0.16, 0.95))
    
    var hp_ratio: float = float(current_hp) / float(max(max_hp, 1))
    var bar_width: float = 60.0
    var bar_height: float = 6.0
    var bar_pos: Vector2 = Vector2(-bar_width * 0.5, body_radius + 15.0)
    draw_rect(Rect2(bar_pos, Vector2(bar_width, bar_height)), Color(0.1, 0.1, 0.1, 0.95), true)
    draw_rect(Rect2(bar_pos, Vector2(bar_width * hp_ratio, bar_height)), Color(0.2, 0.7, 1.0, 1.0), true)
