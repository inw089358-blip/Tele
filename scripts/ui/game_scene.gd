extends Node2D

@onready var state_label: Label = _resolve_state_label()
@onready var wave_manager: WaveManager = $WaveManager
@onready var hud: CanvasLayer = $HUD
@onready var pause_overlay: Control = %PauseOverlay
@onready var pause_panel: PanelContainer = $PauseLayer / PauseOverlay / PausePanel
@onready var pause_dimmer: ColorRect = $PauseLayer / PauseOverlay / Dimmer
@onready var crt_overlay: ColorRect = $CRTLayer / CRTOverlay
@onready var resume_button: Button = %ResumeButton
@onready var main_menu_button: Button = %MainMenuButton
@onready var save_button: Button = %SaveButton
@onready var settings_button: Button = %SettingsButton

const PLAYER_SCRIPT_MAP: Dictionary[String, Script] = {
    "the_fool": preload("res://scripts/characters/the_fool.gd"), 
    "the_chariot": preload("res://scripts/characters/the_chariot.gd"), 
    "the_hanged_man": preload("res://scripts/characters/the_hanged_man.gd"), 
}
const SAVE_SLOT_PANEL_SCENE_PATH: String = "res://scenes/ui/save_slot_panel.tscn"
const SETTINGS_SCENE_PATH: String = "res://scenes/settings.tscn"
const NEON_OPTION_BUTTON_SCRIPT: Script = preload("res://scripts/ui/neon_option_button.gd")
const BG_TUTORIAL_TEXTURE: Texture2D = preload("res://sprite/maps/map_tutorial_dream_entrance.png")
const BG_COMBAT_TEXTURE: Texture2D = preload("res://sprite/maps/map_stage_combat_default.png")
const BG_BOSS_TEXTURE: Texture2D = preload("res://sprite/maps/map_stage_boss_arena.png")
const MELEE_ARC_EFFECT_SCRIPT: Script = preload("res://scripts/effects/melee_arc_effect.gd")
const ShopSystemScript: Script = preload("res://scripts/systems/shop_system.gd")
const WEAPON_ORBIT_ICON_DIR: String = "res://sprite/weapons/generated_from_doc_v1_alpha_final_v2/"
const WEAPON_ORBIT_ICON_TARGET_WIDTH: float = 22.0
const WEAPON_ORBIT_FORWARD_OFFSET: float = 29.0
const WEAPON_ORBIT_SLOT_SPACING: float = 10.0
const WEAPON_ORBIT_FLASH_DURATION: float = 0.11
const WEAPON_ORBIT_FLASH_SCALE_MAX: float = 1.12
const WEAPON_ORBIT_BASE_TINT: Color = Color(0.86, 0.95, 1.0, 0.9)
const WEAPON_ORBIT_FLASH_TINT: Color = Color(1.0, 1.0, 1.0, 1.0)
const WEAPON_TAG_ADDITIVE_EFFECT_TYPES: Dictionary = {
    "attack_damage_flat": true,
    "melee_damage_flat": true,
    "ranged_damage_flat": true,
    "global_attack_percent_flat": true,
    "target_range_flat": true,
    "move_speed_flat": true,
    "armor_flat": true,
    "dodge_chance_flat": true,
    "crit_chance_flat": true,
    "crit_multiplier_flat": true,
    "lifesteal_flat": true,
    "luck_flat": true,
    "harvest_flat": true,
}
const WEAPON_TAG_MULTIPLIER_EFFECT_TYPES: Dictionary = {
    "attack_speed_mult": true,
    "auto_attack_interval_mult": true,
    "xp_gain_mult": true,
}

var _player: Player
var _player_camera: Camera2D
var _current_player_id: String = "the_fool"
var _enemy_spawn_timer: float = 0.0
var _contact_damage_timer: float = 0.0
var _battle_elapsed: float = 0.0
var _next_elite_spawn_time: float = 60.0
var _elite_spawn_relief_timer: float = 0.0
var _elite_schedule_enabled: bool = false
var _elite_respawn_check_interval_runtime: float = 120.0
var _elite_max_alive_runtime: int = 1
var _elite_hp_override_runtime: int = 0
var _enemies: Array[Enemy] = []
var _projectiles: Array[Projectile] = []
var _enemy_projectiles: Array[EnemyProjectile] = []
var _pending_enemy_shots: Array[Dictionary] = []
var _experience_orbs: Array[ExperienceOrb] = []
var _active_elite: Enemy
var _is_game_over: bool = false
var _pause_opened: bool = false
var _reward_opened: bool = false
var _slot_panel: SaveSlotPanel
var _save_slot_panel_scene: PackedScene
var _settings_panel: Control
var _settings_scene_resource: PackedScene
var _level_reward_panel: PanelContainer
var _level_reward_title: Label
var _level_reward_buttons: Array[Button] = []
var _death_settlement_panel: PanelContainer
var _death_settlement_title: Label
var _death_settlement_subtitle: Label
var _death_settlement_value_labels: Dictionary = {}
var _death_retry_button: Button
var _death_menu_button: Button
var _level_reward_choices: Array[Dictionary] = []
var _owned_weapon_rewards: Dictionary = {}
var _reward_history_runtime: Array[String] = []
var _recent_categories_runtime: Array[String] = []
var _build_tags_runtime: Array[String] = []
var _reward_pity_state_runtime: Dictionary = {"no_output_streak": 0}
var _pending_level_up_rewards: int = 0
var _wave_end_reward_gate_active: bool = false
var _pending_wave_shop_snapshot: Dictionary = {}
var _current_level: int = 1
var _current_xp: int = 0
var _xp_to_next_level: int = 20
var _xp_required_multiplier_runtime: float = 1.0
var _stage_target_duration: float = 0.0
var _wave_elapsed: float = 0.0
var _wave_duration_runtime: float = 30.0
var _wave_progress_index: int = 0
var _stage_is_boss_stage: bool = false
var _stage_clear_triggered: bool = false
var _enemy_hp_multiplier: float = 1.0
var _enemy_hp_stage_multiplier: float = 1.0
var _enemy_move_speed_stage_multiplier: float = 1.0
var _enemy_damage_multiplier: float = 1.0
var _spawn_interval_multiplier: float = 1.0
var _xp_multiplier: float = 1.0
var _gold_multiplier: float = 1.0
var _run_kill_count: int = 0
var _arena_half_extents: Vector2 = Vector2(620.0, 340.0)
var _enemy_ranged_weight_runtime: float = ENEMY_RANGED_WEIGHT
var _enemy_barrage_weight_runtime: float = ENEMY_BARRAGE_WEIGHT
var _auto_attack_interval_multiplier_runtime: float = 1.0
var _weapon_cooldowns: Dictionary = {}
var _weapon_cooldown_signatures: Dictionary = {}
var _current_gold_runtime: int = 0
var _selected_starter_weapon_id_runtime: String = ""
var _shop_runtime_state: Dictionary = {
    "equipped_weapons": [],
    "inventory_overflow": [],
    "locked_shop_offers": [],
    "refresh_count": 0,
    "shop_locked": false,
    "owned_items": [],
}
var _stage_background_key: String = ""
var _weapon_orbit_root: Node2D
var _weapon_orbit_nodes: Dictionary = {}
var _weapon_orbit_signatures: Dictionary = {}
var _weapon_orbit_flash_timers: Dictionary = {}
var _weapon_orbit_angle: float = 0.0
var _weapon_orbit_aim_direction: Vector2 = Vector2.RIGHT
var _weapon_orbit_icon_cache: Dictionary = {}
var _weapon_orbit_placeholder_texture: Texture2D
var _pause_transition_tween: Tween
var _death_fx_layer: CanvasLayer
var _death_fx_overlay: ColorRect
var _death_fx_tween: Tween
var _shop_system_runtime: ShopSystem
var _weapon_tag_applied_effects: Array[Dictionary] = []

const INITIAL_ENEMY_COUNT: int = 10
const MAX_ENEMY_COUNT: int = 24
const ENEMY_SPAWN_INTERVAL: float = 1.2
const ENEMY_MIN_SPAWN_RADIUS: float = 380.0
const ENEMY_MAX_SPAWN_RADIUS: float = 620.0
const ENEMY_RANGED_WEIGHT: float = 0.25
const ENEMY_BARRAGE_WEIGHT: float = 0.08
const DEFAULT_ARENA_HALF_EXTENTS: Vector2 = Vector2(620.0, 340.0)
const SPAWN_POSITION_RETRY_COUNT: int = 18
const ELITE_FIRST_SPAWN_TIME: float = 60.0
const ELITE_RESPAWN_CHECK_INTERVAL: float = 120.0
const ELITE_SPAWN_RELIEF_DURATION: float = 8.0
const ELITE_SPAWN_RELIEF_MULTIPLIER: float = 1.2
const AUTO_ATTACK_INTERVAL: float = 0.35
const AUTO_ATTACK_BASE_DAMAGE: int = 12
const BULLET_SPEED: float = 540.0
const DEFAULT_WEAPON_ATTACK_PROFILES: Dictionary = {
    "arc_blade": {
        "mode": "melee_arc",
        "base_damage": 10,
        "interval": 0.38,
        "range": 95.0,
    },
    "storm_wand": {
        "mode": "ranged_homing",
        "base_damage": 9,
        "interval": 0.39,
        "range": 340.0,
        "projectile_speed": 560.0,
        "projectile_radius": 4.0,
    },
    "void_gun": {
        "mode": "ranged_heavy",
        "base_damage": 16,
        "interval": 0.68,
        "range": 420.0,
        "projectile_speed": 680.0,
        "projectile_radius": 6.0,
    },
}
const CONTACT_DAMAGE: int = 8
const CONTACT_DAMAGE_INTERVAL: float = 0.34
const XP_CURVE_LEVEL_OFFSET_DEFAULT: int = 3
const XP_CURVE_BASE_MULT_DEFAULT: float = 1.0
const XP_REQUIRED_MIN_DEFAULT: int = 1
const ATTACK_FLAT_TO_GLOBAL_ATTACK_PERCENT_DEFAULT: float = 3.0
const CRIT_MULTIPLIER_TO_CRIT_CHANCE_RATIO_DEFAULT: float = 0.12
const HARVEST_WAVE_GOLD_PER_POINT_DEFAULT: float = 0.8
const HARVEST_KILL_GOLD_CHANCE_PER_POINT_DEFAULT: float = 0.0008
const HARVEST_KILL_GOLD_MAX_CHANCE_DEFAULT: float = 0.35
const HARVEST_KILL_GOLD_AMOUNT_DEFAULT: int = 1
const LEVEL_UP_MAX_HP_BONUS_DEFAULT: int = 1
const LEVEL_UP_CURRENT_HP_BONUS_DEFAULT: int = 1
const REWARD_TARGET_RANGE_BONUS: float = 80.0
const REWARD_ATTACK_DAMAGE_BONUS: int = 3
const REWARD_MOVE_SPEED_BONUS: float = 15.0
const LEVEL_REWARD_CHOICES_COUNT: int = 3
const STAGE_TIMER_DANGER_SECONDS: int = 10
const STAGE_TIMER_BASE_SECONDS: float = 30.0
const STAGE_TIMER_GROWTH_SECONDS: float = 5.0
const STAGE_TIMER_MAX_SECONDS: float = 120.0
const PAUSE_OPEN_DURATION: float = 0.18
const PAUSE_CLOSE_DURATION: float = 0.13
const PAUSE_PANEL_POP_SCALE: float = 0.94
const DEATH_FLASH_DURATION: float = 0.12
const DEATH_FADE_DURATION: float = 0.46

func _resolve_state_label() -> Label:
    var direct_label: Label = get_node_or_null(^"HUD#StateLabel") as Label
    if direct_label != null:
        return direct_label
    return get_node_or_null(^"HUD/StateLabel") as Label

func _ready() -> void :
    process_mode = Node.PROCESS_MODE_ALWAYS
    EventBus.game_state_changed.connect(_on_game_state_changed)
    EventBus.player_died.connect(_on_player_died)
    AudioManager.play_combat_bgm()
    queue_redraw()
    var pending_slot_data: Dictionary = GameManager.consume_pending_slot_data()
    _refresh_difficulty_modifiers()
    _apply_arena_config_from_balance(GameManager.current_stage_id)
    _apply_enemy_mix_from_balance(GameManager.current_stage_id)
    _reset_progress_state()
    _spawn_player()
    _ensure_shop_system_runtime()
    if not pending_slot_data.is_empty():
        _apply_loaded_slot_data(pending_slot_data, false)
    _ensure_starter_weapon_equipped()
    _refresh_weapon_tag_state_runtime(true)
    _sync_weapon_orbit_visuals(true)
    _spawn_initial_enemies()
    wave_manager.start_stage()
    _sync_wave_runtime_from_manager()
    _apply_stage_runtime_from_balance(GameManager.current_stage_id)
    if state_label != null:
        state_label.visible = false
        state_label.modulate = Color(0.82, 0.96, 1.0, 0.95)
    else:
        push_warning("Stage timer label not found. Expected HUD#StateLabel or HUD/StateLabel.")
    _bind_pause_menu()
    _prepare_pause_sub_scenes()
    _create_pause_sub_panels()
    _set_pause_overlay_visible(false)
    _set_combat_simulation_active(true)

func _reset_progress_state() -> void :
    _current_level = 1
    _current_xp = 0
    _xp_required_multiplier_runtime = _resolve_character_xp_required_multiplier(_current_player_id)
    _xp_to_next_level = _xp_required_for_level(_current_level)
    _pending_level_up_rewards = 0
    _reward_opened = false
    _wave_end_reward_gate_active = false
    _pending_wave_shop_snapshot = {}
    _battle_elapsed = 0.0
    _run_kill_count = 0
    _wave_elapsed = 0.0
    _wave_duration_runtime = 30.0
    _wave_progress_index = 0
    _stage_clear_triggered = false
    _next_elite_spawn_time = ELITE_FIRST_SPAWN_TIME
    _elite_spawn_relief_timer = 0.0
    _elite_schedule_enabled = false
    _elite_respawn_check_interval_runtime = ELITE_RESPAWN_CHECK_INTERVAL
    _elite_max_alive_runtime = 1
    _elite_hp_override_runtime = 0
    _active_elite = null
    _owned_weapon_rewards = {}
    _reward_history_runtime = []
    _recent_categories_runtime = []
    _build_tags_runtime = []
    _reward_pity_state_runtime = {"no_output_streak": 0}
    _level_reward_choices = []
    _auto_attack_interval_multiplier_runtime = 1.0
    _weapon_cooldowns.clear()
    _weapon_cooldown_signatures.clear()
    _weapon_tag_applied_effects.clear()
    _clear_weapon_orbit_runtime()
    _current_gold_runtime = 0
    _selected_starter_weapon_id_runtime = GameManager.selected_starter_weapon_id
    _shop_runtime_state = {
        "equipped_weapons": [],
        "inventory_overflow": [],
        "locked_shop_offers": [],
        "refresh_count": 0,
        "shop_locked": false,
        "owned_items": [],
    }
    if hud != null and hud.has_method("hide_boss_bar"):
        hud.call("hide_boss_bar")

func _process(delta: float) -> void :
    if _is_game_over:
        return
    if _reward_opened:
        return
    if GameManager.current_state != GameManager.GameState.PLAYING:
        return
    _battle_elapsed += delta
    _wave_elapsed += delta
    _update_stage_timer(delta)
    if _stage_clear_triggered:
        return
    _enemy_spawn_timer += delta
    _contact_damage_timer = max(0.0, _contact_damage_timer - delta)
    _elite_spawn_relief_timer = max(0.0, _elite_spawn_relief_timer - delta)

    var spawn_interval: float = ENEMY_SPAWN_INTERVAL
    spawn_interval *= _spawn_interval_multiplier
    if _elite_spawn_relief_timer > 0.0:
        spawn_interval *= ELITE_SPAWN_RELIEF_MULTIPLIER

    if _enemy_spawn_timer >= spawn_interval:
        _enemy_spawn_timer = 0.0
        _try_spawn_enemy()

    _try_spawn_elite_by_schedule()
    _tick_equipped_weapon_attacks(delta)
    _tick_weapon_orbit_visuals(delta)
    _handle_projectile_hits()
    _flush_pending_enemy_shots()
    _handle_enemy_projectile_hits()
    _handle_enemy_contact_damage()
    _update_experience_orbs(delta)
    _cleanup_dead_projectiles()
    _cleanup_dead_enemy_projectiles()
    _cleanup_dead_experience_orbs()
    _update_elite_boss_bar()
    _constrain_actor_positions_to_arena()
    _refresh_player_hud()

func _unhandled_input(event: InputEvent) -> void :
    if not event.is_action_pressed("pause"):
        return
    if _is_game_over:
        return
    if _wave_end_reward_gate_active:
        if _pending_level_up_rewards > 0:
            if _level_reward_panel != null and not _level_reward_panel.visible:
                _show_level_reward_panel()
        return
    if _reward_opened:
        if _level_reward_panel != null and not _level_reward_panel.visible:
            _show_level_reward_panel()
        return
    if _pause_opened:
        if _is_pause_sub_panel_open():
            _hide_pause_sub_panels()
            return
        _resume_game_from_pause()
        return
    _open_pause_menu()

func _on_game_state_changed(_from: int, _to: int) -> void :
    pass

func _on_player_died() -> void :
    if _is_game_over:
        return
    _is_game_over = true
    _set_combat_simulation_active(false)
    _reward_opened = false
    _pending_level_up_rewards = 0
    _wave_end_reward_gate_active = false
    _pending_wave_shop_snapshot = {}
    get_tree().paused = false
    _pause_opened = false
    _set_pause_overlay_visible(false)
    if hud.has_method("set_player_stats"):
        hud.call(
            "set_player_stats", 
            0.0, 
            float(_player.max_hp), 
            _player.current_stamina, 
            _player.stamina_max, 
            float(_current_xp), 
            float(_xp_to_next_level), 
            _current_level,
            _current_gold_runtime
        )
    _clear_experience_orbs()
    _clear_enemy_projectiles()
    if hud != null and hud.has_method("set_stage_timer"):
        hud.call("set_stage_timer", false)
    if hud.has_method("hide_boss_bar"):
        hud.call("hide_boss_bar")
    await _play_player_death_transition()
    _show_death_settlement_panel()

func _play_player_death_transition() -> void:
    _ensure_death_overlay()
    if _death_fx_overlay == null:
        return
    _stop_death_fx_tween()

    _death_fx_overlay.visible = true
    _death_fx_overlay.color = Color(0.45, 0.07, 0.07, 0.0)

    _death_fx_tween = create_tween()
    _death_fx_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
    _death_fx_tween.set_trans(Tween.TRANS_QUAD)
    _death_fx_tween.set_ease(Tween.EASE_OUT)
    _death_fx_tween.tween_property(_death_fx_overlay, "color", Color(0.55, 0.08, 0.08, 0.38), DEATH_FLASH_DURATION)
    _death_fx_tween.set_ease(Tween.EASE_IN)
    _death_fx_tween.tween_property(_death_fx_overlay, "color", Color(0.0, 0.0, 0.0, 0.96), DEATH_FADE_DURATION)
    await _death_fx_tween.finished
    _death_fx_tween = null

func _ensure_death_overlay() -> void:
    if _death_fx_layer != null and is_instance_valid(_death_fx_layer):
        return

    _death_fx_layer = CanvasLayer.new()
    _death_fx_layer.layer = 190
    _death_fx_layer.process_mode = Node.PROCESS_MODE_ALWAYS
    add_child(_death_fx_layer)

    _death_fx_overlay = ColorRect.new()
    _death_fx_overlay.name = "DeathFxOverlay"
    _death_fx_overlay.anchors_preset = Control.PRESET_FULL_RECT
    _death_fx_overlay.anchor_right = 1.0
    _death_fx_overlay.anchor_bottom = 1.0
    _death_fx_overlay.grow_horizontal = Control.GROW_DIRECTION_BOTH
    _death_fx_overlay.grow_vertical = Control.GROW_DIRECTION_BOTH
    _death_fx_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _death_fx_overlay.visible = false
    _death_fx_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
    _death_fx_layer.add_child(_death_fx_overlay)

func _stop_death_fx_tween() -> void:
    if _death_fx_tween != null and is_instance_valid(_death_fx_tween):
        _death_fx_tween.kill()
    _death_fx_tween = null

func _show_death_settlement_panel() -> void:
    if _death_settlement_panel == null:
        return

    _pause_opened = true
    _reward_opened = false
    _set_pause_overlay_visible(true)
    _set_crt_effects_enabled(true)

    if _death_fx_overlay != null:
        _death_fx_overlay.visible = false
        _death_fx_overlay.color = Color(0.0, 0.0, 0.0, 0.0)

    pause_panel.visible = false
    if _slot_panel != null:
        _slot_panel.visible = false
    if _settings_panel != null:
        _settings_panel.visible = false
    if _level_reward_panel != null:
        _level_reward_panel.visible = false
    _death_settlement_panel.visible = true

    var stage_text: String = GameManager.current_stage_id
    var wave_text: String = _tf("ui.common.wave_fmt", [max(1, int(wave_manager.current_wave))], "WAVE %d")
    var survive_text: String = _format_elapsed_time(_battle_elapsed)
    if _death_settlement_title != null:
        _death_settlement_title.text = _tx("ui.game_over.defeat_title", "Defeat")
    if _death_settlement_subtitle != null:
        _death_settlement_subtitle.text = _tx("ui.game_scene.death_subtitle", "Signal interrupted, battle report generated.")
    _set_death_settlement_value("stage", stage_text)
    _set_death_settlement_value("wave", wave_text)
    _set_death_settlement_value("survival", survive_text)
    _set_death_settlement_value("level", _tf("ui.common.level_fmt", [_current_level], "Lv.%d"))
    _set_death_settlement_value("gold", str(_current_gold_runtime))
    _set_death_settlement_value("kills", str(_run_kill_count))

    get_tree().paused = true
    GameManager.change_state(GameManager.GameState.GAME_OVER)
    EventBus.game_over.emit(false)

func _set_combat_simulation_active(active: bool) -> void:
    if _player != null and is_instance_valid(_player):
        _player.set_process(active)
        _player.set_physics_process(active)
    for enemy: Enemy in _enemies:
        if enemy == null or not is_instance_valid(enemy):
            continue
        enemy.set_process(active)
        enemy.set_physics_process(active)
    for projectile: Projectile in _projectiles:
        if projectile == null or not is_instance_valid(projectile):
            continue
        projectile.set_process(active)
        projectile.set_physics_process(active)
    for projectile: EnemyProjectile in _enemy_projectiles:
        if projectile == null or not is_instance_valid(projectile):
            continue
        projectile.set_process(active)
        projectile.set_physics_process(active)
    for orb: ExperienceOrb in _experience_orbs:
        if orb == null or not is_instance_valid(orb):
            continue
        orb.set_process(active)
        orb.set_physics_process(active)

func _format_elapsed_time(seconds_raw: float) -> String:
    var total_seconds: int = max(0, int(floor(seconds_raw)))
    var minutes: int = total_seconds / 60
    var seconds: int = total_seconds % 60
    return "%02d:%02d" % [minutes, seconds]

func _update_stage_timer(_delta: float) -> void:
    if hud == null or not hud.has_method("set_stage_timer"):
        return
    if _stage_is_boss_stage or _wave_duration_runtime <= 0.0:
        hud.call("set_stage_timer", false)
        return
    var remain: float = max(0.0, _wave_duration_runtime - _wave_elapsed)
    var timer_tint: Color = _update_stage_timer_color(remain)
    hud.call("set_stage_timer", true, _format_stage_countdown(remain), timer_tint)
    if remain <= 0.0:
        _on_wave_time_up()

func _format_stage_countdown(remain: float) -> String:
    var seconds_total: int = max(0, int(ceil(remain)))
    var minutes: int = seconds_total / 60
    var seconds: int = seconds_total % 60
    return "%02d:%02d" % [minutes, seconds]

func _update_stage_timer_color(remain: float) -> Color:
    if remain > float(STAGE_TIMER_DANGER_SECONDS):
        return Color(0.82, 0.96, 1.0, 0.95)
    var pulse_t: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.014)
    var safe_color: Color = Color(0.86, 0.96, 1.0, 0.95)
    var danger_color: Color = Color(1.0, 0.42, 0.38, 1.0)
    return safe_color.lerp(danger_color, pulse_t)

func _on_wave_time_up() -> void:
    if _stage_clear_triggered or _is_game_over:
        return
    _stage_clear_triggered = true
    _pause_opened = false
    _reward_opened = false
    _wave_end_reward_gate_active = false
    _pending_wave_shop_snapshot = {}
    get_tree().paused = false
    _set_pause_overlay_visible(false)
    _clear_enemy_projectiles()
    _clear_experience_orbs()
    _clear_all_enemies()
    var current_wave_profile: Dictionary = wave_manager.get_current_wave_definition()
    _add_gold(int(current_wave_profile.get("reward_gold", 0)))
    _add_gold(_resolve_wave_harvest_gold())
    _add_experience(int(current_wave_profile.get("reward_xp", 0)))
    var next_stage_id: String = _resolve_next_stage_id(GameManager.current_stage_id)
    if next_stage_id.is_empty():
        _stage_clear_triggered = false
        _complete_stage_by_timer()
        return
    var shop_snapshot: Dictionary = _build_wave_runtime_snapshot()
    shop_snapshot["stage_id"] = next_stage_id
    shop_snapshot["wave"] = 1
    shop_snapshot["wave_progress_index"] = 0
    _begin_wave_end_reward_then_shop(shop_snapshot)

func _begin_wave_end_reward_then_shop(shop_snapshot: Dictionary) -> void:
    _wave_end_reward_gate_active = true
    _pending_wave_shop_snapshot = shop_snapshot.duplicate(true)
    if _pending_level_up_rewards > 0:
        _try_open_next_level_reward()
        if _reward_opened:
            return
    _open_shop_after_wave_reward()

func _open_shop_after_wave_reward() -> void:
    if not _wave_end_reward_gate_active:
        return
    if _pending_level_up_rewards > 0 or _reward_opened:
        return
    var pending_snapshot: Dictionary = _pending_wave_shop_snapshot.duplicate(true)
    _wave_end_reward_gate_active = false
    _pending_wave_shop_snapshot = {}
    if pending_snapshot.is_empty():
        return
    # Rebuild from current runtime after reward selection so shop/next stage inherits latest stats.
    var shop_snapshot: Dictionary = _build_wave_runtime_snapshot()
    shop_snapshot["stage_id"] = str(pending_snapshot.get("stage_id", shop_snapshot.get("stage_id", GameManager.current_stage_id)))
    shop_snapshot["wave"] = max(1, int(pending_snapshot.get("wave", 1)))
    shop_snapshot["wave_progress_index"] = max(0, int(pending_snapshot.get("wave_progress_index", 0)))
    GameManager.open_wave_shop(shop_snapshot)

func _complete_stage_by_timer() -> void:
    if _is_game_over:
        return
    _stage_clear_triggered = true
    _pause_opened = false
    _reward_opened = false
    _pending_level_up_rewards = 0
    _wave_end_reward_gate_active = false
    _pending_wave_shop_snapshot = {}
    get_tree().paused = false
    _set_pause_overlay_visible(false)
    _clear_enemy_projectiles()
    if hud != null and hud.has_method("set_stage_timer"):
        hud.call("set_stage_timer", false)
    EventBus.stage_cleared.emit(GameManager.current_stage_id)
    var next_stage_id: String = _resolve_next_stage_id(GameManager.current_stage_id)
    if next_stage_id.is_empty():
        GameManager.end_game(true)
        return
    GameManager.start_game_with_runtime(next_stage_id, _build_stage_transition_payload(next_stage_id))

func _build_stage_transition_payload(next_stage_id: String) -> Dictionary:
    var payload: Dictionary = _build_runtime_save_payload()
    payload["stage_id"] = next_stage_id
    payload["wave"] = 1
    payload["wave_progress_index"] = 0
    var next_shop_state: Dictionary = _normalize_shop_runtime_state(payload.get("shop_runtime_state", {}))
    next_shop_state["shop_locked"] = false
    payload["shop_runtime_state"] = next_shop_state
    return payload

func _spawn_player(force_character_id: String = "") -> void :
    var selected_id: String = force_character_id if not force_character_id.is_empty() else GameManager.selected_character
    if selected_id.is_empty():
        selected_id = "the_fool"
    GameManager.selected_character = selected_id
    _current_player_id = selected_id
    _xp_required_multiplier_runtime = _resolve_character_xp_required_multiplier(_current_player_id)
    _xp_to_next_level = _xp_required_for_level(_current_level)

    var script_resource: Script = PLAYER_SCRIPT_MAP["the_fool"]
    if PLAYER_SCRIPT_MAP.has(selected_id):
        script_resource = PLAYER_SCRIPT_MAP[selected_id]

    _clear_weapon_orbit_runtime()
    if _player != null and is_instance_valid(_player):
        _player.queue_free()

    _player = script_resource.new()
    _player.global_position = Vector2.ZERO
    add_child(_player)
    _ensure_weapon_orbit_root()

    var camera: Camera2D = Camera2D.new()
    camera.enabled = true
    camera.position_smoothing_enabled = true
    camera.position_smoothing_speed = 8.0
    camera.limit_enabled = true
    _player.add_child(camera)
    _player_camera = camera
    _update_camera_limits()

    for enemy: Enemy in _enemies:
        if enemy != null and is_instance_valid(enemy):
            enemy.set_target(_player)

    _refresh_player_hud()

func _spawn_initial_enemies() -> void :
    for i: int in range(INITIAL_ENEMY_COUNT):
        _try_spawn_enemy()

func _is_enemy_combat_active(enemy: Variant) -> bool:
    if enemy == null:
        return false
    if not (enemy is Object):
        return false
    var enemy_object: Object = enemy
    if not is_instance_valid(enemy_object):
        return false
    if enemy_object.has_method("is_combat_active"):
        return bool(enemy_object.call("is_combat_active"))
    return true

func _count_active_enemies() -> int:
    var total: int = 0
    for enemy: Enemy in _enemies:
        if _is_enemy_combat_active(enemy):
            total += 1
    return total

func _try_spawn_enemy() -> void :
    if _player == null or not is_instance_valid(_player):
        return
    _cleanup_dead_enemies()
    if _count_active_enemies() >= MAX_ENEMY_COUNT:
        return
    var spawn_roll: float = randf()
    var spawn_type: Enemy.EnemyType = Enemy.EnemyType.MELEE
    if spawn_roll < _enemy_barrage_weight_runtime:
        spawn_type = Enemy.EnemyType.BARRAGE
    elif spawn_roll < _enemy_barrage_weight_runtime + _enemy_ranged_weight_runtime:
        spawn_type = Enemy.EnemyType.RANGED
    _spawn_enemy(spawn_type, _random_spawn_position())

func _spawn_enemy(spawn_type: Enemy.EnemyType, spawn_position: Vector2) -> Enemy:
    var enemy: Enemy = null
    match spawn_type:
        Enemy.EnemyType.RANGED:
            enemy = RangedEnemy.new()
        Enemy.EnemyType.BARRAGE:
            enemy = BarrageEnemy.new()
        Enemy.EnemyType.ELITE_WARDEN:
            enemy = EliteStaticWarden.new()
        _:
            enemy = Enemy.new()

    enemy.global_position = _clamp_position_to_arena(spawn_position, enemy.body_radius)
    enemy.set_target(_player)
    enemy.died.connect(_on_enemy_died)
    enemy.enemy_projectile_fired.connect(_on_enemy_projectile_fired)
    add_child(enemy)
    var hp_scale: float = max(0.1, _enemy_hp_multiplier * _enemy_hp_stage_multiplier)
    var scaled_max_hp: int = max(1, int(round(float(enemy.max_hp) * hp_scale)))
    enemy.max_hp = scaled_max_hp
    enemy.current_hp = scaled_max_hp
    enemy.move_speed = max(10.0, enemy.move_speed * max(0.1, _enemy_move_speed_stage_multiplier))
    enemy.queue_redraw()
    _enemies.append(enemy)
    return enemy

func _try_spawn_elite_by_schedule() -> void :
    if not _elite_schedule_enabled:
        return
    if _battle_elapsed < _next_elite_spawn_time:
        return
    _next_elite_spawn_time += _elite_respawn_check_interval_runtime
    if _count_alive_elites() >= _elite_max_alive_runtime:
        return
    _spawn_elite()

func _has_alive_elite() -> bool:
    if _is_enemy_combat_active(_active_elite):
        return true
    for enemy: Enemy in _enemies:
        if not _is_enemy_combat_active(enemy):
            continue
        if enemy.is_elite:
            _active_elite = enemy
            return true
    _active_elite = null
    return false

func _count_alive_elites() -> int:
    var count: int = 0
    if _is_enemy_combat_active(_active_elite):
        count += 1
    for enemy: Enemy in _enemies:
        if enemy == _active_elite:
            continue
        if not _is_enemy_combat_active(enemy):
            continue
        if enemy.is_elite:
            count += 1
    if count <= 0:
        _active_elite = null
    return count

func _spawn_elite() -> void :
    if _player == null or not is_instance_valid(_player):
        return
    var elite_spawn: Vector2 = _random_spawn_position()
    var enemy: Enemy = _spawn_enemy(Enemy.EnemyType.ELITE_WARDEN, elite_spawn)
    if _elite_hp_override_runtime > 0:
        enemy.max_hp = _elite_hp_override_runtime
        enemy.current_hp = enemy.max_hp
        enemy.queue_redraw()
    _active_elite = enemy
    _elite_spawn_relief_timer = ELITE_SPAWN_RELIEF_DURATION
    print("[Elite] Spawned %s at %.2fs" % [enemy.get_display_name(), _battle_elapsed])
    if hud.has_method("show_boss_bar"):
        hud.call("show_boss_bar", enemy.get_display_name(), float(enemy.max_hp), float(enemy.current_hp))

func _random_spawn_position() -> Vector2:
    var arena_rect: Rect2 = _arena_rect()
    var fallback: Vector2 = Vector2(
        randf_range(arena_rect.position.x, arena_rect.end.x),
        randf_range(arena_rect.position.y, arena_rect.end.y)
    )
    if _player == null or not is_instance_valid(_player):
        return fallback

    # Prefer radial spawn around player, but keep it inside arena bounds.
    for i: int in range(SPAWN_POSITION_RETRY_COUNT):
        var direction: Vector2 = Vector2.RIGHT.rotated(randf() * TAU)
        var distance: float = randf_range(ENEMY_MIN_SPAWN_RADIUS, ENEMY_MAX_SPAWN_RADIUS)
        var candidate: Vector2 = _player.global_position + direction * distance
        if not arena_rect.has_point(candidate):
            continue
        return candidate

    # Near map borders, radial spawn may fail repeatedly; fallback to in-bounds
    # random spawn and keep a reasonable distance from player.
    for i: int in range(SPAWN_POSITION_RETRY_COUNT):
        var candidate: Vector2 = Vector2(
            randf_range(arena_rect.position.x, arena_rect.end.x),
            randf_range(arena_rect.position.y, arena_rect.end.y)
        )
        if candidate.distance_to(_player.global_position) >= ENEMY_MIN_SPAWN_RADIUS * 0.65:
            return candidate
    return fallback

func _arena_rect() -> Rect2:
    return Rect2(-_arena_half_extents, _arena_half_extents * 2.0)

func _clamp_position_to_arena(world_pos: Vector2, body_radius: float) -> Vector2:
    var margin: float = max(0.0, body_radius)
    var min_x: float = -_arena_half_extents.x + margin
    var max_x: float = _arena_half_extents.x - margin
    var min_y: float = -_arena_half_extents.y + margin
    var max_y: float = _arena_half_extents.y - margin
    return Vector2(
        clampf(world_pos.x, min_x, max_x),
        clampf(world_pos.y, min_y, max_y)
    )

func _constrain_actor_positions_to_arena() -> void:
    # Runtime hard clamp: neither player nor enemies can leave map bounds.
    if _player != null and is_instance_valid(_player):
        _player.global_position = _clamp_position_to_arena(_player.global_position, _player.body_radius)

    for enemy: Enemy in _enemies:
        if enemy == null or not is_instance_valid(enemy):
            continue
        enemy.global_position = _clamp_position_to_arena(enemy.global_position, enemy.body_radius)

func _tick_equipped_weapon_attacks(delta: float) -> void:
    if _player == null or not is_instance_valid(_player):
        return
    _sync_weapon_cooldowns_with_equipped_slots()
    var equipped_slots: Array = _normalize_equipped_weapon_slots(_shop_runtime_state.get("equipped_weapons", []))
    var player_speed_mult: float = 1.0
    if _player != null and is_instance_valid(_player):
        player_speed_mult = _player.get_attack_speed_multiplier()
    var safe_speed_mult: float = max(0.01, player_speed_mult)

    for slot_index: int in range(equipped_slots.size()):
        var slot_weapon_value: Variant = equipped_slots[slot_index]
        if not _is_valid_weapon_slot(slot_weapon_value):
            continue
        var slot_weapon: Dictionary = slot_weapon_value
        var attack_profile: Dictionary = _resolve_attack_profile(slot_weapon)
        var base_interval: float = max(0.08, float(attack_profile.get("interval", AUTO_ATTACK_INTERVAL)))
        var effective_interval: float = clampf(
            base_interval * _auto_attack_interval_multiplier_runtime / safe_speed_mult,
            0.08,
            1.2
        )
        var cooldown_remaining: float = max(0.0, float(_weapon_cooldowns.get(slot_index, 0.0)) - delta)
        if cooldown_remaining > 0.0:
            _weapon_cooldowns[slot_index] = cooldown_remaining
            continue

        var target_range: float = _resolve_weapon_attack_range(attack_profile)
        var nearest_enemy: Enemy = _find_nearest_enemy_in_range(target_range)
        if nearest_enemy == null:
            _weapon_cooldowns[slot_index] = 0.0
            continue
        _attack_with_profile(nearest_enemy, attack_profile)
        _trigger_weapon_orbit_flash(slot_index)
        _weapon_cooldowns[slot_index] = effective_interval

func _attack_with_profile(target_enemy: Enemy, attack_profile: Dictionary) -> void:
    if target_enemy == null or not is_instance_valid(target_enemy):
        return
    var mode: String = str(attack_profile.get("mode", "ranged_homing"))
    match mode:
        "melee_arc":
            _perform_melee_arc_attack(target_enemy, attack_profile)
        "ranged_heavy":
            _spawn_weapon_projectile(target_enemy, attack_profile, false)
        _:
            _spawn_weapon_projectile(target_enemy, attack_profile, true)

func _find_nearest_enemy_in_range(max_distance: float) -> Enemy:
    if _player == null:
        return null
    var best_enemy: Enemy = null
    var best_dist_sq: float = max_distance * max_distance
    for enemy: Enemy in _enemies:
        if not _is_enemy_combat_active(enemy):
            continue
        var dist_sq: float = _player.global_position.distance_squared_to(enemy.global_position)
        if dist_sq < best_dist_sq:
            best_dist_sq = dist_sq
            best_enemy = enemy
    return best_enemy

func _spawn_weapon_projectile(target_enemy: Enemy, attack_profile: Dictionary, homing: bool) -> void:
    if target_enemy == null or not is_instance_valid(target_enemy):
        return
    var projectile: Projectile = Projectile.new()
    projectile.damage = _resolve_weapon_damage(attack_profile)
    projectile.speed = max(180.0, float(attack_profile.get("projectile_speed", BULLET_SPEED)))
    projectile.hit_radius = max(2.0, float(attack_profile.get("projectile_radius", 4.0)))
    projectile.crit_chance = _player.crit_chance
    projectile.crit_multiplier = _resolve_weapon_crit_multiplier(attack_profile)
    projectile.lifesteal_chance = _resolve_weapon_lifesteal_chance(attack_profile)
    projectile.owner_player = _player
    projectile.global_position = _player.global_position
    projectile.direction = (_player.global_position.direction_to(target_enemy.global_position)).normalized()
    if homing:
        projectile.set_target(target_enemy)
    add_child(projectile)
    _projectiles.append(projectile)

func _perform_melee_arc_attack(target_enemy: Enemy, attack_profile: Dictionary) -> void:
    if not _is_enemy_combat_active(target_enemy):
        return
    var impact_position: Vector2 = target_enemy.global_position
    _spawn_melee_arc_effect(impact_position, attack_profile)
    var base_damage: int = _resolve_weapon_damage(attack_profile)
    var crit_multiplier: float = _resolve_weapon_crit_multiplier(attack_profile)
    var lifesteal_chance: float = _resolve_weapon_lifesteal_chance(attack_profile)
    var splash_radius: float = _resolve_melee_splash_radius(attack_profile)
    for enemy: Enemy in _enemies:
        if not _is_enemy_combat_active(enemy):
            continue
        var hit_distance: float = splash_radius + enemy.body_radius
        if impact_position.distance_squared_to(enemy.global_position) > hit_distance * hit_distance:
            continue
        var outgoing_damage: int = _player.roll_outgoing_damage(base_damage, _player.crit_chance, crit_multiplier)
        var dealt_damage: int = enemy.take_damage(outgoing_damage)
        if dealt_damage > 0:
            _player.try_lifesteal_on_hit(lifesteal_chance)
    _cleanup_dead_enemies()

func _resolve_weapon_damage(attack_profile: Dictionary) -> int:
    if _player == null or not is_instance_valid(_player):
        return max(1, int(attack_profile.get("base_damage", AUTO_ATTACK_BASE_DAMAGE)))
    var base_damage: int = int(attack_profile.get("base_damage", AUTO_ATTACK_BASE_DAMAGE))
    var mode: String = str(attack_profile.get("mode", "ranged_homing"))
    var mode_bonus: int = _resolve_mode_damage_bonus(mode)
    var damage_before_global: int = max(1, base_damage + mode_bonus)
    var global_mult: float = max(0.1, 1.0 + _player.get_global_attack_percent() / 100.0)
    return max(1, int(round(float(damage_before_global) * global_mult)))

func _resolve_weapon_crit_multiplier(attack_profile: Dictionary) -> float:
    return max(1.0, float(attack_profile.get("crit_multiplier", 1.5)))

func _resolve_weapon_lifesteal_chance(attack_profile: Dictionary) -> float:
    if _player == null or not is_instance_valid(_player):
        return 0.0
    var weapon_lifesteal: float = float(attack_profile.get("lifesteal", attack_profile.get("lifesteal_chance", 0.0)))
    return clampf(_player.lifesteal + weapon_lifesteal, 0.0, 1.0)

func _resolve_mode_damage_bonus(mode: String) -> int:
    if _player == null or not is_instance_valid(_player):
        return 0
    match mode:
        "melee_arc":
            return _player.get_melee_attack_damage_bonus()
        "ranged_homing", "ranged_heavy":
            return _player.get_ranged_attack_damage_bonus()
        _:
            return 0

func _resolve_weapon_attack_range(attack_profile: Dictionary) -> float:
    var mode: String = str(attack_profile.get("mode", "ranged_homing"))
    var profile_range: float = float(attack_profile.get("range", _player.get_current_target_range()))
    var range_bonus_ratio: float = 1.0
    if mode == "melee_arc":
        range_bonus_ratio = 0.5
    var final_range: float = profile_range + _player.bonus_target_range * range_bonus_ratio
    return max(1.0, final_range)

func _resolve_melee_splash_radius(attack_profile: Dictionary) -> float:
    var melee_range: float = clampf(float(attack_profile.get("range", 95.0)), 55.0, 130.0)
    var default_radius: float = melee_range * 0.58
    var raw_radius: float = float(attack_profile.get("splash_radius", default_radius))
    return clampf(raw_radius, 48.0, 110.0)

func _normalize_equipped_weapon_slots(raw_slots: Variant) -> Array:
    var slots: Array = []
    if raw_slots is Array:
        var raw_array: Array = raw_slots
        for i: int in range(min(raw_array.size(), 6)):
            var item: Variant = raw_array[i]
            slots.append(item.duplicate(true) if item is Dictionary else {})
    while slots.size() < 6:
        slots.append({})
    return slots

func _is_valid_weapon_slot(slot_value: Variant) -> bool:
    return slot_value is Dictionary and not str((slot_value as Dictionary).get("weapon_id", "")).is_empty()

func _build_weapon_cooldown_signature(weapon: Dictionary) -> String:
    return "%s|%s|%s" % [
        str(weapon.get("weapon_id", "")),
        str(weapon.get("rarity", "common")),
        str(weapon.get("level", 1)),
    ]

func _sync_weapon_cooldowns_with_equipped_slots() -> void:
    var equipped_slots: Array = _normalize_equipped_weapon_slots(_shop_runtime_state.get("equipped_weapons", []))
    var synced_cooldowns: Dictionary = {}
    var synced_signatures: Dictionary = {}
    for slot_index: int in range(equipped_slots.size()):
        var slot_value: Variant = equipped_slots[slot_index]
        if not _is_valid_weapon_slot(slot_value):
            continue
        var weapon: Dictionary = slot_value
        var signature: String = _build_weapon_cooldown_signature(weapon)
        synced_signatures[slot_index] = signature
        if str(_weapon_cooldown_signatures.get(slot_index, "")) == signature:
            synced_cooldowns[slot_index] = max(0.0, float(_weapon_cooldowns.get(slot_index, 0.0)))
        else:
            synced_cooldowns[slot_index] = 0.0
    _weapon_cooldowns = synced_cooldowns
    _weapon_cooldown_signatures = synced_signatures

func _tick_weapon_orbit_visuals(delta: float) -> void:
    if _player == null or not is_instance_valid(_player):
        return
    _sync_weapon_orbit_visuals()
    if _weapon_orbit_nodes.is_empty():
        return
    var active_slots: Array[int] = []
    for key in _weapon_orbit_nodes.keys():
        active_slots.append(int(key))
    active_slots.sort()
    if active_slots.is_empty():
        return

    var aim_direction: Vector2 = _resolve_weapon_orbit_aim_direction()
    var side_direction: Vector2 = aim_direction.orthogonal().normalized()
    var middle_index: float = (float(active_slots.size()) - 1.0) * 0.5
    for i: int in range(active_slots.size()):
        var slot_index: int = active_slots[i]
        var sprite_value: Variant = _weapon_orbit_nodes.get(slot_index, null)
        if not (sprite_value is Sprite2D):
            continue
        var sprite: Sprite2D = sprite_value
        if not is_instance_valid(sprite):
            continue
        var slot_offset: float = (float(i) - middle_index) * WEAPON_ORBIT_SLOT_SPACING
        sprite.position = aim_direction * WEAPON_ORBIT_FORWARD_OFFSET + side_direction * slot_offset
        sprite.rotation = aim_direction.angle() + PI * 0.5

        var flash_left: float = max(0.0, float(_weapon_orbit_flash_timers.get(slot_index, 0.0)) - delta)
        if flash_left <= 0.0:
            _weapon_orbit_flash_timers.erase(slot_index)
            sprite.scale = _resolve_weapon_orbit_base_scale(sprite)
            sprite.modulate = WEAPON_ORBIT_BASE_TINT
            continue
        _weapon_orbit_flash_timers[slot_index] = flash_left
        var flash_t: float = clampf(flash_left / WEAPON_ORBIT_FLASH_DURATION, 0.0, 1.0)
        var flash_scale: float = lerpf(1.0, WEAPON_ORBIT_FLASH_SCALE_MAX, flash_t)
        sprite.scale = _resolve_weapon_orbit_base_scale(sprite) * flash_scale
        sprite.modulate = WEAPON_ORBIT_BASE_TINT.lerp(WEAPON_ORBIT_FLASH_TINT, flash_t)

func _resolve_weapon_orbit_aim_direction() -> Vector2:
    if _player == null or not is_instance_valid(_player):
        return _weapon_orbit_aim_direction
    var nearest_enemy: Enemy = _find_nearest_enemy_any_distance()
    if nearest_enemy != null:
        var enemy_direction: Vector2 = _player.global_position.direction_to(nearest_enemy.global_position)
        if enemy_direction.length_squared() > 0.0001:
            _weapon_orbit_aim_direction = enemy_direction.normalized()
            return _weapon_orbit_aim_direction
    if _player.velocity.length_squared() > 0.0001:
        _weapon_orbit_aim_direction = _player.velocity.normalized()
    return _weapon_orbit_aim_direction

func _find_nearest_enemy_any_distance() -> Enemy:
    if _player == null:
        return null
    var best_enemy: Enemy = null
    var best_dist_sq: float = INF
    for enemy: Enemy in _enemies:
        if not _is_enemy_combat_active(enemy):
            continue
        var dist_sq: float = _player.global_position.distance_squared_to(enemy.global_position)
        if dist_sq < best_dist_sq:
            best_dist_sq = dist_sq
            best_enemy = enemy
    return best_enemy

func _sync_weapon_orbit_visuals(force_rebuild: bool = false) -> void:
    if _player == null or not is_instance_valid(_player):
        return
    _ensure_weapon_orbit_root()
    var equipped_slots: Array = _normalize_equipped_weapon_slots(_shop_runtime_state.get("equipped_weapons", []))
    var next_signatures: Dictionary = {}
    for slot_index: int in range(equipped_slots.size()):
        var slot_value: Variant = equipped_slots[slot_index]
        if not _is_valid_weapon_slot(slot_value):
            continue
        var weapon: Dictionary = slot_value
        var signature: String = _build_weapon_cooldown_signature(weapon)
        next_signatures[slot_index] = signature
        var has_sprite: bool = _weapon_orbit_nodes.has(slot_index)
        var sprite_valid: bool = false
        if has_sprite:
            var sprite_value: Variant = _weapon_orbit_nodes.get(slot_index, null)
            sprite_valid = sprite_value is Sprite2D and is_instance_valid(sprite_value as Sprite2D)
        var signature_same: bool = str(_weapon_orbit_signatures.get(slot_index, "")) == signature
        if force_rebuild or not has_sprite or not sprite_valid or not signature_same:
            _rebuild_weapon_orbit_slot_sprite(slot_index, weapon)

    var existing_slots: Array = _weapon_orbit_nodes.keys().duplicate()
    for key in existing_slots:
        var slot_index: int = int(key)
        if not next_signatures.has(slot_index):
            _remove_weapon_orbit_slot(slot_index)
    _weapon_orbit_signatures = next_signatures

func _ensure_weapon_orbit_root() -> void:
    if _player == null or not is_instance_valid(_player):
        return
    if _weapon_orbit_root != null and is_instance_valid(_weapon_orbit_root):
        if _weapon_orbit_root.get_parent() == _player:
            return
        _weapon_orbit_root.queue_free()
    _weapon_orbit_root = Node2D.new()
    _weapon_orbit_root.name = "WeaponOrbitRoot"
    _weapon_orbit_root.z_index = 16
    _player.add_child(_weapon_orbit_root)

func _clear_weapon_orbit_runtime() -> void:
    var existing_slots: Array = _weapon_orbit_nodes.keys().duplicate()
    for key in existing_slots:
        _remove_weapon_orbit_slot(int(key))
    _weapon_orbit_nodes.clear()
    _weapon_orbit_signatures.clear()
    _weapon_orbit_flash_timers.clear()
    _weapon_orbit_angle = 0.0
    if _weapon_orbit_root != null and is_instance_valid(_weapon_orbit_root):
        _weapon_orbit_root.queue_free()
    _weapon_orbit_root = null

func _rebuild_weapon_orbit_slot_sprite(slot_index: int, weapon: Dictionary) -> void:
    _remove_weapon_orbit_slot(slot_index)
    if _weapon_orbit_root == null or not is_instance_valid(_weapon_orbit_root):
        return
    var weapon_id: String = str(weapon.get("weapon_id", ""))
    var texture: Texture2D = _get_weapon_orbit_texture(weapon_id)
    if texture == null:
        texture = _get_weapon_orbit_placeholder_texture()
    var sprite: Sprite2D = Sprite2D.new()
    sprite.texture = texture
    sprite.centered = true
    sprite.z_index = 2
    sprite.modulate = WEAPON_ORBIT_BASE_TINT
    var base_scale: Vector2 = _compute_weapon_orbit_base_scale(texture)
    sprite.scale = base_scale
    sprite.set_meta("base_scale", base_scale)
    _weapon_orbit_root.add_child(sprite)
    _weapon_orbit_nodes[slot_index] = sprite

func _remove_weapon_orbit_slot(slot_index: int) -> void:
    var sprite_value: Variant = _weapon_orbit_nodes.get(slot_index, null)
    if sprite_value is Sprite2D:
        var sprite: Sprite2D = sprite_value
        if is_instance_valid(sprite):
            sprite.queue_free()
    _weapon_orbit_nodes.erase(slot_index)
    _weapon_orbit_signatures.erase(slot_index)
    _weapon_orbit_flash_timers.erase(slot_index)

func _get_weapon_orbit_texture(weapon_id: String) -> Texture2D:
    if weapon_id.is_empty():
        return null
    if _weapon_orbit_icon_cache.has(weapon_id):
        return _weapon_orbit_icon_cache[weapon_id] as Texture2D
    var icon_path: String = "%s%s.png" % [WEAPON_ORBIT_ICON_DIR, weapon_id]
    if not ResourceLoader.exists(icon_path):
        _weapon_orbit_icon_cache[weapon_id] = null
        return null
    var icon: Texture2D = load(icon_path) as Texture2D
    _weapon_orbit_icon_cache[weapon_id] = icon
    return icon

func _get_weapon_orbit_placeholder_texture() -> Texture2D:
    if _weapon_orbit_placeholder_texture != null:
        return _weapon_orbit_placeholder_texture
    var size: int = 24
    var image: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
    image.fill(Color(0.0, 0.0, 0.0, 0.0))
    var center: Vector2 = Vector2(float(size) * 0.5, float(size) * 0.5)
    var inner_radius: float = 4.0
    var outer_radius: float = 10.0
    for y: int in range(size):
        for x: int in range(size):
            var pixel_pos: Vector2 = Vector2(float(x) + 0.5, float(y) + 0.5)
            var distance: float = pixel_pos.distance_to(center)
            if distance <= inner_radius:
                image.set_pixel(x, y, Color(0.92, 0.98, 1.0, 0.96))
                continue
            if distance > outer_radius:
                continue
            var fade: float = 1.0 - ((distance - inner_radius) / max(0.01, outer_radius - inner_radius))
            image.set_pixel(x, y, Color(0.28, 0.88, 1.0, 0.6 * fade))
    _weapon_orbit_placeholder_texture = ImageTexture.create_from_image(image)
    return _weapon_orbit_placeholder_texture

func _compute_weapon_orbit_base_scale(texture: Texture2D) -> Vector2:
    if texture == null:
        return Vector2.ONE
    var raw_size: Vector2 = texture.get_size()
    if raw_size.x <= 0.0:
        return Vector2.ONE
    var factor: float = clampf(WEAPON_ORBIT_ICON_TARGET_WIDTH / raw_size.x, 0.32, 1.35)
    return Vector2.ONE * factor

func _resolve_weapon_orbit_base_scale(sprite: Sprite2D) -> Vector2:
    if sprite == null:
        return Vector2.ONE
    var base_scale_value: Variant = sprite.get_meta("base_scale", Vector2.ONE)
    if base_scale_value is Vector2:
        return base_scale_value
    return Vector2.ONE

func _resolve_weapon_orbit_radius(active_weapon_count: int) -> float:
    return WEAPON_ORBIT_FORWARD_OFFSET + float(max(0, active_weapon_count - 1)) * 2.0

func _trigger_weapon_orbit_flash(slot_index: int) -> void:
    if not _weapon_orbit_nodes.has(slot_index):
        return
    _weapon_orbit_flash_timers[slot_index] = WEAPON_ORBIT_FLASH_DURATION

func _spawn_melee_arc_effect(target_position: Vector2, attack_profile: Dictionary) -> void:
    if _player == null or not is_instance_valid(_player):
        return
    var effect: Node2D = MELEE_ARC_EFFECT_SCRIPT.new() as Node2D
    if effect == null:
        return
    effect.global_position = _player.global_position
    add_child(effect)
    var direction: Vector2 = (_player.global_position.direction_to(target_position)).normalized()
    if direction.length_squared() <= 0.0001:
        direction = Vector2.RIGHT
    var profile_range: float = clampf(float(attack_profile.get("range", 95.0)), 55.0, 130.0)
    var arc_width: float = clampf(float(attack_profile.get("arc_width", 1.35)), 0.4, 2.2)
    if effect.has_method("configure"):
        effect.call(
            "configure",
            direction.angle(),
            profile_range * 0.85,
            arc_width,
            8.0,
            Color(0.9, 0.98, 1.0, 0.92),
            0.11
        )

func _cleanup_dead_enemies() -> void :
    var alive: Array[Enemy] = []
    for enemy: Enemy in _enemies:
        if enemy != null and is_instance_valid(enemy):
            alive.append(enemy)
    _enemies = alive
    if _active_elite != null and not is_instance_valid(_active_elite):
        _active_elite = null

func _handle_projectile_hits() -> void :
    for projectile: Projectile in _projectiles:
        if projectile == null or not is_instance_valid(projectile):
            continue
        for enemy: Enemy in _enemies:
            if not _is_enemy_combat_active(enemy):
                continue
            var hit_distance: float = projectile.hit_radius + enemy.body_radius
            if projectile.global_position.distance_squared_to(enemy.global_position) <= hit_distance * hit_distance:
                var projectile_owner: Player = projectile.owner_player
                var outgoing_damage: int = projectile.damage
                if projectile_owner != null and is_instance_valid(projectile_owner):
                    outgoing_damage = projectile_owner.roll_outgoing_damage(
                        projectile.damage,
                        projectile.crit_chance,
                        projectile.crit_multiplier
                    )
                var dealt_damage: int = enemy.take_damage(outgoing_damage)
                if projectile_owner != null and is_instance_valid(projectile_owner):
                    projectile_owner.heal_from_lifesteal(dealt_damage, projectile.lifesteal_chance)
                projectile.queue_free()
                break
    _cleanup_dead_enemies()

func _on_enemy_projectile_fired(
    shooter: Enemy,
    origin: Vector2, 
    direction: Vector2, 
    speed: float, 
    damage: int, 
    hit_radius: float, 
    life_time: float, 
    tint: Color
) -> void :
    _pending_enemy_shots.append({
        "shooter": shooter,
        "origin": origin,
        "direction": direction,
        "speed": speed,
        "damage": damage,
        "hit_radius": hit_radius,
        "life_time": life_time,
        "tint": tint,
        "physics_frame_id": Engine.get_physics_frames(),
    })

func _flush_pending_enemy_shots() -> void:
    if _pending_enemy_shots.is_empty():
        return
    var pending: Array[Dictionary] = _pending_enemy_shots
    _pending_enemy_shots = []
    for shot: Dictionary in pending:
        var shooter_value: Variant = shot.get("shooter", null)
        if not _is_enemy_combat_active(shooter_value):
            continue
        var projectile: EnemyProjectile = EnemyProjectile.new()
        projectile.global_position = shot.get("origin", Vector2.ZERO)
        projectile.direction = Vector2(shot.get("direction", Vector2.ZERO))
        projectile.speed = float(shot.get("speed", 0.0))
        projectile.damage = max(
            1,
            int(round(float(shot.get("damage", 1)) * _enemy_damage_multiplier))
        )
        projectile.hit_radius = float(shot.get("hit_radius", 4.0))
        projectile.life_time = float(shot.get("life_time", 3.0))
        projectile.tint = shot.get("tint", Color(1.0, 0.36, 0.3, 1.0))
        add_child(projectile)
        _enemy_projectiles.append(projectile)

func _handle_enemy_projectile_hits() -> void :
    if _player == null or not is_instance_valid(_player):
        return
    for projectile: EnemyProjectile in _enemy_projectiles:
        if projectile == null or not is_instance_valid(projectile):
            continue
        var hit_distance: float = projectile.hit_radius + _player.body_radius
        if projectile.global_position.distance_squared_to(_player.global_position) <= hit_distance * hit_distance:
            _player.take_damage(projectile.damage)
            projectile.queue_free()
            _refresh_player_hud()
            if _is_game_over:
                return

func _handle_enemy_contact_damage() -> void :
    if _player == null or not is_instance_valid(_player):
        return
    if _contact_damage_timer > 0.0:
        return
    var touched: bool = false
    for enemy: Enemy in _enemies:
        if not _is_enemy_combat_active(enemy):
            continue
        var contact_distance: float = enemy.body_radius + _player.body_radius + 2.0
        if enemy.global_position.distance_squared_to(_player.global_position) <= contact_distance * contact_distance:
            touched = true
            break
    if not touched:
        return
    _contact_damage_timer = CONTACT_DAMAGE_INTERVAL
    var scaled_contact_damage: int = max(1, int(round(float(CONTACT_DAMAGE) * _enemy_damage_multiplier)))
    _player.take_damage(scaled_contact_damage)
    _refresh_player_hud()

func _cleanup_dead_projectiles() -> void :
    var alive: Array[Projectile] = []
    for projectile: Projectile in _projectiles:
        if projectile != null and is_instance_valid(projectile):
            alive.append(projectile)
    _projectiles = alive

func _cleanup_dead_enemy_projectiles() -> void :
    var alive: Array[EnemyProjectile] = []
    for projectile: EnemyProjectile in _enemy_projectiles:
        if projectile != null and is_instance_valid(projectile):
            alive.append(projectile)
    _enemy_projectiles = alive

func _update_experience_orbs(delta: float) -> void :
    if _player == null or not is_instance_valid(_player):
        return
    var pickup_radius: float = max(0.0, _player.pickup_radius)
    for orb: ExperienceOrb in _experience_orbs:
        if orb == null or not is_instance_valid(orb):
            continue
        if orb.tick_collect(_player.global_position, pickup_radius, delta):
            _add_experience(orb.xp_value)
            if orb.gold_value > 0:
                _add_gold(orb.gold_value)
            orb.queue_free()
            if _reward_opened:
                break

func _cleanup_dead_experience_orbs() -> void :
    var alive: Array[ExperienceOrb] = []
    for orb: ExperienceOrb in _experience_orbs:
        if orb != null and is_instance_valid(orb):
            alive.append(orb)
    _experience_orbs = alive

func _clear_experience_orbs() -> void :
    for orb: ExperienceOrb in _experience_orbs:
        if orb != null and is_instance_valid(orb):
            orb.queue_free()
    _experience_orbs.clear()

func _clear_enemy_projectiles() -> void :
    _pending_enemy_shots.clear()
    for projectile: EnemyProjectile in _enemy_projectiles:
        if projectile != null and is_instance_valid(projectile):
            projectile.queue_free()
    _enemy_projectiles.clear()

func _clear_all_enemies() -> void:
    for enemy: Enemy in _enemies:
        if enemy != null and is_instance_valid(enemy):
            enemy.queue_free()
    _enemies.clear()
    _active_elite = null
    if hud != null and hud.has_method("hide_boss_bar"):
        hud.call("hide_boss_bar")

func _refresh_player_hud() -> void :
    if _player == null or not is_instance_valid(_player):
        return
    if hud.has_method("set_player_stats"):
        hud.call(
            "set_player_stats", 
            float(_player.current_hp), 
            float(_player.max_hp), 
            _player.current_stamina, 
            _player.stamina_max, 
            float(_current_xp), 
            float(_xp_to_next_level), 
            _current_level,
            _current_gold_runtime
        )

func _update_elite_boss_bar() -> void :
    if _active_elite == null or not is_instance_valid(_active_elite):
        return
    if hud.has_method("update_boss_hp"):
        hud.call("update_boss_hp", float(_active_elite.current_hp))

func _draw() -> void :
    var world_rect: Rect2 = Rect2(-3000.0, -3000.0, 6000.0, 6000.0)
    draw_rect(world_rect, Color(0.05, 0.09, 0.11, 1.0), true)
    var arena_rect: Rect2 = _arena_rect()
    var stage_texture: Texture2D = _get_stage_background_texture()
    if stage_texture != null:
        # Render one full map image in the arena instead of tiled repetition.
        draw_texture_rect(stage_texture, arena_rect, false, Color(1.0, 1.0, 1.0, 0.95))

    # Keep a lightweight grid/border overlay so movement and scale stay readable.
    var grid_color_major: Color = Color(0.2, 0.33, 0.37, 0.22)
    var grid_color_minor: Color = Color(0.13, 0.22, 0.25, 0.14)
    var min_x: int = int(floor(arena_rect.position.x / 80.0)) * 80
    var max_x: int = int(ceil(arena_rect.end.x / 80.0)) * 80
    var min_y: int = int(floor(arena_rect.position.y / 80.0)) * 80
    var max_y: int = int(ceil(arena_rect.end.y / 80.0)) * 80

    for x: int in range(min_x, max_x + 1, 80):
        var cx: Color = grid_color_major if x % 320 == 0 else grid_color_minor
        draw_line(Vector2(x, arena_rect.position.y), Vector2(x, arena_rect.end.y), cx, 1.0)
    for y: int in range(min_y, max_y + 1, 80):
        var cy: Color = grid_color_major if y % 320 == 0 else grid_color_minor
        draw_line(Vector2(arena_rect.position.x, y), Vector2(arena_rect.end.x, y), cy, 1.0)

    draw_rect(arena_rect, Color(0.23, 0.36, 0.4, 0.35), false, 2.0)

func _bind_pause_menu() -> void :
    resume_button.text = _tx("ui.pause.resume", "Resume")
    main_menu_button.text = _tx("ui.pause.main_menu", "Main Menu")
    save_button.text = _tx("ui.pause.save", "Save")
    settings_button.text = _tx("ui.pause.settings", "Settings")
    resume_button.pressed.connect(_on_resume_button_pressed)
    main_menu_button.pressed.connect(_on_main_menu_button_pressed)
    save_button.pressed.connect(_on_save_button_pressed)
    settings_button.pressed.connect(_on_settings_button_pressed)

func _create_pause_sub_panels() -> void :
    var panel_node: Node = null
    if _save_slot_panel_scene != null:
        panel_node = _save_slot_panel_scene.instantiate()
    else:
        panel_node = SaveSlotPanel.new()
    _slot_panel = panel_node as SaveSlotPanel
    if _slot_panel == null:
        panel_node.queue_free()
        return
    _add_pause_sub_panel(_slot_panel)
    _slot_panel.slot_selected.connect(_on_slot_button_pressed)
    _slot_panel.panel_closed.connect(_hide_pause_sub_panels)
    _slot_panel.visible = false

    if _settings_scene_resource != null:
        var settings_node: Node = _settings_scene_resource.instantiate()
        _settings_panel = settings_node as Control
        if _settings_panel != null:
            _add_pause_sub_panel(_settings_panel)
            _settings_panel.visible = false
            if _settings_panel.has_method("set_embedded_mode"):
                _settings_panel.call("set_embedded_mode", true)
            if _settings_panel.has_signal("request_close"):
                _settings_panel.connect("request_close", Callable(self, "_on_settings_panel_close_requested"))

    _create_level_reward_panel()
    _create_death_settlement_panel()

func _prepare_pause_sub_scenes() -> void :
    var loaded_scene: Resource = ResourceLoader.load(SAVE_SLOT_PANEL_SCENE_PATH)
    if loaded_scene is PackedScene:
        var packed_scene: PackedScene = loaded_scene
        _save_slot_panel_scene = packed_scene
    else:
        _save_slot_panel_scene = null
        push_error("Failed to load scene: %s" % SAVE_SLOT_PANEL_SCENE_PATH)

    var loaded_settings_scene: Resource = ResourceLoader.load(SETTINGS_SCENE_PATH)
    if loaded_settings_scene is PackedScene:
        var settings_scene: PackedScene = loaded_settings_scene
        _settings_scene_resource = settings_scene
    else:
        _settings_scene_resource = null
        push_error("Failed to load scene: %s" % SETTINGS_SCENE_PATH)

func _add_pause_sub_panel(panel: Control) -> void :
    pause_overlay.add_child(panel)
    var panel_index: int = max(0, pause_overlay.get_child_count() - 2)
    pause_overlay.move_child(panel, panel_index)

func _create_level_reward_panel() -> void :
    var panel: PanelContainer = PanelContainer.new()
    panel.visible = false
    panel.custom_minimum_size = Vector2(460.0, 320.0)
    panel.anchors_preset = Control.PRESET_CENTER
    panel.anchor_left = 0.5
    panel.anchor_top = 0.5
    panel.anchor_right = 0.5
    panel.anchor_bottom = 0.5
    panel.offset_left = -230.0
    panel.offset_top = -160.0
    panel.offset_right = 230.0
    panel.offset_bottom = 160.0
    panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
    panel.grow_vertical = Control.GROW_DIRECTION_BOTH

    var margin: MarginContainer = MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 16)
    margin.add_theme_constant_override("margin_top", 14)
    margin.add_theme_constant_override("margin_right", 16)
    margin.add_theme_constant_override("margin_bottom", 14)
    panel.add_child(margin)

    var vbox: VBoxContainer = VBoxContainer.new()
    vbox.add_theme_constant_override("separation", 8)
    margin.add_child(vbox)

    _level_reward_title = Label.new()
    _level_reward_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _level_reward_title.add_theme_font_size_override("font_size", 28)
    vbox.add_child(_level_reward_title)

    vbox.add_spacer(false)

    _level_reward_buttons.clear()
    for i: int in range(LEVEL_REWARD_CHOICES_COUNT):
        var button: Button = _build_reward_button("Loading...", "none")
        _level_reward_buttons.append(button)
        vbox.add_child(button)

    _level_reward_panel = panel
    _add_pause_sub_panel(_level_reward_panel)

func _create_death_settlement_panel() -> void:
    var panel: PanelContainer = PanelContainer.new()
    panel.visible = false
    panel.custom_minimum_size = Vector2(720.0, 430.0)
    panel.anchors_preset = Control.PRESET_CENTER
    panel.anchor_left = 0.5
    panel.anchor_top = 0.5
    panel.anchor_right = 0.5
    panel.anchor_bottom = 0.5
    panel.offset_left = -360.0
    panel.offset_top = -215.0
    panel.offset_right = 360.0
    panel.offset_bottom = 215.0
    panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
    panel.grow_vertical = Control.GROW_DIRECTION_BOTH
    panel.add_theme_stylebox_override("panel", _build_neon_panel_style(
        Color(0.015, 0.05, 0.075, 0.95),
        Color(0.11, 0.78, 0.8, 0.92),
        3,
        28
    ))

    var margin: MarginContainer = MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 20)
    margin.add_theme_constant_override("margin_top", 18)
    margin.add_theme_constant_override("margin_right", 20)
    margin.add_theme_constant_override("margin_bottom", 18)
    panel.add_child(margin)

    var vbox: VBoxContainer = VBoxContainer.new()
    vbox.add_theme_constant_override("separation", 12)
    margin.add_child(vbox)

    _death_settlement_title = Label.new()
    _death_settlement_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _death_settlement_title.add_theme_font_size_override("font_size", 44)
    _death_settlement_title.add_theme_color_override("font_color", Color(0.56, 1.0, 0.88, 1.0))
    _death_settlement_title.text = _tx("ui.game_over.defeat_title", "Defeat")
    vbox.add_child(_death_settlement_title)

    _death_settlement_subtitle = Label.new()
    _death_settlement_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _death_settlement_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _death_settlement_subtitle.add_theme_font_size_override("font_size", 20)
    _death_settlement_subtitle.add_theme_color_override("font_color", Color(0.76, 0.9, 0.96, 0.92))
    _death_settlement_subtitle.text = _tx("ui.game_scene.death_subtitle", "Signal interrupted, battle report generated.")
    vbox.add_child(_death_settlement_subtitle)

    var separator: HSeparator = HSeparator.new()
    vbox.add_child(separator)

    var stat_card: PanelContainer = PanelContainer.new()
    stat_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
    stat_card.add_theme_stylebox_override("panel", _build_neon_panel_style(
        Color(0.018, 0.075, 0.11, 0.88),
        Color(0.12, 0.63, 0.72, 0.84),
        2,
        14
    ))
    vbox.add_child(stat_card)

    var stat_margin: MarginContainer = MarginContainer.new()
    stat_margin.add_theme_constant_override("margin_left", 14)
    stat_margin.add_theme_constant_override("margin_top", 12)
    stat_margin.add_theme_constant_override("margin_right", 14)
    stat_margin.add_theme_constant_override("margin_bottom", 12)
    stat_card.add_child(stat_margin)

    var stat_grid: GridContainer = GridContainer.new()
    stat_grid.columns = 2
    stat_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    stat_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
    stat_grid.add_theme_constant_override("h_separation", 10)
    stat_grid.add_theme_constant_override("v_separation", 8)
    stat_margin.add_child(stat_grid)

    _death_settlement_value_labels.clear()
    _create_death_stat_cell(stat_grid, "stage", _tx("ui.game_scene.stat_stage", "Stage"))
    _create_death_stat_cell(stat_grid, "wave", _tx("ui.game_scene.stat_wave", "Wave"))
    _create_death_stat_cell(stat_grid, "survival", _tx("ui.game_scene.stat_survival", "Survival"))
    _create_death_stat_cell(stat_grid, "level", _tx("ui.game_scene.stat_level", "Level"))
    _create_death_stat_cell(stat_grid, "gold", _tx("ui.game_scene.stat_gold", "Gold"))
    _create_death_stat_cell(stat_grid, "kills", _tx("ui.game_scene.stat_kills", "Kills"))

    var button_row: HBoxContainer = HBoxContainer.new()
    button_row.add_theme_constant_override("separation", 12)
    button_row.alignment = BoxContainer.ALIGNMENT_CENTER
    vbox.add_child(button_row)

    _death_retry_button = Button.new()
    _style_neon_action_button(_death_retry_button, _tx("ui.game_scene.retry_stage", "Retry Stage"))
    _death_retry_button.pressed.connect(_on_death_retry_pressed)
    button_row.add_child(_death_retry_button)

    _death_menu_button = Button.new()
    _style_neon_action_button(_death_menu_button, _tx("ui.game_over.back_to_menu", "Back to Menu"))
    _death_menu_button.pressed.connect(_on_death_menu_pressed)
    button_row.add_child(_death_menu_button)

    _death_settlement_panel = panel
    _add_pause_sub_panel(_death_settlement_panel)

func _build_neon_panel_style(
    bg_color: Color,
    border_color: Color,
    border_width: int = 2,
    shadow_size: int = 12
) -> StyleBoxFlat:
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = bg_color
    style.border_color = border_color
    style.border_width_left = border_width
    style.border_width_top = border_width
    style.border_width_right = border_width
    style.border_width_bottom = border_width
    style.corner_radius_top_left = 8
    style.corner_radius_top_right = 8
    style.corner_radius_bottom_left = 8
    style.corner_radius_bottom_right = 8
    style.shadow_color = Color(0.0, 0.82, 0.86, 0.24)
    style.shadow_size = shadow_size
    return style

func _create_death_stat_cell(parent: GridContainer, key: String, title_text: String) -> void:
    var cell_panel: PanelContainer = PanelContainer.new()
    cell_panel.custom_minimum_size = Vector2(0.0, 78.0)
    cell_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    cell_panel.add_theme_stylebox_override("panel", _build_neon_panel_style(
        Color(0.012, 0.055, 0.085, 0.86),
        Color(0.1, 0.52, 0.62, 0.75),
        1,
        6
    ))
    parent.add_child(cell_panel)

    var cell_margin: MarginContainer = MarginContainer.new()
    cell_margin.add_theme_constant_override("margin_left", 10)
    cell_margin.add_theme_constant_override("margin_top", 8)
    cell_margin.add_theme_constant_override("margin_right", 10)
    cell_margin.add_theme_constant_override("margin_bottom", 8)
    cell_panel.add_child(cell_margin)

    var cell_vbox: VBoxContainer = VBoxContainer.new()
    cell_vbox.add_theme_constant_override("separation", 4)
    cell_margin.add_child(cell_vbox)

    var title: Label = Label.new()
    title.text = title_text
    title.add_theme_font_size_override("font_size", 16)
    title.add_theme_color_override("font_color", Color(0.53, 0.94, 0.95, 0.95))
    cell_vbox.add_child(title)

    var value: Label = Label.new()
    value.text = "--"
    value.add_theme_font_size_override("font_size", 24)
    value.add_theme_color_override("font_color", Color(0.92, 0.98, 1.0, 1.0))
    value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    cell_vbox.add_child(value)

    _death_settlement_value_labels[key] = value

func _set_death_settlement_value(key: String, value: String) -> void:
    var entry: Variant = _death_settlement_value_labels.get(key, null)
    if entry is Label:
        var target_label: Label = entry
        target_label.text = value

func _style_neon_action_button(button: Button, text: String) -> void:
    if button == null:
        return
    button.custom_minimum_size = Vector2(220.0, 56.0)
    button.add_theme_font_size_override("font_size", 26)
    button.text = text
    if NEON_OPTION_BUTTON_SCRIPT != null:
        button.set_script(NEON_OPTION_BUTTON_SCRIPT)

func _build_reward_button(text: String, reward_id: String) -> Button:
    var button: Button = Button.new()
    button.custom_minimum_size = Vector2(400.0, 52.0)
    button.text = text
    button.add_theme_font_size_override("font_size", 24)
    button.set_meta("reward_id", reward_id)
    button.pressed.connect(_on_level_reward_button_pressed.bind(button))
    return button

func _on_level_reward_button_pressed(button: Button) -> void:
    if button == null:
        return
    var reward_id: String = str(button.get_meta("reward_id", ""))
    if reward_id.is_empty() or reward_id == "none":
        return
    _on_level_reward_selected(reward_id)

func _open_pause_menu() -> void :
    if _wave_end_reward_gate_active:
        return
    _pause_opened = true
    _hide_pause_sub_panels()
    GameManager.pause_game()
    _play_pause_overlay_open_transition()

func _resume_game_from_pause() -> void :
    if _reward_opened:
        _show_level_reward_panel()
        return
    _pause_opened = false
    _hide_pause_sub_panels()
    _play_pause_overlay_close_transition(func() -> void:
        GameManager.resume_game()
    )

func _set_pause_overlay_visible(is_visible: bool) -> void :
    _stop_pause_transition_tween()
    pause_overlay.visible = is_visible
    pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP if is_visible else Control.MOUSE_FILTER_IGNORE
    if pause_dimmer != null:
        pause_dimmer.modulate.a = 1.0 if is_visible else 0.0
    if pause_panel != null:
        pause_panel.modulate.a = 1.0 if is_visible else 0.0
        pause_panel.scale = Vector2.ONE
        pause_panel.pivot_offset = pause_panel.size * 0.5
    if not is_visible:
        _hide_pause_sub_panels()

func _play_pause_overlay_open_transition() -> void:
    if pause_overlay == null or pause_panel == null:
        _set_pause_overlay_visible(true)
        return
    _stop_pause_transition_tween()
    pause_overlay.visible = true
    pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    pause_panel.visible = true
    pause_panel.pivot_offset = pause_panel.size * 0.5
    pause_panel.scale = Vector2(PAUSE_PANEL_POP_SCALE, PAUSE_PANEL_POP_SCALE)
    pause_panel.modulate.a = 0.0
    if pause_dimmer != null:
        pause_dimmer.modulate.a = 0.0
    _pause_transition_tween = create_tween()
    _pause_transition_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
    _pause_transition_tween.set_trans(Tween.TRANS_QUART)
    _pause_transition_tween.set_ease(Tween.EASE_OUT)
    _pause_transition_tween.parallel().tween_property(pause_panel, "modulate:a", 1.0, PAUSE_OPEN_DURATION)
    _pause_transition_tween.parallel().tween_property(pause_panel, "scale", Vector2.ONE, PAUSE_OPEN_DURATION)
    if pause_dimmer != null:
        _pause_transition_tween.parallel().tween_property(pause_dimmer, "modulate:a", 1.0, PAUSE_OPEN_DURATION)
    _pause_transition_tween.finished.connect(func() -> void:
        _pause_transition_tween = null
    )

func _play_pause_overlay_close_transition(on_finished: Callable = Callable()) -> void:
    if pause_overlay == null or pause_panel == null:
        _set_pause_overlay_visible(false)
        if on_finished.is_valid():
            on_finished.call()
        return
    if not pause_overlay.visible:
        if on_finished.is_valid():
            on_finished.call()
        return
    _stop_pause_transition_tween()
    pause_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    pause_panel.visible = true
    pause_panel.pivot_offset = pause_panel.size * 0.5
    _pause_transition_tween = create_tween()
    _pause_transition_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
    _pause_transition_tween.set_trans(Tween.TRANS_QUART)
    _pause_transition_tween.set_ease(Tween.EASE_IN)
    _pause_transition_tween.parallel().tween_property(pause_panel, "modulate:a", 0.0, PAUSE_CLOSE_DURATION)
    _pause_transition_tween.parallel().tween_property(
        pause_panel,
        "scale",
        Vector2(PAUSE_PANEL_POP_SCALE, PAUSE_PANEL_POP_SCALE),
        PAUSE_CLOSE_DURATION
    )
    if pause_dimmer != null:
        _pause_transition_tween.parallel().tween_property(pause_dimmer, "modulate:a", 0.0, PAUSE_CLOSE_DURATION)
    _pause_transition_tween.finished.connect(func() -> void:
        pause_overlay.visible = false
        pause_panel.modulate.a = 1.0
        pause_panel.scale = Vector2.ONE
        if pause_dimmer != null:
            pause_dimmer.modulate.a = 1.0
        _pause_transition_tween = null
        if on_finished.is_valid():
            on_finished.call()
    )

func _stop_pause_transition_tween() -> void:
    if _pause_transition_tween != null and is_instance_valid(_pause_transition_tween):
        _pause_transition_tween.kill()
    _pause_transition_tween = null

func _on_resume_button_pressed() -> void :
    if _reward_opened:
        _show_level_reward_panel()
        return
    _resume_game_from_pause()

func _on_main_menu_button_pressed() -> void :
    _pause_opened = false
    _play_pause_overlay_close_transition(func() -> void:
        GameManager.go_to_menu()
    )

func _on_save_button_pressed() -> void :
    _show_slot_panel(SaveSlotPanel.MODE_SAVE)

func _on_settings_button_pressed() -> void :
    _show_settings_panel()

func _show_slot_panel(mode: String) -> void :
    if _reward_opened:
        _show_level_reward_panel()
        return
    if _slot_panel == null:
        return
    _set_crt_effects_enabled(true)
    if _settings_panel != null:
        _settings_panel.visible = false
    _slot_panel.setup(mode)
    _slot_panel.visible = true
    pause_panel.visible = false

func _show_settings_panel() -> void :
    if _reward_opened:
        _show_level_reward_panel()
        return
    if _settings_panel == null:
        return
    _set_crt_effects_enabled(false)
    if _slot_panel != null:
        _slot_panel.visible = false
    _settings_panel.visible = true
    pause_panel.visible = false

func _hide_pause_sub_panels() -> void :
    if _reward_opened:
        _set_crt_effects_enabled(true)
        if _slot_panel != null:
            _slot_panel.visible = false
        if _settings_panel != null:
            _settings_panel.visible = false
        if _death_settlement_panel != null:
            _death_settlement_panel.visible = false
        pause_panel.visible = false
        if _level_reward_panel != null:
            _level_reward_panel.visible = true
        return
    _set_crt_effects_enabled(true)
    if _slot_panel != null:
        _slot_panel.visible = false
    if _settings_panel != null:
        _settings_panel.visible = false
    if _level_reward_panel != null:
        _level_reward_panel.visible = false
    if _death_settlement_panel != null:
        _death_settlement_panel.visible = false
    pause_panel.visible = true

func _is_pause_sub_panel_open() -> bool:
    var slot_open: bool = _slot_panel != null and _slot_panel.visible
    var settings_open: bool = _settings_panel != null and _settings_panel.visible
    var reward_open: bool = _level_reward_panel != null and _level_reward_panel.visible
    var death_summary_open: bool = _death_settlement_panel != null and _death_settlement_panel.visible
    return slot_open or settings_open or reward_open or death_summary_open

func _on_death_retry_pressed() -> void:
    get_tree().paused = false
    _pause_opened = false
    _set_pause_overlay_visible(false)
    GameManager.start_game(GameManager.current_stage_id)

func _on_death_menu_pressed() -> void:
    get_tree().paused = false
    _pause_opened = false
    _set_pause_overlay_visible(false)
    GameManager.go_to_menu()

func _on_settings_panel_close_requested() -> void :
    _hide_pause_sub_panels()

func _set_crt_effects_enabled(enabled: bool) -> void:
    if crt_overlay != null:
        crt_overlay.visible = enabled

func _on_enemy_died(enemy: Enemy) -> void :
    if _is_game_over:
        return
    if enemy == null:
        return
    _run_kill_count += 1
    if enemy == _active_elite:
        _active_elite = null
        if hud.has_method("hide_boss_bar"):
            hud.call("hide_boss_bar")
    var gold_amount: int = _resolve_enemy_gold_drop(enemy) + _roll_harvest_kill_bonus_gold()
    _spawn_experience_orb(enemy.global_position, enemy.xp_drop_amount, gold_amount)

func _resolve_enemy_gold_drop(enemy: Enemy) -> int:
    var combat_params: Dictionary = BalanceService.get_global_combat_params()
    var gold_drop: Dictionary = combat_params.get("gold_drop", {})
    if enemy.is_elite:
        return int(gold_drop.get("elite", 8))
    if enemy.enemy_type == Enemy.EnemyType.RANGED or enemy.enemy_type == Enemy.EnemyType.BARRAGE:
        return int(gold_drop.get("ranged", 2))
    return int(gold_drop.get("melee", 1))

func _add_gold(amount: int) -> void:
    if amount <= 0:
        return
    var scaled_amount: int = max(0, int(round(float(amount) * _gold_multiplier)))
    _current_gold_runtime = max(0, _current_gold_runtime + scaled_amount)
    _refresh_player_hud()

func _resolve_wave_harvest_gold() -> int:
    if _player == null or not is_instance_valid(_player):
        return 0
    var harvest_value: float = max(0.0, _player.get_harvest())
    if harvest_value <= 0.0:
        return 0
    var combat_params: Dictionary = BalanceService.get_global_combat_params()
    var wave_gold_per_point: float = max(
        0.0,
        float(combat_params.get("harvest_wave_gold_per_point", HARVEST_WAVE_GOLD_PER_POINT_DEFAULT))
    )
    return max(0, int(round(harvest_value * wave_gold_per_point)))

func _roll_harvest_kill_bonus_gold() -> int:
    if _player == null or not is_instance_valid(_player):
        return 0
    var harvest_value: float = max(0.0, _player.get_harvest())
    if harvest_value <= 0.0:
        return 0
    var combat_params: Dictionary = BalanceService.get_global_combat_params()
    var chance_per_point: float = max(
        0.0,
        float(combat_params.get("harvest_kill_gold_chance_per_point", HARVEST_KILL_GOLD_CHANCE_PER_POINT_DEFAULT))
    )
    var max_chance: float = clampf(
        float(combat_params.get("harvest_kill_gold_max_chance", HARVEST_KILL_GOLD_MAX_CHANCE_DEFAULT)),
        0.0,
        1.0
    )
    var trigger_chance: float = clampf(harvest_value * chance_per_point, 0.0, max_chance)
    if randf() > trigger_chance:
        return 0
    return max(0, int(combat_params.get("harvest_kill_gold_amount", HARVEST_KILL_GOLD_AMOUNT_DEFAULT)))

func _spawn_experience_orb(spawn_position: Vector2, xp_value: int, gold_value: int = 0) -> void :
    var orb: ExperienceOrb = ExperienceOrb.new()
    orb.global_position = spawn_position
    orb.setup(xp_value, gold_value)
    add_child(orb)
    _experience_orbs.append(orb)

func _add_experience(amount: int) -> void :
    if amount <= 0:
        return
    var player_xp_gain: float = 1.0
    if _player != null and is_instance_valid(_player):
        player_xp_gain = _player.get_xp_gain_multiplier()
    var scaled_amount: int = max(1, int(round(float(amount) * _xp_multiplier * player_xp_gain)))
    _current_xp += scaled_amount
    while _current_xp >= _xp_to_next_level:
        _current_xp -= _xp_to_next_level
        _current_level += 1
        _apply_level_up_base_growth()
        _xp_to_next_level = _xp_required_for_level(_current_level)
        _pending_level_up_rewards += 1
        EventBus.level_up.emit(_current_level)
    _refresh_player_hud()
    _try_open_next_level_reward()

func _apply_level_up_base_growth() -> void:
    if _player == null or not is_instance_valid(_player):
        return
    var max_hp_bonus: int = _get_level_up_max_hp_bonus()
    var current_hp_bonus: int = _get_level_up_current_hp_bonus()
    if max_hp_bonus <= 0 and current_hp_bonus <= 0:
        return
    if max_hp_bonus > 0:
        _player.max_hp = max(1, _player.max_hp + max_hp_bonus)
    if current_hp_bonus > 0:
        _player.current_hp = clampi(_player.current_hp + current_hp_bonus, 0, _player.max_hp)

func _get_level_up_max_hp_bonus() -> int:
    var combat_params: Dictionary = BalanceService.get_global_combat_params()
    return max(0, int(combat_params.get("level_up_max_hp_bonus", LEVEL_UP_MAX_HP_BONUS_DEFAULT)))

func _get_level_up_current_hp_bonus() -> int:
    var combat_params: Dictionary = BalanceService.get_global_combat_params()
    return max(0, int(combat_params.get("level_up_current_hp_bonus", LEVEL_UP_CURRENT_HP_BONUS_DEFAULT)))

func _xp_required_for_level(current_level: int) -> int:
    var combat_params: Dictionary = BalanceService.get_global_combat_params()
    var target_level: int = max(1, current_level)
    var level_offset: int = int(combat_params.get("xp_curve_level_offset", XP_CURVE_LEVEL_OFFSET_DEFAULT))
    var base_multiplier: float = max(0.01, float(combat_params.get("xp_curve_base_multiplier", XP_CURVE_BASE_MULT_DEFAULT)))
    var min_required: int = max(1, int(combat_params.get("xp_required_min", XP_REQUIRED_MIN_DEFAULT)))
    var curve_value: float = float(target_level + level_offset)
    var required: int = int(round(curve_value * curve_value * base_multiplier * _xp_required_multiplier_runtime))
    return max(min_required, required)

func _resolve_character_xp_required_multiplier(character_id: String) -> float:
    if character_id.is_empty():
        return 1.0
    var character_profile: Dictionary = BalanceService.get_character_profile(character_id)
    return clampf(float(character_profile.get("xp_required_mult", 1.0)), 0.2, 5.0)

func _try_open_next_level_reward() -> void :
    if _pending_level_up_rewards <= 0:
        return
    if not _wave_end_reward_gate_active:
        return
    if _reward_opened or _is_game_over:
        return
    _show_level_reward_panel()

func _show_level_reward_panel() -> void :
    if _level_reward_panel == null:
        return
    _reward_opened = true
    get_tree().paused = true
    _set_pause_overlay_visible(true)
    pause_panel.visible = false
    if _slot_panel != null:
        _slot_panel.visible = false
    if _settings_panel != null:
        _settings_panel.visible = false
    _refresh_level_reward_choices()
    _level_reward_panel.visible = true
    if _level_reward_title != null:
        _level_reward_title.text = _tf("ui.game_scene.level_reward_title_fmt", [_current_level], "Level %d Reward Choice")

func _on_level_reward_selected(reward_id: String) -> void :
    if _player == null or not is_instance_valid(_player):
        return
    if reward_id.is_empty() or reward_id == "none":
        return
    var run_state: Dictionary = _build_reward_run_state()
    run_state = UpgradeSystem.apply_reward(reward_id, _player, run_state)
    _apply_reward_run_state(run_state)

    _pending_level_up_rewards = max(0, _pending_level_up_rewards - 1)
    if _pending_level_up_rewards > 0:
        if _level_reward_title != null:
            _level_reward_title.text = _tf("ui.game_scene.level_reward_title_fmt", [_current_level], "Level %d Reward Choice")
        _refresh_level_reward_choices()
        return
    _close_level_reward_panel()
    _open_shop_after_wave_reward()

func _close_level_reward_panel() -> void :
    _reward_opened = false
    _level_reward_choices = []
    if _level_reward_panel != null:
        _level_reward_panel.visible = false
    get_tree().paused = false
    _set_pause_overlay_visible(false)

func _refresh_level_reward_choices() -> void:
    var reward_context: Dictionary = UpgradeSystem.build_reward_context(_build_reward_run_state())
    _level_reward_choices = UpgradeSystem.get_reward_choices(reward_context)
    for i: int in range(_level_reward_buttons.size()):
        var button: Button = _level_reward_buttons[i]
        if button == null:
            continue
        if i >= _level_reward_choices.size():
            button.disabled = true
            button.text = _tx("ui.game_scene.no_weapon", "No Weapon")
            button.set_meta("reward_id", "none")
            button.tooltip_text = ""
            continue
        var reward: Dictionary = _level_reward_choices[i]
        button.disabled = false
        button.text = str(reward.get("name", "Unknown Weapon"))
        button.set_meta("reward_id", str(reward.get("id", "")))
        button.tooltip_text = str(reward.get("desc", ""))

func _build_reward_run_state() -> Dictionary:
    var player_luck: float = 0.0
    if _player != null and is_instance_valid(_player):
        player_luck = _player.luck
    return {
        "stage_id": GameManager.current_stage_id,
        "level": _current_level,
        "hp_ratio": _get_player_hp_ratio(),
        "difficulty": GameManager.current_difficulty,
        "luck": player_luck,
        "build_tags": _build_tags_runtime.duplicate(),
        "history": _reward_history_runtime.duplicate(),
        "recent_categories": _recent_categories_runtime.duplicate(),
        "pity_state": _reward_pity_state_runtime.duplicate(true),
        "owned_rewards": _owned_weapon_rewards.duplicate(true),
        "gold_gain_multiplier": _gold_multiplier,
        "auto_attack_interval_multiplier": _auto_attack_interval_multiplier_runtime,
    }

func _apply_reward_run_state(run_state: Dictionary) -> void:
    var history_value: Variant = run_state.get("reward_history", _reward_history_runtime)
    if history_value is Array:
        _reward_history_runtime = _extract_string_array(history_value)

    var recent_categories_value: Variant = run_state.get("recent_categories", _recent_categories_runtime)
    if recent_categories_value is Array:
        _recent_categories_runtime = _extract_string_array(recent_categories_value)

    var build_tags_value: Variant = run_state.get("build_tags", _build_tags_runtime)
    if build_tags_value is Array:
        _build_tags_runtime = _extract_string_array(build_tags_value)

    var pity_value: Variant = run_state.get("reward_pity_state", _reward_pity_state_runtime)
    if pity_value is Dictionary:
        _reward_pity_state_runtime = pity_value.duplicate(true)

    var owned_value: Variant = run_state.get("owned_rewards", _owned_weapon_rewards)
    if owned_value is Dictionary:
        _owned_weapon_rewards = owned_value.duplicate(true)

    _gold_multiplier = max(0.1, float(run_state.get("gold_gain_multiplier", _gold_multiplier)))
    _auto_attack_interval_multiplier_runtime = clampf(
        float(run_state.get("auto_attack_interval_multiplier", _auto_attack_interval_multiplier_runtime)),
        0.45,
        1.6
    )
    _refresh_player_hud()

func _get_auto_attack_interval_runtime() -> float:
    var primary_weapon: Dictionary = _get_primary_weapon_runtime()
    var attack_profile: Dictionary = _resolve_attack_profile(primary_weapon)
    var base_interval: float = max(0.08, float(attack_profile.get("interval", AUTO_ATTACK_INTERVAL)))
    var player_speed_mult: float = 1.0
    if _player != null and is_instance_valid(_player):
        player_speed_mult = _player.get_attack_speed_multiplier()
    var safe_speed_mult: float = max(0.01, player_speed_mult)
    return clampf(base_interval * _auto_attack_interval_multiplier_runtime / safe_speed_mult, 0.08, 1.2)

func _on_slot_button_pressed(slot_id: String) -> void :
    if _slot_panel == null:
        return

    if _slot_panel.get_mode() == SaveSlotPanel.MODE_SAVE:
        var save_payload: Dictionary = _build_runtime_save_payload()
        SaveSystem.save_to_slot(slot_id, save_payload)
        _slot_panel.show_hint(_tf("msg.slot.saved_to_fmt", [_slot_title(slot_id)], "Saved to %s"))
        _slot_panel.refresh_slots()
        return

    var loaded_data: Dictionary = SaveSystem.load_from_slot(slot_id)
    if loaded_data.is_empty():
        _slot_panel.show_hint(_tx("msg.slot.empty", "This slot is empty."))
        return

    _apply_loaded_slot_data(loaded_data)
    _resume_game_from_pause()

func _slot_title(slot_id: String) -> String:
    match slot_id:
        "slot_1":
            return _tx("ui.save_slot.slot_1", "Slot 1")
        "slot_2":
            return _tx("ui.save_slot.slot_2", "Slot 2")
        "slot_3":
            return _tx("ui.save_slot.slot_3", "Slot 3")
        _:
            return slot_id

func _build_runtime_save_payload() -> Dictionary:
    _refresh_weapon_tag_state_runtime(false)
    var base_save: Dictionary = SaveSystem.load_save()
    var unlocked_characters: Array[String] = _extract_character_array(base_save.get("unlocked_characters", ["the_fool"]))
    if unlocked_characters.is_empty():
        unlocked_characters.append(_current_player_id)
    if not unlocked_characters.has(_current_player_id):
        unlocked_characters.append(_current_player_id)

    var player_hp: int = 100
    var player_max_hp: int = 100
    var player_stamina: float = 100.0
    var player_stamina_max: float = 100.0
    var player_move_speed: float = 220.0
    var bonus_target_range: float = 0.0
    var bonus_attack_damage: int = 0
    var player_stats: Dictionary = {}
    var player_pos_x: float = 0.0
    var player_pos_y: float = 0.0

    if _player != null and is_instance_valid(_player):
        player_hp = _player.current_hp
        player_max_hp = _player.max_hp
        player_stamina = _player.current_stamina
        player_stamina_max = _player.stamina_max
        player_move_speed = _player.move_speed
        bonus_target_range = _player.bonus_target_range
        player_stats = _player.export_runtime_stats()
        bonus_attack_damage = _estimate_legacy_attack_bonus_from_stats(player_stats)
        player_pos_x = _player.global_position.x
        player_pos_y = _player.global_position.y

    var wave_id: int = 1

    var play_time_value: Variant = base_save.get("total_play_time", 0.0)
    var total_play_time: float = float(play_time_value) + 1.0
    var kill_count_value: Variant = base_save.get("total_kills", 0)
    var total_kills: int = int(kill_count_value)

    return {
        "unlocked_characters": unlocked_characters, 
        "best_stage": GameManager.current_stage_id, 
        "total_kills": total_kills, 
        "total_play_time": total_play_time, 
        "selected_character": _current_player_id, 
        "selected_starter_weapon_id": _selected_starter_weapon_id_runtime,
        "difficulty": GameManager.current_difficulty, 
        "stage_id": GameManager.current_stage_id, 
        "wave": wave_id, 
        "wave_progress_index": _wave_progress_index,
        "player_hp": player_hp, 
        "player_max_hp": player_max_hp, 
        "player_stamina": player_stamina, 
        "player_stamina_max": player_stamina_max, 
        "player_move_speed": player_move_speed, 
        "bonus_target_range": bonus_target_range, 
        "bonus_attack_damage": bonus_attack_damage, 
        "player_stats": player_stats,
        "player_pos_x": player_pos_x, 
        "player_pos_y": player_pos_y, 
        "current_level": _current_level, 
        "current_xp": _current_xp, 
        "current_gold": _current_gold_runtime,
        "xp_to_next_level": _xp_to_next_level, 
        "reward_history": _reward_history_runtime.duplicate(),
        "recent_categories": _recent_categories_runtime.duplicate(),
        "build_tags": _build_tags_runtime.duplicate(),
        "reward_pity_state": _reward_pity_state_runtime.duplicate(true),
        "reward_owned": _owned_weapon_rewards.duplicate(true),
        "auto_attack_interval_multiplier": _auto_attack_interval_multiplier_runtime,
        "gold_gain_multiplier": _gold_multiplier,
        "shop_runtime_state": _shop_runtime_state.duplicate(true),
        "equipped_weapons": _extract_weapon_list_from_shop_state(_shop_runtime_state),
        "locked_shop_offers": _extract_locked_offer_list_from_shop_state(_shop_runtime_state),
    }

func _apply_loaded_slot_data(slot_data: Dictionary, sync_wave_manager: bool = true) -> void :
    var selected_id: String = str(slot_data.get("selected_character", _current_player_id))
    if selected_id.is_empty():
        selected_id = "the_fool"
    var stage_id: String = str(slot_data.get("stage_id", GameManager.current_stage_id))
    var wave_id: int = 1
    var loaded_difficulty: String = str(slot_data.get("difficulty", "normal")).to_lower()
    if loaded_difficulty != "easy" and loaded_difficulty != "hard":
        loaded_difficulty = "normal"
    GameManager.current_difficulty = loaded_difficulty
    _refresh_difficulty_modifiers()

    GameManager.selected_character = selected_id
    _selected_starter_weapon_id_runtime = str(
        slot_data.get("selected_starter_weapon_id", GameManager.selected_starter_weapon_id)
    )
    GameManager.selected_starter_weapon_id = _selected_starter_weapon_id_runtime
    GameManager.current_stage_id = stage_id
    GameManager.current_wave = 1
    _apply_arena_config_from_balance(stage_id)
    _apply_enemy_mix_from_balance(stage_id)
    _apply_stage_runtime_from_balance(stage_id)

    if selected_id != _current_player_id or _player == null or not is_instance_valid(_player):
        _spawn_player(selected_id)
    _clear_applied_weapon_tag_effects()

    var max_hp: int = max(1, int(slot_data.get("player_max_hp", _player.max_hp)))
    var hp: int = clampi(int(slot_data.get("player_hp", max_hp)), 0, max_hp)
    _player.max_hp = max_hp
    _player.current_hp = hp

    var max_stamina: float = max(1.0, float(slot_data.get("player_stamina_max", _player.stamina_max)))
    var stamina: float = clampf(float(slot_data.get("player_stamina", max_stamina)), 0.0, max_stamina)
    _player.stamina_max = max_stamina
    _player.current_stamina = stamina

    var pos_x: float = float(slot_data.get("player_pos_x", 0.0))
    var pos_y: float = float(slot_data.get("player_pos_y", 0.0))
    _player.global_position = Vector2(pos_x, pos_y)
    _player.global_position = _clamp_position_to_arena(_player.global_position, _player.body_radius)

    _player.move_speed = float(slot_data.get("player_move_speed", _player.move_speed))
    _player.bonus_target_range = float(slot_data.get("bonus_target_range", 0.0))
    var legacy_bonus_attack_damage: int = int(slot_data.get("bonus_attack_damage", 0))
    _player.bonus_attack_damage = legacy_bonus_attack_damage
    var player_stats_value: Variant = slot_data.get("player_stats", {})
    var migrated_stats: Dictionary = {}
    if player_stats_value is Dictionary:
        migrated_stats = (player_stats_value as Dictionary).duplicate(true)
    if (
        legacy_bonus_attack_damage != 0
        and not migrated_stats.has("global_attack_percent")
    ):
        migrated_stats["global_attack_percent"] = (
            float(legacy_bonus_attack_damage) * _get_attack_flat_to_global_attack_percent()
        )
    migrated_stats = _migrate_legacy_crit_multiplier_stat(migrated_stats, selected_id)
    if not migrated_stats.is_empty():
        _player.import_runtime_stats(migrated_stats)

    _current_level = max(1, int(slot_data.get("current_level", 1)))
    _current_xp = max(0, int(slot_data.get("current_xp", 0)))
    var expected_xp_to_next: int = _xp_required_for_level(_current_level)
    _xp_to_next_level = max(1, int(slot_data.get("xp_to_next_level", expected_xp_to_next)))
    if _current_level == 1 and _xp_to_next_level == 10:
        _xp_to_next_level = expected_xp_to_next
    while _current_xp >= _xp_to_next_level:
        _current_xp -= _xp_to_next_level
        _current_level += 1
        _xp_to_next_level = _xp_required_for_level(_current_level)
    _pending_level_up_rewards = 0
    _reward_opened = false
    _wave_end_reward_gate_active = false
    _pending_wave_shop_snapshot = {}
    _wave_progress_index = max(0, int(slot_data.get("wave_progress_index", wave_id - 1)))
    _current_gold_runtime = max(0, int(slot_data.get("current_gold", _current_gold_runtime)))
    _shop_runtime_state = _normalize_shop_runtime_state(slot_data.get("shop_runtime_state", {}))
    if _shop_runtime_state.get("equipped_weapons", []).is_empty():
        var legacy_equipped: Variant = slot_data.get("equipped_weapons", [])
        if legacy_equipped is Array:
            _shop_runtime_state["equipped_weapons"] = legacy_equipped.duplicate(true)
    if _shop_runtime_state.get("locked_shop_offers", []).is_empty():
        var legacy_locked: Variant = slot_data.get("locked_shop_offers", [])
        if legacy_locked is Array:
            _shop_runtime_state["locked_shop_offers"] = legacy_locked.duplicate(true)
    _ensure_starter_weapon_equipped()
    _refresh_weapon_tag_state_runtime(true)
    _reward_history_runtime = _extract_string_array(slot_data.get("reward_history", []))
    _recent_categories_runtime = _extract_string_array(slot_data.get("recent_categories", []))
    _build_tags_runtime = _extract_string_array(slot_data.get("build_tags", []))
    var pity_state_value: Variant = slot_data.get("reward_pity_state", {"no_output_streak": 0})
    if pity_state_value is Dictionary:
        _reward_pity_state_runtime = pity_state_value.duplicate(true)
    else:
        _reward_pity_state_runtime = {"no_output_streak": 0}
    var owned_rewards_value: Variant = slot_data.get("reward_owned", {})
    if owned_rewards_value is Dictionary:
        _owned_weapon_rewards = owned_rewards_value.duplicate(true)
    else:
        _owned_weapon_rewards = {}
    _auto_attack_interval_multiplier_runtime = clampf(
        float(slot_data.get("auto_attack_interval_multiplier", _auto_attack_interval_multiplier_runtime)),
        0.45,
        1.6
    )
    _gold_multiplier = max(0.1, float(slot_data.get("gold_gain_multiplier", _gold_multiplier)))
    _clear_experience_orbs()
    _clear_enemy_projectiles()
    _active_elite = null
    _elite_spawn_relief_timer = 0.0
    _battle_elapsed = 0.0
    if hud.has_method("hide_boss_bar"):
        hud.call("hide_boss_bar")

    if sync_wave_manager and wave_manager != null:
        wave_manager.current_wave = wave_id
        _sync_wave_runtime_from_manager()
        EventBus.wave_started.emit(wave_id)

    for enemy: Enemy in _enemies:
        if enemy != null and is_instance_valid(enemy):
            enemy.set_target(_player)

    _refresh_player_hud()

func _estimate_legacy_attack_bonus_from_stats(player_stats: Dictionary) -> int:
    var conversion: float = _get_attack_flat_to_global_attack_percent()
    if conversion <= 0.0:
        return 0
    var global_attack_percent: float = float(player_stats.get("global_attack_percent", 0.0))
    return int(round(global_attack_percent / conversion))

func _get_attack_flat_to_global_attack_percent() -> float:
    var combat_params: Dictionary = BalanceService.get_global_combat_params()
    return max(
        0.0,
        float(combat_params.get("attack_flat_to_global_attack_percent", ATTACK_FLAT_TO_GLOBAL_ATTACK_PERCENT_DEFAULT))
    )

func _get_crit_multiplier_to_crit_chance_ratio() -> float:
    var combat_params: Dictionary = BalanceService.get_global_combat_params()
    return max(
        0.0,
        float(combat_params.get("crit_multiplier_to_crit_chance_ratio", CRIT_MULTIPLIER_TO_CRIT_CHANCE_RATIO_DEFAULT))
    )

func _migrate_legacy_crit_multiplier_stat(raw_stats: Dictionary, character_id: String) -> Dictionary:
    var migrated: Dictionary = raw_stats.duplicate(true)
    if not migrated.has("crit_multiplier"):
        return migrated
    var profile: Dictionary = BalanceService.get_character_profile(character_id)
    var base_crit_multiplier: float = max(1.0, float(profile.get("crit_multiplier", 1.5)))
    var legacy_crit_multiplier: float = max(1.0, float(migrated.get("crit_multiplier", base_crit_multiplier)))
    var delta: float = legacy_crit_multiplier - base_crit_multiplier
    if absf(delta) > 0.0001:
        var current_crit_chance: float = float(migrated.get("crit_chance", _player.crit_chance if _player != null else 0.05))
        migrated["crit_chance"] = current_crit_chance + delta * _get_crit_multiplier_to_crit_chance_ratio()
    migrated.erase("crit_multiplier")
    return migrated

func _extract_character_array(raw_value: Variant) -> Array[String]:
    var result: Array[String] = []
    if raw_value is Array:
        var raw_array: Array = raw_value
        for item: Variant in raw_array:
            var character_id: String = str(item)
            if character_id.is_empty():
                continue
            if not result.has(character_id):
                result.append(character_id)
    return result

func _extract_string_array(raw_value: Variant) -> Array[String]:
    var result: Array[String] = []
    if raw_value is Array:
        var raw_array: Array = raw_value
        for item: Variant in raw_array:
            var text: String = str(item)
            if text.is_empty():
                continue
            result.append(text)
    return result

func _get_player_hp_ratio() -> float:
    if _player == null or not is_instance_valid(_player):
        return 1.0
    return clampf(float(_player.current_hp) / float(max(1, _player.max_hp)), 0.0, 1.0)

func _refresh_difficulty_modifiers() -> void :
    var difficulty_modifiers: Dictionary = GameManager.get_difficulty_modifiers()
    _enemy_hp_multiplier = max(0.1, float(difficulty_modifiers.get("enemy_hp", 1.0)))
    _enemy_damage_multiplier = max(0.1, float(difficulty_modifiers.get("enemy_damage", 1.0)))
    _spawn_interval_multiplier = max(0.1, float(difficulty_modifiers.get("spawn_interval", 1.0)))
    _xp_multiplier = max(0.1, float(difficulty_modifiers.get("xp", 1.0)))
    _gold_multiplier = max(0.1, float(difficulty_modifiers.get("gold", 1.0)))

func _apply_arena_config_from_balance(stage_id: String) -> void:
    # Load global default bounds, then allow per-stage override.
    var combat_params: Dictionary = BalanceService.get_global_combat_params()
    var resolved_extents: Vector2 = _read_half_extents(
        combat_params.get("arena_half_extents", {}),
        DEFAULT_ARENA_HALF_EXTENTS
    )

    if not stage_id.is_empty():
        var stage_profile: Dictionary = BalanceService.get_stage_profile(stage_id)
        resolved_extents = _read_half_extents(
            stage_profile.get("arena_half_extents", {}),
            resolved_extents
        )

    # Minimum guard prevents invalid tiny maps from broken data.
    _arena_half_extents = Vector2(
        max(40.0, resolved_extents.x),
        max(40.0, resolved_extents.y)
    )
    _update_camera_limits()
    queue_redraw()

func _apply_enemy_mix_from_balance(stage_id: String) -> void:
    var stage_profile: Dictionary = BalanceService.get_stage_profile(stage_id)
    var enemy_mix: Dictionary = stage_profile.get("enemy_mix", {})

    var ranged_weight: float = float(enemy_mix.get("ranged_weight", ENEMY_RANGED_WEIGHT))
    var barrage_weight: float = float(enemy_mix.get("barrage_weight", ENEMY_BARRAGE_WEIGHT))
    ranged_weight = clampf(ranged_weight, 0.0, 1.0)
    barrage_weight = clampf(barrage_weight, 0.0, 1.0)

    # Prevent overflow so melee always has room in the spawn pool.
    var combined: float = ranged_weight + barrage_weight
    if combined > 0.95:
        var weight_scale: float = 0.95 / combined
        ranged_weight *= weight_scale
        barrage_weight *= weight_scale

    _enemy_ranged_weight_runtime = ranged_weight
    _enemy_barrage_weight_runtime = barrage_weight

func _apply_stage_runtime_from_balance(stage_id: String) -> void:
    var stage_profile: Dictionary = BalanceService.get_stage_profile(stage_id)
    _stage_is_boss_stage = bool(stage_profile.get("is_boss_stage", false))
    _stage_background_key = str(stage_profile.get("background_key", "")).to_lower()
    _apply_elite_schedule_from_stage_profile(stage_profile)
    _enemy_hp_stage_multiplier = clampf(float(stage_profile.get("enemy_hp_multiplier", 1.0)), 0.1, 3.0)
    _enemy_move_speed_stage_multiplier = clampf(
        float(stage_profile.get("enemy_move_speed_multiplier", 1.0)),
        0.1,
        3.0
    )
    var wave_profile: Dictionary = {}
    if wave_manager != null and wave_manager.has_method("get_current_wave_definition"):
        wave_profile = wave_manager.get_current_wave_definition()
    _stage_target_duration = _resolve_stage_duration_runtime(stage_id, stage_profile, wave_profile)
    _wave_duration_runtime = _stage_target_duration
    _apply_arena_size_from_background_texture()
    queue_redraw()

func _apply_elite_schedule_from_stage_profile(stage_profile: Dictionary) -> void:
    var elite_schedule_value: Variant = stage_profile.get("elite_schedule", {})
    if not (elite_schedule_value is Dictionary):
        _elite_schedule_enabled = false
        _next_elite_spawn_time = INF
        _elite_respawn_check_interval_runtime = ELITE_RESPAWN_CHECK_INTERVAL
        _elite_max_alive_runtime = 1
        _elite_hp_override_runtime = 0
        return
    var elite_schedule: Dictionary = elite_schedule_value
    _elite_schedule_enabled = bool(elite_schedule.get("enabled", false))
    if not _elite_schedule_enabled:
        _next_elite_spawn_time = INF
        _elite_respawn_check_interval_runtime = ELITE_RESPAWN_CHECK_INTERVAL
        _elite_max_alive_runtime = 1
        _elite_hp_override_runtime = 0
        return
    _next_elite_spawn_time = max(0.0, float(elite_schedule.get("first_spawn_time", ELITE_FIRST_SPAWN_TIME)))
    _elite_respawn_check_interval_runtime = max(
        1.0,
        float(elite_schedule.get("respawn_check_interval", ELITE_RESPAWN_CHECK_INTERVAL))
    )
    _elite_max_alive_runtime = max(1, int(elite_schedule.get("max_alive", 1)))
    _elite_hp_override_runtime = max(0, int(elite_schedule.get("elite_hp_override", 0)))

func _sync_wave_runtime_from_manager() -> void:
    if wave_manager == null:
        return
    _wave_progress_index = max(0, int(wave_manager.current_wave) - 1)
    var wave_profile: Dictionary = wave_manager.get_current_wave_definition()
    var stage_profile: Dictionary = BalanceService.get_stage_profile(GameManager.current_stage_id)
    _wave_duration_runtime = _resolve_stage_duration_runtime(GameManager.current_stage_id, stage_profile, wave_profile)
    _stage_target_duration = _wave_duration_runtime
    _wave_elapsed = 0.0
    _stage_clear_triggered = false
    GameManager.current_wave = max(1, int(wave_manager.current_wave))

func _resolve_stage_duration_runtime(stage_id: String, stage_profile: Dictionary, wave_profile: Dictionary) -> float:
    if _stage_is_boss_stage:
        var boss_duration: float = max(1.0, float(wave_profile.get("duration", 0.0)))
        if boss_duration > 0.0:
            return boss_duration
        var boss_spawn_profile: Dictionary = stage_profile.get("spawn_profile", {})
        return max(1.0, float(boss_spawn_profile.get("target_duration", STAGE_TIMER_MAX_SECONDS)))

    var combat_params: Dictionary = BalanceService.get_global_combat_params()
    var timer_profile: Dictionary = {}
    var timer_profile_value: Variant = combat_params.get("stage_timer", {})
    if timer_profile_value is Dictionary:
        timer_profile = timer_profile_value

    var base_duration: float = max(1.0, float(timer_profile.get("base_duration", STAGE_TIMER_BASE_SECONDS)))
    var growth_per_stage: float = max(0.0, float(timer_profile.get("duration_per_stage", STAGE_TIMER_GROWTH_SECONDS)))
    var duration_cap: float = max(base_duration, float(timer_profile.get("max_duration", STAGE_TIMER_MAX_SECONDS)))
    var stage_no: int = _extract_stage_number(stage_id)
    var computed_duration: float = base_duration + float(max(0, stage_no - 1)) * growth_per_stage
    computed_duration = clampf(computed_duration, base_duration, duration_cap)

    var stage_override: float = max(0.0, float(stage_profile.get("duration_override", 0.0)))
    if stage_override > 0.0:
        computed_duration = min(duration_cap, stage_override)

    var wave_duration: float = max(0.0, float(wave_profile.get("duration", 0.0)))
    if wave_duration > 0.0:
        computed_duration = max(computed_duration, min(duration_cap, wave_duration))
    return max(1.0, computed_duration)

func _extract_stage_number(stage_id: String) -> int:
    if not stage_id.begins_with("stage_"):
        return 1
    var suffix: String = stage_id.substr(6)
    if suffix.is_empty():
        return 1
    var stage_no: int = int(suffix)
    if stage_no <= 0:
        return 1
    return stage_no

func _build_wave_runtime_snapshot() -> Dictionary:
    _refresh_weapon_tag_state_runtime(false)
    var snapshot: Dictionary = _build_runtime_save_payload()
    snapshot["stage_id"] = GameManager.current_stage_id
    snapshot["wave"] = max(1, int(wave_manager.current_wave))
    snapshot["wave_progress_index"] = _wave_progress_index
    snapshot["current_gold"] = _current_gold_runtime
    snapshot["shop_runtime_state"] = _shop_runtime_state.duplicate(true)
    return snapshot

func _normalize_shop_runtime_state(raw_state: Variant) -> Dictionary:
    var normalized: Dictionary = {
        "equipped_weapons": [],
        "inventory_overflow": [],
        "locked_shop_offers": [],
        "refresh_count": 0,
        "shop_locked": false,
        "owned_items": [],
        "weapon_tag_state": {},
    }
    if raw_state is Dictionary:
        var source: Dictionary = raw_state
        var equipped: Variant = source.get("equipped_weapons", [])
        if equipped is Array:
            normalized["equipped_weapons"] = equipped.duplicate(true)
        var overflow: Variant = source.get("inventory_overflow", [])
        if overflow is Array:
            normalized["inventory_overflow"] = overflow.duplicate(true)
        var locked: Variant = source.get("locked_shop_offers", [])
        if locked is Array:
            normalized["locked_shop_offers"] = locked.duplicate(true)
        var owned_items: Variant = source.get("owned_items", [])
        if owned_items is Array:
            normalized["owned_items"] = owned_items.duplicate(true)
        var weapon_tag_state_raw: Variant = source.get("weapon_tag_state", {})
        if weapon_tag_state_raw is Dictionary:
            normalized["weapon_tag_state"] = (weapon_tag_state_raw as Dictionary).duplicate(true)
        normalized["refresh_count"] = max(0, int(source.get("refresh_count", 0)))
        normalized["shop_locked"] = false
    else:
        normalized["shop_locked"] = false
    return normalized

func _extract_weapon_list_from_shop_state(shop_state: Dictionary) -> Array:
    var equipped: Variant = shop_state.get("equipped_weapons", [])
    if equipped is Array:
        return equipped.duplicate(true)
    return []

func _extract_locked_offer_list_from_shop_state(shop_state: Dictionary) -> Array:
    var locked: Variant = shop_state.get("locked_shop_offers", [])
    if locked is Array:
        return locked.duplicate(true)
    return []

func _ensure_starter_weapon_equipped() -> void:
    if _selected_starter_weapon_id_runtime.is_empty():
        _selected_starter_weapon_id_runtime = GameManager.selected_starter_weapon_id
    if _selected_starter_weapon_id_runtime.is_empty():
        _selected_starter_weapon_id_runtime = _resolve_default_starter_weapon_id()
    if _selected_starter_weapon_id_runtime.is_empty():
        _refresh_weapon_tag_state_runtime(false)
        return
    GameManager.selected_starter_weapon_id = _selected_starter_weapon_id_runtime

    var equipped: Array = _normalize_equipped_weapon_slots(_shop_runtime_state.get("equipped_weapons", []))
    var slot0: Variant = equipped[0] if not equipped.is_empty() else {}
    var slot0_has_weapon: bool = slot0 is Dictionary and not str((slot0 as Dictionary).get("weapon_id", "")).is_empty()
    if slot0_has_weapon:
        _shop_runtime_state["equipped_weapons"] = equipped
        _sync_weapon_cooldowns_with_equipped_slots()
        _refresh_weapon_tag_state_runtime(false)
        return
    var starter_weapon: Dictionary = _build_weapon_instance_by_id(_selected_starter_weapon_id_runtime)
    if starter_weapon.is_empty():
        _shop_runtime_state["equipped_weapons"] = equipped
        _sync_weapon_cooldowns_with_equipped_slots()
        _refresh_weapon_tag_state_runtime(false)
        return
    equipped[0] = starter_weapon
    _shop_runtime_state["equipped_weapons"] = equipped
    _sync_weapon_cooldowns_with_equipped_slots()
    _refresh_weapon_tag_state_runtime(false)

func _get_primary_weapon_runtime() -> Dictionary:
    var equipped: Array = _normalize_equipped_weapon_slots(_shop_runtime_state.get("equipped_weapons", []))
    for slot_value: Variant in equipped:
        if not (slot_value is Dictionary):
            continue
        var weapon: Dictionary = slot_value
        if str(weapon.get("weapon_id", "")).is_empty():
            continue
        return weapon
    return _build_weapon_instance_by_id(_selected_starter_weapon_id_runtime)

func _resolve_attack_profile(weapon: Dictionary) -> Dictionary:
    var weapon_id: String = str(weapon.get("weapon_id", ""))
    if weapon.has("attack_profile") and weapon.get("attack_profile", {}) is Dictionary:
        return weapon.get("attack_profile", {}).duplicate(true)
    if DEFAULT_WEAPON_ATTACK_PROFILES.has(weapon_id):
        return DEFAULT_WEAPON_ATTACK_PROFILES[weapon_id].duplicate(true)
    return {
        "mode": "ranged_homing",
        "base_damage": AUTO_ATTACK_BASE_DAMAGE,
        "interval": AUTO_ATTACK_INTERVAL,
        "range": 320.0,
        "projectile_speed": BULLET_SPEED,
        "projectile_radius": 4.0,
    }

func _build_weapon_instance_by_id(weapon_id: String) -> Dictionary:
    if weapon_id.is_empty():
        return {}
    var catalog_weapon: Dictionary = _get_weapon_catalog_entry(weapon_id)
    if catalog_weapon.is_empty():
        return {}
    var attack_profile: Dictionary = catalog_weapon.get("attack_profile", {})
    if attack_profile.is_empty() and DEFAULT_WEAPON_ATTACK_PROFILES.has(weapon_id):
        attack_profile = DEFAULT_WEAPON_ATTACK_PROFILES[weapon_id].duplicate(true)
    return {
        "weapon_id": weapon_id,
        "rarity": "common",
        "level": 1,
        "tags": catalog_weapon.get("tags", []),
        "build_tags": catalog_weapon.get("build_tags", []),
        "effects": catalog_weapon.get("effects", {}),
        "stack_key": str(catalog_weapon.get("stack_key", weapon_id)),
        "attack_profile": attack_profile.duplicate(true),
    }

func _ensure_shop_system_runtime() -> void:
    if _shop_system_runtime != null:
        return
    _shop_system_runtime = ShopSystemScript.new() as ShopSystem
    _shop_system_runtime.setup(BalanceService.get_shop_catalog())

func _refresh_weapon_tag_state_runtime(apply_effects: bool = true) -> void:
    _ensure_shop_system_runtime()
    if _shop_system_runtime == null:
        return
    _shop_runtime_state = _normalize_shop_runtime_state(_shop_runtime_state)
    var tag_state: Dictionary = _shop_system_runtime.resolve_weapon_tag_state(_shop_runtime_state)
    _shop_runtime_state["weapon_tag_state"] = tag_state
    if apply_effects:
        _apply_weapon_tag_effects_runtime(tag_state)

func _apply_weapon_tag_effects_runtime(tag_state: Dictionary) -> void:
    if _player == null or not is_instance_valid(_player):
        return
    _clear_applied_weapon_tag_effects()
    if not bool(tag_state.get("enabled", false)):
        return
    var effects_raw: Variant = tag_state.get("preview_effects", [])
    if not (effects_raw is Array):
        return
    var effects: Array = effects_raw
    for effect_value: Variant in effects:
        if not (effect_value is Dictionary):
            continue
        var effect: Dictionary = (effect_value as Dictionary).duplicate(true)
        var effect_type: String = str(effect.get("type", "")).strip_edges()
        if effect_type.is_empty():
            continue
        if not WEAPON_TAG_ADDITIVE_EFFECT_TYPES.has(effect_type) and not WEAPON_TAG_MULTIPLIER_EFFECT_TYPES.has(effect_type):
            continue
        var effect_amount: Variant = effect.get("value", 0)
        if _player.apply_effect(effect_type, effect_amount):
            _weapon_tag_applied_effects.append(
                {
                    "type": effect_type,
                    "value": effect_amount,
                }
            )

func _clear_applied_weapon_tag_effects() -> void:
    if _player == null or not is_instance_valid(_player):
        _weapon_tag_applied_effects.clear()
        return
    for i: int in range(_weapon_tag_applied_effects.size() - 1, -1, -1):
        var effect: Dictionary = _weapon_tag_applied_effects[i]
        _apply_inverse_weapon_tag_effect(effect)
    _weapon_tag_applied_effects.clear()

func _apply_inverse_weapon_tag_effect(effect: Dictionary) -> void:
    var effect_type: String = str(effect.get("type", "")).strip_edges()
    if effect_type.is_empty():
        return
    if WEAPON_TAG_ADDITIVE_EFFECT_TYPES.has(effect_type):
        _player.apply_effect(effect_type, -float(effect.get("value", 0.0)))
        return
    if not WEAPON_TAG_MULTIPLIER_EFFECT_TYPES.has(effect_type):
        return
    var value: float = float(effect.get("value", 1.0))
    if is_zero_approx(value):
        return
    var inverse_value: float = 1.0 / value
    _player.apply_effect(effect_type, inverse_value)

func _get_weapon_catalog_entry(weapon_id: String) -> Dictionary:
    var catalog: Dictionary = BalanceService.get_shop_catalog()
    var pool_value: Variant = catalog.get("weapon_pool", [])
    if pool_value is Array:
        var pool: Array = pool_value
        for weapon_value in pool:
            if not (weapon_value is Dictionary):
                continue
            var weapon_entry: Dictionary = weapon_value
            if str(weapon_entry.get("weapon_id", "")) == weapon_id:
                return weapon_entry.duplicate(true)
    return {}

func _resolve_default_starter_weapon_id() -> String:
    var catalog: Dictionary = BalanceService.get_shop_catalog()
    var pool_value: Variant = catalog.get("weapon_pool", [])
    if pool_value is Array:
        var pool: Array = pool_value
        for weapon_value in pool:
            if not (weapon_value is Dictionary):
                continue
            var weapon_entry: Dictionary = weapon_value
            if not bool(weapon_entry.get("starter", false)):
                continue
            var weapon_id: String = str(weapon_entry.get("weapon_id", ""))
            if not weapon_id.is_empty():
                return weapon_id
    return ""

func _get_stage_background_texture() -> Texture2D:
    match _stage_background_key:
        "tutorial":
            return BG_TUTORIAL_TEXTURE
        "boss":
            return BG_BOSS_TEXTURE
        "combat":
            return BG_COMBAT_TEXTURE
        _:
            # Backward-compatible fallback for old stage configs.
            if _stage_is_boss_stage:
                return BG_BOSS_TEXTURE
            if GameManager.current_stage_id == "stage_001":
                return BG_TUTORIAL_TEXTURE
            return BG_COMBAT_TEXTURE

func _apply_arena_size_from_background_texture() -> void:
    var texture: Texture2D = _get_stage_background_texture()
    if texture == null:
        return
    var texture_size: Vector2 = texture.get_size()
    if texture_size.x <= 0.0 or texture_size.y <= 0.0:
        return

    # Map size follows source image dimensions directly.
    _arena_half_extents = Vector2(
        max(40.0, texture_size.x * 0.5),
        max(40.0, texture_size.y * 0.5)
    )
    _update_camera_limits()

func _update_camera_limits() -> void:
    if _player_camera == null or not is_instance_valid(_player_camera):
        return
    var arena_rect: Rect2 = _arena_rect()
    _player_camera.limit_left = int(round(arena_rect.position.x))
    _player_camera.limit_top = int(round(arena_rect.position.y))
    _player_camera.limit_right = int(round(arena_rect.end.x))
    _player_camera.limit_bottom = int(round(arena_rect.end.y))

func _resolve_next_stage_id(current_stage_id: String) -> String:
    if current_stage_id.is_empty():
        return ""
    var stage_profile: Dictionary = BalanceService.get_stage_profile(current_stage_id)
    var config_next_stage: String = str(stage_profile.get("next_stage_id", ""))
    if not config_next_stage.is_empty() and BalanceService.has_stage_profile(config_next_stage):
        return config_next_stage

    if not current_stage_id.begins_with("stage_"):
        return ""
    var suffix: String = current_stage_id.substr(6)
    if suffix.is_empty():
        return ""
    var stage_no: int = int(suffix)
    if stage_no <= 0:
        return ""
    var inferred_next_stage_id: String = "stage_%03d" % (stage_no + 1)
    if BalanceService.has_stage_profile(inferred_next_stage_id):
        return inferred_next_stage_id
    return ""

func _read_half_extents(raw_value: Variant, fallback: Vector2) -> Vector2:
    if raw_value is Dictionary:
        var raw_dict: Dictionary = raw_value
        var x: float = float(raw_dict.get("x", fallback.x))
        var y: float = float(raw_dict.get("y", fallback.y))
        return Vector2(x, y)
    return fallback

func _tx(key: String, fallback: String = "") -> String:
    if LocaleService != null:
        return LocaleService.tx(key, fallback if not fallback.is_empty() else key)
    if fallback.is_empty():
        return key
    return fallback

func _tf(key: String, args: Array, fallback: String = "") -> String:
    if LocaleService != null:
        return LocaleService.tf(key, args, fallback if not fallback.is_empty() else key)
    var base: String = fallback if not fallback.is_empty() else key
    return base % args
