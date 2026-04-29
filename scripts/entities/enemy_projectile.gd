class_name EnemyProjectile
extends Node2D

const PROJECTILE_IMPACT_EFFECT_SCRIPT: Script = preload("res://scripts/effects/projectile_impact_effect.gd")

@export var speed: float = 260.0
@export var direction: Vector2 = Vector2.RIGHT
@export var damage: int = 10
@export var hit_radius: float = 5.0
@export var life_time: float = 4.0
@export var tint: Color = Color(1.0, 0.44, 0.34, 1.0)

var spawn_flash_time: float = 0.05
var trail_strength: float = 0.92

var _elapsed: float = 0.0
var _total_life_time: float = 4.0
var _glitch_phase: float = 0.0
var _despawned: bool = false

func _ready() -> void :
    process_mode = Node.PROCESS_MODE_PAUSABLE
    _total_life_time = max(0.01, life_time)
    _glitch_phase = randf_range(0.0, TAU)
    queue_redraw()

func _physics_process(delta: float) -> void :
    if direction.length_squared() <= 0.0001:
        direction = Vector2.RIGHT
    _elapsed += delta
    global_position += direction.normalized() * speed * delta
    life_time -= delta
    if life_time <= 0.0:
        despawn(false)
        return
    queue_redraw()

func _draw() -> void :
    var forward: Vector2 = direction.normalized()
    if forward.length_squared() <= 0.0001:
        forward = Vector2.RIGHT
    var side: Vector2 = forward.orthogonal()

    var speed_ratio: float = clampf((speed - 140.0) / 280.0, 0.0, 1.0)
    var flash_ratio: float = 0.0
    if spawn_flash_time > 0.0 and _elapsed < spawn_flash_time:
        flash_ratio = 1.0 - (_elapsed / spawn_flash_time)
    var fade_ratio: float = 1.0
    var tail_window: float = _total_life_time * 0.2
    if tail_window > 0.0 and life_time < tail_window:
        fade_ratio = clampf(life_time / tail_window, 0.0, 1.0)
    var flicker: float = 0.95 + 0.05 * sin(_elapsed * 26.0 + _glitch_phase)
    var alpha_scale: float = clampf(fade_ratio * flicker, 0.0, 1.0)

    var body_length: float = max(8.0, hit_radius * (2.5 + speed_ratio * 0.28))
    var body_half_width: float = max(2.6, hit_radius * (1.08 + flash_ratio * 0.08))
    var trail_length: float = max(body_length * 0.7, body_length * trail_strength)
    var shadow_width: float = body_half_width * (1.5 + flash_ratio * 0.1)
    var glow_radius: float = max(hit_radius + 1.0, body_half_width * 1.8)
    var glitch_offset: Vector2 = side * ((0.25 + hit_radius * 0.05) * sin(_elapsed * 44.0 + _glitch_phase))

    var shadow_color: Color = Color(0.22, 0.05, 0.07, 0.84 * alpha_scale)
    var trail_color: Color = Color(
        min(1.0, tint.r * 0.82),
        min(1.0, tint.g * 0.44),
        min(1.0, tint.b * 0.58),
        0.28 * alpha_scale
    )
    var body_color: Color = Color(
        min(1.0, tint.r * (1.0 + flash_ratio * 0.1)),
        min(1.0, tint.g * (1.0 + flash_ratio * 0.08)),
        min(1.0, tint.b * (1.0 + flash_ratio * 0.08)),
        tint.a * alpha_scale
    )
    var core_color: Color = Color(
        min(1.0, tint.r * 1.08),
        min(1.0, tint.g * 0.92 + 0.12),
        min(1.0, tint.b * 0.9 + 0.08),
        0.92 * alpha_scale
    )
    var glitch_color: Color = Color(
        min(1.0, body_color.r * 1.05),
        min(1.0, body_color.g * 0.86),
        min(1.0, body_color.b * 0.95),
        0.2 * alpha_scale
    )

    draw_colored_polygon(
        _build_trail_points(forward, side, trail_length, body_length, body_half_width),
        trail_color
    )
    draw_colored_polygon(
        _build_body_points(forward, side, body_length, shadow_width, glitch_offset * 0.35),
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
        _build_body_points(forward, side, body_length * 0.68, body_half_width * 0.46, forward * (body_length * 0.02)),
        core_color
    )
    draw_circle(forward * (body_length * 0.08), glow_radius, Color(tint.r, tint.g * 0.75, tint.b * 0.82, 0.08 * alpha_scale))

func _build_trail_points(forward: Vector2, side: Vector2, trail_length: float, body_length: float, body_half_width: float) -> PackedVector2Array:
    var front_center: Vector2 = -forward * (body_length * 0.1)
    var front_left: Vector2 = front_center + side * (body_half_width * 0.66)
    var front_right: Vector2 = front_center - side * (body_half_width * 0.66)
    var tail_center: Vector2 = -forward * (trail_length + body_length * 0.24)
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
    var nose: Vector2 = offset + forward * (body_length * 0.7)
    var shoulder_left: Vector2 = offset + forward * (body_length * 0.08) + side * body_half_width
    var shoulder_right: Vector2 = offset + forward * (body_length * 0.08) - side * body_half_width
    var rear_left: Vector2 = offset - forward * (body_length * 0.38) + side * (body_half_width * 0.4)
    var rear_right: Vector2 = offset - forward * (body_length * 0.38) - side * (body_half_width * 0.4)
    var tail: Vector2 = offset - forward * (body_length * 0.58)
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
    effect.configure(
        "enemy_hit" if is_hit else "enemy_fade",
        max(hit_radius * 1.25, 5.0),
        effect_direction,
        0.11 if is_hit else 0.075,
        Color(0.22, 0.05, 0.07, 0.84),
        tint,
        Color(1.0, 0.9, 0.88, 1.0),
        0.95 if is_hit else 0.68
    )
    parent_node.add_child(effect)
