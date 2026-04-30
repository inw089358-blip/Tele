class_name Enemy
extends CharacterBody2D

static var _runtime_texture_cache: Dictionary = {}
const ENEMY_DEATH_VISUAL_FX_SCRIPT: Script = preload("res://scripts/effects/enemy_death_visual_fx.gd")

enum EnemyType {
    MELEE,
    RANGED,
    ELITE_WARDEN,
    BARRAGE,
    FAST_MELEE,
    CHARGER,
}

signal died(enemy: Enemy)
signal enemy_projectile_fired(
    shooter: Enemy,
    origin: Vector2,
    direction: Vector2,
    speed: float,
    damage: int,
    hit_radius: float,
    life_time: float,
    tint: Color
)

@export var move_speed: float = 120.0
@export var max_hp: int = 30
@export var body_radius: float = 8.0
@export var xp_drop_amount: int = 5
@export var enemy_type: EnemyType = EnemyType.MELEE
@export var is_elite: bool = false

var current_hp: int = max_hp
var damage_reduction_ratio: float = 0.0
var damage_multiplier: float = 1.0
var _target: Node2D
var _is_dead: bool = false
var _visual_sprite: Sprite2D
var _visual_move_frames: Array[int] = []
var _visual_anim_fps: float = 0.0
var _visual_flip_with_velocity: bool = true
var _visual_anim_time: float = 0.0
var _visual_anim_frame_index: int = 0
var _visual_has_sprite: bool = false
var _death_frames: Array[int] = []
var _death_anim_fps: float = 10.0
var _death_hold_seconds: float = 0.1

func _ready() -> void :
    _apply_profile_from_balance()
    _configure_visual_from_balance()
    process_mode = Node.PROCESS_MODE_PAUSABLE
    current_hp = max_hp
    add_to_group("enemies")
    queue_redraw()

func _apply_profile_from_balance() -> void:
    var type_key: String = _get_type_key()
    var profile: Dictionary = BalanceService.get_enemy_profile(type_key)
    move_speed = float(profile.get("move_speed", move_speed))
    max_hp = int(profile.get("max_hp", max_hp))
    body_radius = float(profile.get("body_radius", body_radius))
    xp_drop_amount = int(profile.get("xp_drop", xp_drop_amount))

func _get_type_key() -> String:
    match enemy_type:
        EnemyType.MELEE: return "melee"
        EnemyType.RANGED: return "ranged"
        EnemyType.ELITE_WARDEN: return "elite_warden"
        EnemyType.BARRAGE: return "barrage"
        EnemyType.FAST_MELEE: return "fast_melee"
        EnemyType.CHARGER: return "charger"
    return "melee"

func _configure_visual_from_balance() -> void:
    var type_key: String = _get_type_key()
    var profile: Dictionary = BalanceService.get_enemy_profile(type_key)
    var visual_value: Variant = profile.get("visual", {})
    if not (visual_value is Dictionary):
        _clear_visual_sprite()
        return
    var visual_config: Dictionary = visual_value
    _setup_visual_from_config(visual_config)

func _physics_process(delta: float) -> void :
    if GameManager.current_state != GameManager.GameState.PLAYING:
        return
    if _is_dead:
        return
    if _target == null:
        _tick_visual_animation(delta)
        return
    tick_ai(delta)
    _tick_visual_animation(delta)
    move_and_slide()

func tick_ai(_delta: float) -> void :
    var direction: Vector2 = (_target.global_position - global_position).normalized()
    velocity = direction * move_speed

func set_target(target: Node2D) -> void :
    _target = target

func get_display_name() -> String:
    return "Enemy"

func scale_outgoing_damage(base_damage: int) -> int:
    return max(1, int(round(float(max(1, base_damage)) * max(0.1, damage_multiplier))))

func try_fire_projectile(
    direction: Vector2,
    speed: float,
    damage: int,
    hit_radius: float,
    life_time: float,
    tint: Color = Color(1.0, 0.36, 0.3, 1.0)
) -> void :
    if _is_dead:
        return
    if direction.length_squared() <= 0.0001:
        return
    enemy_projectile_fired.emit(self, global_position, direction.normalized(), speed, damage, hit_radius, life_time, tint)

func fire_projectile_from(
    origin: Vector2,
    direction: Vector2,
    speed: float,
    damage: int,
    hit_radius: float,
    life_time: float,
    tint: Color = Color(1.0, 0.36, 0.3, 1.0)
) -> void:
    if _is_dead:
        return
    if direction.length_squared() <= 0.0001:
        return
    enemy_projectile_fired.emit(self, origin, direction.normalized(), speed, damage, hit_radius, life_time, tint)

func take_damage(amount: int) -> int:
    if _is_dead:
        return 0
    if amount <= 0:
        return 0
    var reduced_ratio: float = clampf(damage_reduction_ratio, 0.0, 0.95)
    var final_damage: int = int(round(float(amount) * (1.0 - reduced_ratio)))
    final_damage = max(1, final_damage)

    current_hp = max(0, current_hp - final_damage)
    queue_redraw()
    if current_hp <= 0:
        _is_dead = true
        died.emit(self)
        _enter_death_state_or_free()
    return final_damage

func is_combat_active() -> bool:
    return not _is_dead

func _draw() -> void :
    if not _visual_has_sprite:
        draw_circle(Vector2.ZERO, body_radius + 2.0, Color(0.18, 0.04, 0.05, 0.9))
        draw_circle(Vector2.ZERO, body_radius, Color(0.92, 0.28, 0.26, 1.0))
    if not _should_draw_health_bar():
        return
    var hp_ratio: float = float(current_hp) / float(max(max_hp, 1))
    var bar_width: float = 22.0
    var bar_height: float = 4.0
    var bar_pos: Vector2 = Vector2( - bar_width * 0.5, body_radius + 7.0)
    draw_rect(Rect2(bar_pos, Vector2(bar_width, bar_height)), Color(0.18, 0.1, 0.1, 0.9), true)
    draw_rect(Rect2(bar_pos, Vector2(bar_width * hp_ratio, bar_height)), Color(0.95, 0.22, 0.24, 1.0), true)

func _should_draw_health_bar() -> bool:
    return is_elite or enemy_type == EnemyType.ELITE_WARDEN

func _setup_visual_from_config(config: Dictionary) -> void:
    _clear_visual_sprite()
    var sprite_sheet_path: String = str(config.get("sprite_sheet_path", ""))
    if sprite_sheet_path.is_empty():
        return
    var sprite_texture: Texture2D = _load_texture_with_runtime_fallback(sprite_sheet_path)
    if sprite_texture == null:
        return

    var sprite: Sprite2D = Sprite2D.new()
    sprite.name = "VisualSprite"
    sprite.texture = sprite_texture
    sprite.centered = true
    sprite.hframes = max(1, int(config.get("hframes", 1)))
    sprite.vframes = max(1, int(config.get("vframes", 1)))
    
    var base_scale: float = max(0.01, float(config.get("scale", 1.0)))
    var elite_scale_multiplier: float = max(0.01, float(config.get("elite_scale_multiplier", 1.5)))
    var apply_elite_tint: bool = bool(config.get("apply_elite_tint", true))
    if is_elite:
        sprite.scale = Vector2.ONE * base_scale * elite_scale_multiplier
        if apply_elite_tint:
            sprite.modulate = Color(1.2, 1.1, 0.8, 1.0)
    else:
        sprite.scale = Vector2.ONE * base_scale
        var tint_raw: Variant = config.get("tint", "")
        if tint_raw is String and not str(tint_raw).is_empty():
            sprite.modulate = Color(str(tint_raw))
        elif tint_raw is Array:
            var tint_values: Array = tint_raw
            if tint_values.size() >= 3:
                var alpha: float = float(tint_values[3]) if tint_values.size() >= 4 else 1.0
                sprite.modulate = Color(
                    float(tint_values[0]),
                    float(tint_values[1]),
                    float(tint_values[2]),
                    alpha
                )
        
    sprite.z_index = 1
    add_child(sprite)

    var total_frames: int = max(1, sprite.hframes * sprite.vframes)
    _visual_move_frames = _sanitize_visual_frames(config.get("move_frames", []), total_frames)
    if _visual_move_frames.is_empty():
        _visual_move_frames = [0]
    _visual_anim_fps = max(0.0, float(config.get("anim_fps", 0.0)))
    _visual_flip_with_velocity = bool(config.get("flip_with_velocity", true))
    _death_frames = _sanitize_visual_frames(config.get("death_frames", [8, 9, 10, 11]), total_frames)
    _death_anim_fps = max(0.01, float(config.get("death_anim_fps", 10.0)))
    _death_hold_seconds = max(0.0, float(config.get("death_hold_seconds", 0.1)))
    _visual_anim_time = 0.0
    _visual_anim_frame_index = 0
    _visual_sprite = sprite
    _visual_has_sprite = true
    _apply_visual_frame()

func _sanitize_visual_frames(raw_frames: Variant, total_frames: int) -> Array[int]:
    var result: Array[int] = []
    if raw_frames is Array:
        var source_frames: Array = raw_frames
        for frame_value: Variant in source_frames:
            var frame_index: int = int(frame_value)
            if frame_index < 0 or frame_index >= total_frames:
                continue
            result.append(frame_index)
    return result

func _tick_visual_animation(delta: float) -> void:
    if _is_dead:
        return
    if not _visual_has_sprite or _visual_sprite == null:
        return
    if _visual_flip_with_velocity and absf(velocity.x) > 0.01:
        _visual_sprite.flip_h = velocity.x < 0.0
    if _visual_move_frames.is_empty():
        return
    if _visual_anim_fps <= 0.0:
        _apply_visual_frame()
        return

    var frame_step: float = 1.0 / _visual_anim_fps
    _visual_anim_time += delta
    while _visual_anim_time >= frame_step:
        _visual_anim_time -= frame_step
        _visual_anim_frame_index = (_visual_anim_frame_index + 1) % _visual_move_frames.size()
    _apply_visual_frame()

func _apply_visual_frame() -> void:
    if _visual_sprite == null or _visual_move_frames.is_empty():
        return
    var safe_index: int = clampi(_visual_anim_frame_index, 0, _visual_move_frames.size() - 1)
    _visual_sprite.frame = _visual_move_frames[safe_index]

func _enter_death_state_or_free() -> void:
    velocity = Vector2.ZERO
    _target = null
    _spawn_death_visual_fx()
    queue_free()

func _spawn_death_visual_fx() -> void:
    if not _visual_has_sprite:
        return
    if _visual_sprite == null or _death_frames.is_empty():
        return
    if ENEMY_DEATH_VISUAL_FX_SCRIPT == null:
        return
    var parent: Node = get_parent()
    if parent == null or not is_instance_valid(parent):
        return
    var fx: Node2D = ENEMY_DEATH_VISUAL_FX_SCRIPT.new() as Node2D
    if fx == null:
        return
    parent.add_child(fx)
    fx.global_position = global_position
    fx.call(
        "setup_from_enemy",
        _visual_sprite.texture,
        _visual_sprite.hframes,
        _visual_sprite.vframes,
        _visual_sprite.scale,
        _visual_sprite.flip_h,
        _visual_sprite.modulate,
        _death_frames.duplicate(),
        _death_anim_fps,
        _death_hold_seconds,
        _visual_sprite.z_index
    )

func _clear_visual_sprite() -> void:
    if _visual_sprite != null and is_instance_valid(_visual_sprite):
        _visual_sprite.queue_free()
    _visual_sprite = null
    _visual_move_frames.clear()
    _visual_anim_fps = 0.0
    _visual_flip_with_velocity = true
    _visual_anim_time = 0.0
    _visual_anim_frame_index = 0
    _visual_has_sprite = false
    _death_frames.clear()
    _death_anim_fps = 10.0
    _death_hold_seconds = 0.1

func _load_texture_with_runtime_fallback(path: String) -> Texture2D:
    if path.is_empty():
        return null
    if _runtime_texture_cache.has(path):
        var cached: Variant = _runtime_texture_cache[path]
        if cached is Texture2D:
            return cached as Texture2D

    var import_sidecar_path: String = "%s.import" % path
    if FileAccess.file_exists(import_sidecar_path):
        var imported_texture: Texture2D = load(path) as Texture2D
        if imported_texture != null:
            _runtime_texture_cache[path] = imported_texture
            return imported_texture

    if not FileAccess.file_exists(path):
        return null
    var file: FileAccess = FileAccess.open(path, FileAccess.READ)
    if file == null:
        return null
    var encoded: PackedByteArray = file.get_buffer(file.get_length())
    if encoded.is_empty():
        return null

    var image: Image = Image.new()
    var ext: String = path.get_extension().to_lower()
    var err: int = ERR_FILE_UNRECOGNIZED
    match ext:
        "png":
            err = image.load_png_from_buffer(encoded)
        "jpg", "jpeg":
            err = image.load_jpg_from_buffer(encoded)
        "webp":
            err = image.load_webp_from_buffer(encoded)
        _:
            err = image.load_png_from_buffer(encoded)
    if err != OK:
        return null

    var texture: ImageTexture = ImageTexture.create_from_image(image)
    _runtime_texture_cache[path] = texture
    return texture
