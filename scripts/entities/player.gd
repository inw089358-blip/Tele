class_name Player
extends CharacterBody2D

@export var move_speed: float = 220.0
@export var max_hp: int = 100
@export var body_radius: float = 12.0
@export var pickup_radius: float = 92.0
@export var stamina_max: float = 100.0
@export var stamina_recover_per_sec: float = 26.0
@export var dash_cost: float = 28.0
@export var dash_duration: float = 0.18
@export var dash_speed_multiplier: float = 3.2
@export var base_target_range: float = 320.0

var current_hp: int = max_hp
var current_stamina: float = stamina_max
var bonus_target_range: float = 0.0
var bonus_attack_damage: int = 0
var bonus_melee_attack_damage: int = 0
var bonus_ranged_attack_damage: int = 0
var global_attack_percent: float = 0.0
var armor: float = 0.0
var dodge_chance: float = 0.0
var attack_speed_mult: float = 1.0
var crit_chance: float = 0.05
var crit_multiplier: float = 1.5
var lifesteal: float = 0.0
var luck: float = 0.0
var harvest: float = 0.0
var hp_regen: float = 0.0
var xp_gain_mult: float = 1.0

var _dash_timer: float = 0.0
var _last_move_direction: Vector2 = Vector2.RIGHT
var _attribute_rules: Dictionary = {}
var _is_dead: bool = false
var _attack_flat_to_global_attack_percent: float = 3.0
var _crit_multiplier_to_crit_chance_ratio: float = 0.12
var _hp_regen_first_hps: float = 0.2
var _hp_regen_extra_hps_per_point: float = 0.089
var _hp_regen_elapsed: float = 0.0
var _lifesteal_internal_cooldown_seconds: float = 0.1
var _lifesteal_cooldown_remaining: float = 0.0
var _visual_sprite: Sprite2D
var _visual_move_frames: Array[int] = []
var _visual_anim_fps: float = 0.0
var _visual_flip_with_velocity: bool = true
var _visual_anim_time: float = 0.0
var _visual_anim_frame_index: int = 0
var _visual_idle_frame: int = 0
var _visual_has_sprite: bool = false
var _visual_directional_move_frames: Dictionary = {}
var _visual_directional_idle_frames: Dictionary = {}
var _visual_direction_key: String = "down"

func _ready() -> void :
    process_mode = Node.PROCESS_MODE_PAUSABLE
    _load_attribute_rules()
    _clamp_runtime_stats()
    _ensure_collision_shape()
    current_hp = max_hp
    current_stamina = stamina_max
    _hp_regen_elapsed = 0.0
    queue_redraw()

func _physics_process(delta: float) -> void :
    if _is_dead:
        velocity = Vector2.ZERO
        return
    _try_start_dash()
    _dash_timer = max(0.0, _dash_timer - delta)
    _lifesteal_cooldown_remaining = max(0.0, _lifesteal_cooldown_remaining - delta)
    if _dash_timer <= 0.0:
        current_stamina = min(stamina_max, current_stamina + stamina_recover_per_sec * delta)
    _tick_hp_regen(delta)

    var movement: Vector2 = Vector2(
        Input.get_action_strength("move_right") - Input.get_action_strength("move_left"), 
        Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
    )
    if movement.length_squared() > 0.0:
        _last_move_direction = movement.normalized()

    var move_vector: Vector2 = movement
    if _dash_timer > 0.0 and move_vector.length_squared() == 0.0:
        move_vector = _last_move_direction

    var speed_scale: float = dash_speed_multiplier if _dash_timer > 0.0 else 1.0
    velocity = move_vector.normalized() * move_speed * speed_scale
    move_and_slide()
    _tick_visual_animation(delta)

func take_damage(amount: int) -> int:
    if amount <= 0:
        return 0
    if _is_dead:
        return 0
    if _roll_dodge():
        return 0
    var final_damage: int = _calculate_damage_after_armor(amount)
    current_hp = max(0, current_hp - final_damage)
    if current_hp <= 0:
        _is_dead = true
        velocity = Vector2.ZERO
        _set_collision_enabled(false)
        EventBus.player_died.emit()
    return final_damage

func _set_collision_enabled(enabled: bool) -> void:
    for child: Node in get_children():
        if child is CollisionShape2D:
            var shape_node: CollisionShape2D = child
            shape_node.disabled = not enabled

func _try_start_dash() -> void :
    if _dash_timer > 0.0:
        return
    if not Input.is_key_pressed(KEY_SPACE):
        return
    if not Input.is_action_just_pressed("skill"):
        return
    if current_stamina < dash_cost:
        return
    current_stamina = max(0.0, current_stamina - dash_cost)
    _dash_timer = dash_duration

func _draw() -> void :
    if not _visual_has_sprite:
        draw_circle(Vector2.ZERO, body_radius + 2.0, Color(0.15, 0.12, 0.08, 0.85))
        draw_circle(Vector2.ZERO, body_radius, Color(0.93, 0.86, 0.69, 1.0))

func setup_visual_from_config(config: Dictionary) -> void:
    _clear_visual_sprite()
    var sprite_sheet_path: String = str(config.get("sprite_sheet_path", ""))
    if sprite_sheet_path.is_empty():
        queue_redraw()
        return
    var sprite_texture: Texture2D = _load_texture_with_runtime_fallback(sprite_sheet_path)
    if sprite_texture == null:
        queue_redraw()
        return

    var sprite: Sprite2D = Sprite2D.new()
    sprite.name = "VisualSprite"
    sprite.texture = sprite_texture
    sprite.centered = true
    sprite.hframes = max(1, int(config.get("hframes", 1)))
    sprite.vframes = max(1, int(config.get("vframes", 1)))
    sprite.scale = Vector2.ONE * max(0.01, float(config.get("scale", 1.0)))
    sprite.z_index = 1
    add_child(sprite)

    var total_frames: int = max(1, sprite.hframes * sprite.vframes)
    _visual_move_frames = _sanitize_visual_frames(config.get("move_frames", []), total_frames)
    if _visual_move_frames.is_empty():
        _visual_move_frames = [0]
    _visual_idle_frame = clampi(int(config.get("idle_frame", _visual_move_frames[0])), 0, total_frames - 1)
    _visual_directional_move_frames = _sanitize_directional_visual_frames(
        config.get("directional_move_frames", {}),
        total_frames
    )
    _visual_directional_idle_frames = _sanitize_directional_idle_frames(
        config.get("directional_idle_frames", {}),
        total_frames
    )
    _visual_anim_fps = max(0.0, float(config.get("anim_fps", 0.0)))
    _visual_flip_with_velocity = bool(config.get("flip_with_velocity", true))
    _visual_anim_time = 0.0
    _visual_anim_frame_index = 0
    _visual_direction_key = str(config.get("default_direction", "down"))
    _visual_sprite = sprite
    _visual_has_sprite = true
    _apply_visual_frame(_get_visual_idle_frame(_visual_direction_key))
    queue_redraw()

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

func _sanitize_directional_visual_frames(raw_frames: Variant, total_frames: int) -> Dictionary:
    var result: Dictionary = {}
    if not (raw_frames is Dictionary):
        return result
    var source_frames: Dictionary = raw_frames
    for direction_key: Variant in source_frames.keys():
        var direction_name: String = str(direction_key)
        var frames: Array[int] = _sanitize_visual_frames(source_frames[direction_key], total_frames)
        if frames.is_empty():
            continue
        result[direction_name] = frames
    return result

func _sanitize_directional_idle_frames(raw_frames: Variant, total_frames: int) -> Dictionary:
    var result: Dictionary = {}
    if not (raw_frames is Dictionary):
        return result
    var source_frames: Dictionary = raw_frames
    for direction_key: Variant in source_frames.keys():
        var direction_name: String = str(direction_key)
        result[direction_name] = clampi(int(source_frames[direction_key]), 0, total_frames - 1)
    return result

func _tick_visual_animation(delta: float) -> void:
    if not _visual_has_sprite or _visual_sprite == null:
        return
    var uses_directional_frames: bool = not _visual_directional_move_frames.is_empty()
    if uses_directional_frames:
        var next_direction_key: String = _resolve_visual_direction_key()
        if next_direction_key != _visual_direction_key:
            _visual_direction_key = next_direction_key
            _visual_anim_time = 0.0
            _visual_anim_frame_index = 0
        if _visual_flip_with_velocity and next_direction_key == "side" and absf(velocity.x) > 0.01:
            _visual_sprite.flip_h = velocity.x < 0.0
        elif next_direction_key != "side":
            _visual_sprite.flip_h = false
    elif _visual_flip_with_velocity and absf(velocity.x) > 0.01:
        _visual_sprite.flip_h = velocity.x < 0.0
    if velocity.length_squared() <= 0.01:
        _visual_anim_time = 0.0
        _visual_anim_frame_index = 0
        _apply_visual_frame(_get_visual_idle_frame(_visual_direction_key))
        return
    var active_move_frames: Array[int] = _get_visual_move_frames(_visual_direction_key)
    if active_move_frames.is_empty():
        return
    if _visual_anim_fps <= 0.0:
        _apply_visual_frame(active_move_frames[0])
        return

    var frame_step: float = 1.0 / _visual_anim_fps
    _visual_anim_time += delta
    while _visual_anim_time >= frame_step:
        _visual_anim_time -= frame_step
        _visual_anim_frame_index = (_visual_anim_frame_index + 1) % active_move_frames.size()
    var safe_index: int = clampi(_visual_anim_frame_index, 0, active_move_frames.size() - 1)
    _apply_visual_frame(active_move_frames[safe_index])

func _resolve_visual_direction_key() -> String:
    if velocity.length_squared() <= 0.01:
        return _visual_direction_key
    if absf(velocity.x) >= absf(velocity.y):
        return "side"
    if velocity.y < 0.0:
        return "up"
    return "down"

func _get_visual_move_frames(direction_key: String) -> Array[int]:
    if _visual_directional_move_frames.has(direction_key):
        return _copy_visual_frame_array(_visual_directional_move_frames[direction_key])
    if _visual_directional_move_frames.has("down"):
        return _copy_visual_frame_array(_visual_directional_move_frames["down"])
    return _visual_move_frames

func _copy_visual_frame_array(raw_frames: Variant) -> Array[int]:
    var result: Array[int] = []
    if raw_frames is Array:
        var frames: Array = raw_frames
        for frame_value: Variant in frames:
            result.append(int(frame_value))
    return result

func _get_visual_idle_frame(direction_key: String) -> int:
    if _visual_directional_idle_frames.has(direction_key):
        return int(_visual_directional_idle_frames[direction_key])
    if _visual_directional_idle_frames.has("down"):
        return int(_visual_directional_idle_frames["down"])
    return _visual_idle_frame

func _apply_visual_frame(frame_index: int) -> void:
    if _visual_sprite == null:
        return
    _visual_sprite.frame = frame_index

func _clear_visual_sprite() -> void:
    if _visual_sprite != null and is_instance_valid(_visual_sprite):
        _visual_sprite.queue_free()
    _visual_sprite = null
    _visual_move_frames.clear()
    _visual_anim_fps = 0.0
    _visual_flip_with_velocity = true
    _visual_anim_time = 0.0
    _visual_anim_frame_index = 0
    _visual_idle_frame = 0
    _visual_has_sprite = false
    _visual_directional_move_frames.clear()
    _visual_directional_idle_frames.clear()
    _visual_direction_key = "down"

func _load_texture_with_runtime_fallback(path: String) -> Texture2D:
    if path.is_empty():
        return null
    var import_sidecar_path: String = "%s.import" % path
    if FileAccess.file_exists(import_sidecar_path):
        var imported_texture: Texture2D = load(path) as Texture2D
        if imported_texture != null:
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
    return ImageTexture.create_from_image(image)

func get_current_target_range() -> float:
    return max(80.0, base_target_range + bonus_target_range)

func add_target_range(amount: float) -> void :
    bonus_target_range += amount

func add_attack_damage(amount: int) -> void :
    bonus_attack_damage += amount

func add_melee_attack_damage(amount: int) -> void:
    bonus_melee_attack_damage += amount

func add_ranged_attack_damage(amount: int) -> void:
    bonus_ranged_attack_damage += amount

func add_global_attack_percent(amount: float) -> void:
    global_attack_percent += amount

func add_harvest(amount: float) -> void:
    harvest += amount

func add_hp_regen(amount: float) -> void:
    hp_regen += amount

func get_attack_damage_bonus() -> int:
    return bonus_attack_damage

func get_melee_attack_damage_bonus() -> int:
    return bonus_melee_attack_damage

func get_ranged_attack_damage_bonus() -> int:
    return bonus_ranged_attack_damage

func get_global_attack_percent() -> float:
    return global_attack_percent

func get_harvest() -> float:
    return harvest

func get_hp_regen() -> float:
    return hp_regen

func add_move_speed(amount: float) -> void :
    move_speed += amount

func apply_profile(profile: Dictionary) -> void:
    move_speed = float(profile.get("move_speed", move_speed))
    max_hp = int(profile.get("max_hp", max_hp))
    base_target_range = float(profile.get("base_target_range", base_target_range))
    armor = float(profile.get("armor", armor))
    dodge_chance = float(profile.get("dodge_chance", dodge_chance))
    attack_speed_mult = float(profile.get("attack_speed_mult", attack_speed_mult))
    global_attack_percent = float(profile.get("global_attack_percent", global_attack_percent))
    crit_chance = float(profile.get("crit_chance", crit_chance))
    crit_multiplier = float(profile.get("crit_multiplier", crit_multiplier))
    lifesteal = float(profile.get("lifesteal", lifesteal))
    luck = float(profile.get("luck", luck))
    harvest = float(profile.get("harvest", harvest))
    hp_regen = float(profile.get("hp_regen", hp_regen))
    xp_gain_mult = float(profile.get("xp_gain_mult", xp_gain_mult))
    _clamp_runtime_stats()

func apply_effect(effect_type: String, value: Variant) -> bool:
    match effect_type:
        "attack_damage_flat":
            var legacy_amount: int = int(value)
            add_attack_damage(legacy_amount)
            add_global_attack_percent(float(legacy_amount) * _attack_flat_to_global_attack_percent)
        "melee_damage_flat":
            add_melee_attack_damage(int(value))
        "ranged_damage_flat":
            add_ranged_attack_damage(int(value))
        "global_attack_percent_flat":
            add_global_attack_percent(float(value))
        "target_range_flat":
            add_target_range(float(value))
        "move_speed_flat":
            add_move_speed(float(value))
        "max_hp_flat":
            var hp_delta: int = int(value)
            max_hp = max(1, max_hp + hp_delta)
            current_hp = clampi(current_hp + hp_delta, 0, max_hp)
        "heal_flat":
            current_hp = clampi(current_hp + int(value), 0, max_hp)
        "stamina_recover_mult":
            stamina_recover_per_sec = max(1.0, stamina_recover_per_sec * float(value))
        "armor_flat":
            armor += float(value)
        "dodge_chance_flat":
            dodge_chance += float(value)
        "attack_speed_mult":
            attack_speed_mult *= float(value)
        "auto_attack_interval_mult":
            var interval_mult: float = max(0.05, float(value))
            attack_speed_mult *= 1.0 / interval_mult
        "crit_chance_flat":
            crit_chance += float(value)
        "crit_multiplier_flat":
            crit_chance += float(value) * _crit_multiplier_to_crit_chance_ratio
        "lifesteal_flat":
            lifesteal += float(value)
        "luck_flat":
            luck += float(value)
        "harvest_flat":
            harvest += float(value)
        "hp_regen_flat":
            add_hp_regen(float(value))
        "xp_gain_mult":
            xp_gain_mult *= float(value)
        _:
            return false
    _clamp_runtime_stats()
    return true

func get_attack_speed_multiplier() -> float:
    return attack_speed_mult

func get_xp_gain_multiplier() -> float:
    return xp_gain_mult

func roll_outgoing_damage(base_damage: int, base_crit_chance: float = -1.0, base_crit_multiplier: float = -1.0) -> int:
    var damage_value: int = max(1, base_damage)
    var chance: float = crit_chance if base_crit_chance < 0.0 else base_crit_chance
    var multiplier: float = 1.5 if base_crit_multiplier < 0.0 else base_crit_multiplier
    if randf() < clampf(chance, 0.0, 1.0):
        damage_value = max(1, int(floor(float(damage_value) * max(1.0, multiplier))))
    return damage_value

func heal(amount: int) -> int:
    if _is_dead or amount <= 0:
        return 0
    var old_hp: int = current_hp
    current_hp = clampi(current_hp + amount, 0, max_hp)
    var healed: int = current_hp - old_hp
    if healed > 0:
        # Simple health flash using modulate if possible, or just skip visual feedback for now
        var tween = create_tween()
        tween.tween_property(self, "modulate", Color(0.5, 1.0, 0.5), 0.1)
        tween.tween_property(self, "modulate", Color.WHITE, 0.1)
    return healed

func heal_from_lifesteal(dealt_damage: int, ratio: float = -1.0) -> int:

    if dealt_damage <= 0:
        return 0
    var lifesteal_chance: float = lifesteal if ratio < 0.0 else ratio
    return try_lifesteal_on_hit(lifesteal_chance)

func try_lifesteal_on_hit(lifesteal_chance: float) -> int:
    if _is_dead:
        return 0
    if current_hp >= max_hp:
        return 0
    if _lifesteal_cooldown_remaining > 0.0:
        return 0
    var chance: float = clampf(lifesteal_chance, 0.0, 1.0)
    if chance <= 0.0:
        return 0
    if randf() >= chance:
        return 0
    var hp_before: int = current_hp
    current_hp = clampi(current_hp + 1, 0, max_hp)
    if current_hp > hp_before:
        _lifesteal_cooldown_remaining = max(0.0, _lifesteal_internal_cooldown_seconds)
    return max(0, current_hp - hp_before)

func export_runtime_stats() -> Dictionary:
    return {
        "armor": armor,
        "dodge_chance": dodge_chance,
        "attack_speed_mult": attack_speed_mult,
        "bonus_melee_attack_damage": bonus_melee_attack_damage,
        "bonus_ranged_attack_damage": bonus_ranged_attack_damage,
        "global_attack_percent": global_attack_percent,
        "crit_chance": crit_chance,
        "lifesteal": lifesteal,
        "luck": luck,
        "harvest": harvest,
        "hp_regen": hp_regen,
        "xp_gain_mult": xp_gain_mult,
    }

func import_runtime_stats(raw_stats: Dictionary) -> void:
    armor = float(raw_stats.get("armor", armor))
    dodge_chance = float(raw_stats.get("dodge_chance", dodge_chance))
    attack_speed_mult = float(raw_stats.get("attack_speed_mult", attack_speed_mult))
    bonus_melee_attack_damage = int(raw_stats.get("bonus_melee_attack_damage", bonus_melee_attack_damage))
    bonus_ranged_attack_damage = int(raw_stats.get("bonus_ranged_attack_damage", bonus_ranged_attack_damage))
    global_attack_percent = float(raw_stats.get("global_attack_percent", global_attack_percent))
    crit_chance = float(raw_stats.get("crit_chance", crit_chance))
    lifesteal = float(raw_stats.get("lifesteal", lifesteal))
    luck = float(raw_stats.get("luck", luck))
    harvest = float(raw_stats.get("harvest", harvest))
    hp_regen = float(raw_stats.get("hp_regen", hp_regen))
    xp_gain_mult = float(raw_stats.get("xp_gain_mult", xp_gain_mult))
    _clamp_runtime_stats()

func _tick_hp_regen(delta: float) -> void:
    if current_hp >= max_hp:
        _hp_regen_elapsed = 0.0
        return
    if hp_regen <= 0.0:
        _hp_regen_elapsed = 0.0
        return
    var hps: float = _resolve_hp_regen_hps()
    if hps <= 0.0:
        _hp_regen_elapsed = 0.0
        return
    var tick_interval: float = 1.0 / hps
    _hp_regen_elapsed += max(0.0, delta)
    while _hp_regen_elapsed >= tick_interval:
        _hp_regen_elapsed -= tick_interval
        current_hp = clampi(current_hp + 1, 0, max_hp)
        if current_hp >= max_hp:
            _hp_regen_elapsed = 0.0
            return

func _resolve_hp_regen_hps() -> float:
    if hp_regen <= 0.0:
        return 0.0
    return max(0.0, _hp_regen_first_hps + (hp_regen - 1.0) * _hp_regen_extra_hps_per_point)

func _ensure_collision_shape() -> void:
    for child: Node in get_children():
        if child is CollisionShape2D:
            var existing_collision: CollisionShape2D = child
            if existing_collision.shape == null:
                var fallback_shape: CircleShape2D = CircleShape2D.new()
                fallback_shape.radius = max(1.0, body_radius)
                existing_collision.shape = fallback_shape
            return

    var collision_shape: CollisionShape2D = CollisionShape2D.new()
    collision_shape.name = "AutoCollisionShape2D"
    var circle_shape: CircleShape2D = CircleShape2D.new()
    circle_shape.radius = max(1.0, body_radius)
    collision_shape.shape = circle_shape
    add_child(collision_shape)

func _load_attribute_rules() -> void:
    var combat_params: Dictionary = BalanceService.get_global_combat_params()
    _attribute_rules = combat_params.get("attribute_rules", {})
    _attack_flat_to_global_attack_percent = max(
        0.0,
        float(combat_params.get("attack_flat_to_global_attack_percent", _attack_flat_to_global_attack_percent))
    )
    _crit_multiplier_to_crit_chance_ratio = max(
        0.0,
        float(combat_params.get("crit_multiplier_to_crit_chance_ratio", _crit_multiplier_to_crit_chance_ratio))
    )
    _hp_regen_first_hps = max(
        0.0,
        float(combat_params.get("hp_regen_first_hps", _hp_regen_first_hps))
    )
    _hp_regen_extra_hps_per_point = max(
        0.0,
        float(combat_params.get("hp_regen_extra_hps_per_point", _hp_regen_extra_hps_per_point))
    )
    _lifesteal_internal_cooldown_seconds = max(
        0.0,
        float(combat_params.get("lifesteal_internal_cooldown_seconds", _lifesteal_internal_cooldown_seconds))
    )

func _get_rule_float(rule_key: String, fallback_value: float) -> float:
    return float(_attribute_rules.get(rule_key, fallback_value))

func _clamp_runtime_stats() -> void:
    armor = clampf(armor, _get_rule_float("armor_min", -10.0), _get_rule_float("armor_max", 30.0))
    dodge_chance = clampf(dodge_chance, _get_rule_float("dodge_min", 0.0), _get_rule_float("dodge_max", 0.6))
    attack_speed_mult = clampf(
        attack_speed_mult,
        _get_rule_float("attack_speed_min", 0.3),
        _get_rule_float("attack_speed_max", 2.5)
    )
    crit_chance = clampf(crit_chance, _get_rule_float("crit_chance_min", 0.0), _get_rule_float("crit_chance_max", 0.75))
    lifesteal = clampf(lifesteal, _get_rule_float("lifesteal_min", 0.0), _get_rule_float("lifesteal_max", 0.25))
    global_attack_percent = clampf(
        global_attack_percent,
        _get_rule_float("global_attack_percent_min", -80.0),
        _get_rule_float("global_attack_percent_max", 500.0)
    )
    luck = clampf(luck, _get_rule_float("luck_min", -20.0), _get_rule_float("luck_max", 100.0))
    harvest = clampf(harvest, _get_rule_float("harvest_min", -50.0), _get_rule_float("harvest_max", 300.0))
    hp_regen = clampf(hp_regen, _get_rule_float("hp_regen_min", 0.0), _get_rule_float("hp_regen_max", 100.0))
    xp_gain_mult = clampf(
        xp_gain_mult,
        _get_rule_float("xp_gain_mult_min", 1.0),
        _get_rule_float("xp_gain_mult_max", 1.8)
    )

func _roll_dodge() -> bool:
    return randf() < dodge_chance

func _calculate_damage_after_armor(raw_damage: int) -> int:
    var armor_scale: float = _get_rule_float("armor_scale", 8.0)
    var denominator: float = 100.0 + armor * armor_scale
    if denominator <= 1.0:
        denominator = 1.0
    var reduced_damage: int = int(ceil(float(raw_damage) * 100.0 / denominator))
    return max(1, reduced_damage)
