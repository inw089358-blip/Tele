class_name Projectile
extends Area2D

const PROJECTILE_IMPACT_EFFECT_SCRIPT: Script = preload("res://scripts/effects/projectile_impact_effect.gd")

@export var speed: float = 520.0
@export var direction: Vector2 = Vector2.RIGHT
@export var damage: int = 10
@export var hit_radius: float = 4.0
@export var life_time: float = 1.6
@export var crit_chance: float = 0.0
@export var crit_multiplier: float = 1.5
@export var lifesteal_chance: float = 0.0
@export var aoe_radius: float = 0.0
@export var knockback_strength: float = 0.0
@export var knockback_duration: float = 0.0
@export var bounce_count: int = 0
@export var bounce_range: float = 0.0
@export var bounce_damage_mult: float = 1.0
@export var spin_speed: float = 0.0

var visual_preset: String = "default"
var impact_mode: String = "single"
var spawn_flash_time: float = 0.05
var trail_strength: float = 1.0
var base_tint: Color = Color(0.47, 0.94, 1.0, 1.0)
var outer_tint: Color = Color(0.05, 0.28, 0.43, 0.74)
var core_tint: Color = Color(0.96, 1.0, 1.0, 1.0)

var _target: Node2D
var owner_player: Player
var _elapsed: float = 0.0
var _total_life_time: float = 1.6
var _body_length_scale: float = 2.8
var _body_width_scale: float = 1.0
var _trail_length_scale: float = 1.0
var _glow_strength: float = 1.0
var _glitch_phase: float = 0.0
var _despawned: bool = false
var _lob_enabled: bool = false
var _lob_start_position: Vector2 = Vector2.ZERO
var _lob_target_position: Vector2 = Vector2.ZERO
var _lob_flight_time: float = 0.55
var _lob_arc_height: float = 80.0
var _lob_elapsed: float = 0.0
var _impact_requested: bool = false
var _weapon_sprite: Sprite2D
var _uses_weapon_texture: bool = false
var _hit_enemy_ids: Dictionary = {}

func _ready() -> void :
    process_mode = Node.PROCESS_MODE_PAUSABLE
    _total_life_time = max(0.01, life_time)
    _glitch_phase = randf_range(0.0, TAU)
    configure_visual_preset(visual_preset)
    queue_redraw()

func set_target(target: Node2D) -> void :
    _target = target

func configure_weapon_projectile(texture: Texture2D, target_width: float, configured_spin_speed: float) -> void:
    if texture == null:
        return
    _uses_weapon_texture = true
    visual_preset = "weapon_bounce"
    spin_speed = configured_spin_speed
    base_tint = Color(0.62, 0.98, 1.0, 1.0)
    outer_tint = Color(0.08, 0.55, 0.72, 0.78)
    core_tint = Color(1.0, 0.24, 0.48, 0.86)
    trail_strength = 0.76
    _glow_strength = 1.18
    if _weapon_sprite == null:
        _weapon_sprite = Sprite2D.new()
        _weapon_sprite.name = "WeaponSprite"
        _weapon_sprite.centered = true
        _weapon_sprite.z_index = 2
        add_child(_weapon_sprite)
    _weapon_sprite.texture = texture
    var raw_size: Vector2 = texture.get_size()
    var width: float = max(1.0, raw_size.x)
    var scale_factor: float = clampf(target_width / width, 0.02, 2.0)
    _weapon_sprite.scale = Vector2.ONE * scale_factor
    _weapon_sprite.modulate = Color(0.9, 0.98, 1.0, 0.96)

func is_bounce_weapon_projectile() -> bool:
    return impact_mode == "bounce_weapon"

func has_hit_enemy(enemy_id: int) -> bool:
    return _hit_enemy_ids.has(enemy_id)

func register_hit_enemy(enemy_id: int) -> void:
    _hit_enemy_ids[enemy_id] = true

func can_bounce() -> bool:
    return is_bounce_weapon_projectile() and bounce_count > 0 and bounce_range > 0.0

func bounce_to(target: Node2D) -> void:
    if target == null or not is_instance_valid(target):
        return
    bounce_count = max(0, bounce_count - 1)
    damage = max(1, int(round(float(damage) * clampf(bounce_damage_mult, 0.05, 1.0))))
    set_target(target)
    var to_target: Vector2 = target.global_position - global_position
    if to_target.length_squared() > 0.0001:
        direction = to_target.normalized()
    queue_redraw()

func configure_lob(target_position: Vector2, flight_time: float, arc_height: float) -> void:
    _lob_enabled = true
    _lob_start_position = global_position
    _lob_target_position = target_position
    _lob_flight_time = max(0.05, flight_time)
    _lob_arc_height = max(0.0, arc_height)
    _lob_elapsed = 0.0
    life_time = max(life_time, _lob_flight_time + 0.08)
    _total_life_time = max(0.01, life_time)
    var initial_direction: Vector2 = _lob_start_position.direction_to(_lob_target_position)
    if initial_direction.length_squared() > 0.0001:
        direction = initial_direction

func is_aoe_projectile() -> bool:
    return impact_mode == "aoe" and aoe_radius > 0.0

func consume_impact_request() -> bool:
    if not _impact_requested:
        return false
    _impact_requested = false
    return true

func configure_visual_preset(preset: String) -> void:
    visual_preset = preset
    match visual_preset:
        "weapon_bounce":
            spawn_flash_time = 0.05
            trail_strength = 0.76
            base_tint = Color(0.62, 0.98, 1.0, 1.0)
            outer_tint = Color(0.08, 0.55, 0.72, 0.78)
            core_tint = Color(1.0, 0.24, 0.48, 0.86)
            _body_length_scale = 1.65
            _body_width_scale = 0.82
            _trail_length_scale = 1.0
            _glow_strength = 1.18
        "homing":
            spawn_flash_time = 0.045
            trail_strength = 1.15
            base_tint = Color(0.5, 0.96, 1.0, 1.0)
            outer_tint = Color(0.06, 0.31, 0.45, 0.76)
            core_tint = Color(0.98, 1.0, 1.0, 1.0)
            _body_length_scale = 3.15
            _body_width_scale = 0.92
            _trail_length_scale = 1.18
            _glow_strength = 1.0
        "heavy":
            spawn_flash_time = 0.06
            trail_strength = 0.85
            base_tint = Color(0.42, 0.92, 1.0, 1.0)
            outer_tint = Color(0.04, 0.24, 0.38, 0.82)
            core_tint = Color(0.98, 1.0, 1.0, 1.0)
            _body_length_scale = 2.45
            _body_width_scale = 1.28
            _trail_length_scale = 0.88
            _glow_strength = 1.14
        "lob_aoe":
            spawn_flash_time = 0.07
            trail_strength = 0.72
            base_tint = Color(1.0, 0.45, 0.18, 1.0)
            outer_tint = Color(0.76, 0.12, 0.05, 0.78)
            core_tint = Color(1.0, 0.9, 0.48, 1.0)
            _body_length_scale = 2.15
            _body_width_scale = 1.35
            _trail_length_scale = 0.76
            _glow_strength = 1.28
        _:
            visual_preset = "default"
            spawn_flash_time = 0.05
            trail_strength = 1.0
            base_tint = Color(0.47, 0.94, 1.0, 1.0)
            outer_tint = Color(0.05, 0.28, 0.43, 0.74)
            core_tint = Color(0.96, 1.0, 1.0, 1.0)
            _body_length_scale = 2.8
            _body_width_scale = 1.0
            _trail_length_scale = 1.0
            _glow_strength = 1.0

func _physics_process(delta: float) -> void :
    if _impact_requested:
        return
    if _lob_enabled:
        _tick_lob_motion(delta)
        return
    if _target != null and is_instance_valid(_target):
        var to_target: Vector2 = _target.global_position - global_position
        if to_target.length_squared() > 0.0001:
            direction = to_target.normalized()
    _elapsed += delta
    global_position += direction.normalized() * speed * delta
    if _weapon_sprite != null and is_instance_valid(_weapon_sprite):
        _weapon_sprite.rotation += spin_speed * delta
    life_time -= delta
    if life_time <= 0.0:
        if is_aoe_projectile():
            _impact_requested = true
            queue_redraw()
            return
        despawn(false)
        return
    queue_redraw()

func _tick_lob_motion(delta: float) -> void:
    var previous_position: Vector2 = global_position
    _elapsed += delta
    _lob_elapsed += delta
    life_time -= delta
    var progress: float = clampf(_lob_elapsed / _lob_flight_time, 0.0, 1.0)
    var ground_position: Vector2 = _lob_start_position.lerp(_lob_target_position, progress)
    var arc_offset: Vector2 = Vector2.UP * sin(progress * PI) * _lob_arc_height
    global_position = ground_position + arc_offset
    var travel_direction: Vector2 = global_position - previous_position
    if travel_direction.length_squared() > 0.0001:
        direction = travel_direction.normalized()
    if progress >= 1.0 or life_time <= 0.0:
        global_position = _lob_target_position
        _impact_requested = true
    queue_redraw()

func _draw() -> void :
    var forward: Vector2 = direction.normalized()
    if forward.length_squared() <= 0.0001:
        forward = Vector2.RIGHT
    var side: Vector2 = forward.orthogonal()

    var speed_ratio: float = clampf((speed - 180.0) / 500.0, 0.0, 1.0)
    var flash_ratio: float = 0.0
    if spawn_flash_time > 0.0 and _elapsed < spawn_flash_time:
        flash_ratio = 1.0 - (_elapsed / spawn_flash_time)
    var fade_ratio: float = 1.0
    var tail_window: float = _total_life_time * 0.2
    if tail_window > 0.0 and life_time < tail_window:
        fade_ratio = clampf(life_time / tail_window, 0.0, 1.0)
    var flicker: float = 0.94 + 0.06 * sin(_elapsed * 30.0 + _glitch_phase)
    var alpha_scale: float = clampf(fade_ratio * flicker, 0.0, 1.0)
    var flash_boost: float = 1.0 + flash_ratio * 0.55

    var body_length: float = max(8.0, hit_radius * _body_length_scale * (1.0 + speed_ratio * 0.14))
    var body_half_width: float = max(2.2, hit_radius * _body_width_scale * (1.0 + flash_ratio * 0.1))
    var trail_length: float = max(body_length * 0.8, body_length * trail_strength * _trail_length_scale)
    var shadow_width: float = body_half_width * (1.55 + flash_ratio * 0.12)
    var glow_radius: float = max(hit_radius + 1.0, body_half_width * (1.9 + flash_ratio * 0.25))
    var glitch_amount: float = (0.35 + hit_radius * 0.05) * sin(_elapsed * 52.0 + _glitch_phase)
    var glitch_offset: Vector2 = side * glitch_amount

    var trail_color: Color = Color(
        outer_tint.r * 0.9,
        min(1.0, outer_tint.g * 1.1),
        min(1.0, outer_tint.b * 1.16),
        0.30 * alpha_scale * _glow_strength
    )
    var shadow_color: Color = Color(outer_tint.r, outer_tint.g, outer_tint.b, outer_tint.a * alpha_scale * _glow_strength)
    var body_color: Color = Color(
        min(1.0, base_tint.r * flash_boost),
        min(1.0, base_tint.g * flash_boost),
        min(1.0, base_tint.b * flash_boost),
        base_tint.a * alpha_scale
    )
    var core_color: Color = Color(
        min(1.0, core_tint.r * (1.0 + flash_ratio * 0.18)),
        min(1.0, core_tint.g * (1.0 + flash_ratio * 0.18)),
        min(1.0, core_tint.b * (1.0 + flash_ratio * 0.18)),
        core_tint.a * alpha_scale
    )
    var glitch_color: Color = Color(
        min(1.0, body_color.r * 0.82),
        min(1.0, body_color.g * 1.02),
        min(1.0, body_color.b * 1.08),
        0.22 * alpha_scale
    )

    if _uses_weapon_texture:
        draw_colored_polygon(
            _build_trail_points(forward, side, trail_length, body_length, body_half_width),
            trail_color
        )
        draw_circle(Vector2.ZERO, glow_radius, Color(0.15, 0.86, 1.0, 0.08 * alpha_scale * _glow_strength))
        draw_rect(Rect2(-side * (body_half_width + 1.0) - forward * 1.0, Vector2(body_half_width * 2.0 + 2.0, 1.0)), Color(1.0, 0.15, 0.35, 0.20 * alpha_scale), true)
        draw_rect(Rect2(side * (body_half_width * 0.7) - forward * (body_length * 0.45), Vector2(body_half_width * 1.3, 1.0)), Color(0.5, 0.96, 1.0, 0.24 * alpha_scale), true)
        return

    draw_colored_polygon(
        _build_trail_points(forward, side, trail_length, body_length, body_half_width),
        trail_color
    )
    draw_colored_polygon(
        _build_body_points(forward, side, body_length, shadow_width, glitch_offset * 0.45),
        shadow_color
    )
    draw_colored_polygon(
        _build_body_points(forward, side, body_length, body_half_width, glitch_offset),
        glitch_color
    )
    draw_colored_polygon(
        _build_body_points(forward, side, body_length, body_half_width, Vector2.ZERO),
        body_color
    )
    draw_colored_polygon(
        _build_body_points(forward, side, body_length * 0.74, body_half_width * 0.42, forward * (body_length * 0.03)),
        core_color
    )
    draw_circle(forward * (body_length * 0.12), glow_radius, Color(0.15, 0.86, 1.0, 0.07 * alpha_scale * _glow_strength))

func _build_trail_points(forward: Vector2, side: Vector2, trail_length: float, body_length: float, body_half_width: float) -> PackedVector2Array:
    var front_center: Vector2 = -forward * (body_length * 0.12)
    var front_left: Vector2 = front_center + side * (body_half_width * 0.68)
    var front_right: Vector2 = front_center - side * (body_half_width * 0.68)
    var tail_center: Vector2 = -forward * (trail_length + body_length * 0.26)
    return PackedVector2Array([
        front_left,
        front_right,
        tail_center,
    ])

func _build_body_points(
    forward: Vector2,
    side: Vector2,
    body_length: float,
    body_half_width: float,
    offset: Vector2
) -> PackedVector2Array:
    var nose: Vector2 = offset + forward * (body_length * 0.72)
    var shoulder_left: Vector2 = offset + forward * (body_length * 0.08) + side * body_half_width
    var shoulder_right: Vector2 = offset + forward * (body_length * 0.08) - side * body_half_width
    var rear_left: Vector2 = offset - forward * (body_length * 0.42) + side * (body_half_width * 0.38)
    var rear_right: Vector2 = offset - forward * (body_length * 0.42) - side * (body_half_width * 0.38)
    var tail: Vector2 = offset - forward * (body_length * 0.62)
    return PackedVector2Array([
        tail,
        rear_left,
        shoulder_left,
        nose,
        shoulder_right,
        rear_right,
    ])

func despawn(is_hit: bool, impact_direction: Vector2 = Vector2.ZERO) -> void:
    if _despawned:
        return
    _despawned = true
    _spawn_despawn_fx(is_hit, impact_direction)
    queue_free()

func spawn_impact_fx(impact_direction: Vector2 = Vector2.ZERO) -> void:
    _spawn_despawn_fx(true, impact_direction)

func _spawn_despawn_fx(is_hit: bool, impact_direction: Vector2) -> void:
    var parent_node: Node = get_parent()
    if parent_node == null or PROJECTILE_IMPACT_EFFECT_SCRIPT == null:
        return
    var effect = PROJECTILE_IMPACT_EFFECT_SCRIPT.new()
    if effect == null:
        return
    effect.global_position = global_position
    var effect_direction: Vector2 = impact_direction.normalized() if impact_direction.length_squared() > 0.0001 else direction.normalized()
    if effect_direction.length_squared() <= 0.0001:
        effect_direction = Vector2.RIGHT
    var effect_radius: float = max(hit_radius * 1.2, 5.0)
    if is_hit and is_aoe_projectile():
        effect_radius = max(effect_radius, aoe_radius)
    effect.configure(
        "player_hit" if is_hit else "player_fade",
        effect_radius,
        effect_direction,
        0.12 if is_hit else 0.08,
        outer_tint,
        base_tint,
        core_tint,
        1.0 if is_hit else 0.75
    )
    parent_node.add_child(effect)
