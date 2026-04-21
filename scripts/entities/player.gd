class_name Player
extends CharacterBody2D

@export var move_speed: float = 220.0
@export var max_hp: int = 100
@export var body_radius: float = 9.0
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
var armor: float = 0.0
var dodge_chance: float = 0.0
var attack_speed_mult: float = 1.0
var crit_chance: float = 0.05
var crit_multiplier: float = 1.5
var lifesteal: float = 0.0
var luck: float = 0.0
var xp_gain_mult: float = 1.0

var _dash_timer: float = 0.0
var _last_move_direction: Vector2 = Vector2.RIGHT
var _attribute_rules: Dictionary = {}

func _ready() -> void :
    process_mode = Node.PROCESS_MODE_PAUSABLE
    _load_attribute_rules()
    _clamp_runtime_stats()
    _ensure_collision_shape()
    current_hp = max_hp
    current_stamina = stamina_max
    queue_redraw()

func _physics_process(delta: float) -> void :
    _try_start_dash()
    _dash_timer = max(0.0, _dash_timer - delta)
    if _dash_timer <= 0.0:
        current_stamina = min(stamina_max, current_stamina + stamina_recover_per_sec * delta)

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

func take_damage(amount: int) -> int:
    if amount <= 0:
        return 0
    if _roll_dodge():
        return 0
    var final_damage: int = _calculate_damage_after_armor(amount)
    current_hp = max(0, current_hp - final_damage)
    if current_hp <= 0:
        EventBus.player_died.emit()
        queue_free()
    return final_damage

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
    draw_circle(Vector2.ZERO, body_radius + 2.0, Color(0.15, 0.12, 0.08, 0.85))
    draw_circle(Vector2.ZERO, body_radius, Color(0.93, 0.86, 0.69, 1.0))

func get_current_target_range() -> float:
    return max(80.0, base_target_range + bonus_target_range)

func add_target_range(amount: float) -> void :
    bonus_target_range += amount

func add_attack_damage(amount: int) -> void :
    bonus_attack_damage += amount

func get_attack_damage_bonus() -> int:
    return bonus_attack_damage

func add_move_speed(amount: float) -> void :
    move_speed += amount

func apply_profile(profile: Dictionary) -> void:
    move_speed = float(profile.get("move_speed", move_speed))
    max_hp = int(profile.get("max_hp", max_hp))
    base_target_range = float(profile.get("base_target_range", base_target_range))
    armor = float(profile.get("armor", armor))
    dodge_chance = float(profile.get("dodge_chance", dodge_chance))
    attack_speed_mult = float(profile.get("attack_speed_mult", attack_speed_mult))
    crit_chance = float(profile.get("crit_chance", crit_chance))
    crit_multiplier = float(profile.get("crit_multiplier", crit_multiplier))
    lifesteal = float(profile.get("lifesteal", lifesteal))
    luck = float(profile.get("luck", luck))
    xp_gain_mult = float(profile.get("xp_gain_mult", xp_gain_mult))
    _clamp_runtime_stats()

func apply_effect(effect_type: String, value: Variant) -> bool:
    match effect_type:
        "attack_damage_flat":
            add_attack_damage(int(value))
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
            crit_multiplier += float(value)
        "lifesteal_flat":
            lifesteal += float(value)
        "luck_flat":
            luck += float(value)
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
    var multiplier: float = crit_multiplier if base_crit_multiplier < 0.0 else base_crit_multiplier
    if randf() < clampf(chance, 0.0, 1.0):
        damage_value = max(1, int(floor(float(damage_value) * max(1.0, multiplier))))
    return damage_value

func heal_from_lifesteal(dealt_damage: int, ratio: float = -1.0) -> int:
    if dealt_damage <= 0:
        return 0
    var lifesteal_ratio: float = lifesteal if ratio < 0.0 else ratio
    if lifesteal_ratio <= 0.0:
        return 0
    var heal_amount: int = int(floor(float(dealt_damage) * lifesteal_ratio))
    if heal_amount <= 0:
        return 0
    var hp_before: int = current_hp
    current_hp = clampi(current_hp + heal_amount, 0, max_hp)
    return max(0, current_hp - hp_before)

func export_runtime_stats() -> Dictionary:
    return {
        "armor": armor,
        "dodge_chance": dodge_chance,
        "attack_speed_mult": attack_speed_mult,
        "crit_chance": crit_chance,
        "crit_multiplier": crit_multiplier,
        "lifesteal": lifesteal,
        "luck": luck,
        "xp_gain_mult": xp_gain_mult,
    }

func import_runtime_stats(raw_stats: Dictionary) -> void:
    armor = float(raw_stats.get("armor", armor))
    dodge_chance = float(raw_stats.get("dodge_chance", dodge_chance))
    attack_speed_mult = float(raw_stats.get("attack_speed_mult", attack_speed_mult))
    crit_chance = float(raw_stats.get("crit_chance", crit_chance))
    crit_multiplier = float(raw_stats.get("crit_multiplier", crit_multiplier))
    lifesteal = float(raw_stats.get("lifesteal", lifesteal))
    luck = float(raw_stats.get("luck", luck))
    xp_gain_mult = float(raw_stats.get("xp_gain_mult", xp_gain_mult))
    _clamp_runtime_stats()

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
    crit_multiplier = clampf(
        crit_multiplier,
        _get_rule_float("crit_multiplier_min", 1.5),
        _get_rule_float("crit_multiplier_max", 3.0)
    )
    lifesteal = clampf(lifesteal, _get_rule_float("lifesteal_min", 0.0), _get_rule_float("lifesteal_max", 0.25))
    luck = clampf(luck, _get_rule_float("luck_min", -20.0), _get_rule_float("luck_max", 100.0))
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
