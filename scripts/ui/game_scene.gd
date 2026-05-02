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
@onready var pause_character_name_label: Label = %CharacterNameLabel
@onready var pause_character_preview: TextureRect = %CharacterPreview
@onready var pause_weapon_list: VBoxContainer = %WeaponList
@onready var pause_item_list: VBoxContainer = %ItemList
@onready var pause_stats_grid: GridContainer = %PauseStatsGrid

const PLAYER_SCRIPT_MAP: Dictionary[String, Script] = {
    "the_fool": preload("res://scripts/characters/the_fool.gd"), 
    "the_chariot": preload("res://scripts/characters/the_chariot.gd"), 
    "the_sun": preload("res://scripts/characters/the_sun.gd"), 
}
const CHARACTER_BATTLE_SHEET_PATHS: Dictionary[String, String] = {
    "the_fool": "res://sprite/characters/the_fool/battle_sheet.png",
    "the_chariot": "res://sprite/characters/the_chariot/battle_sheet.png",
    "the_sun": "res://sprite/characters/the_sun/battle_sheet.png",
}
const CHARACTER_PREVIEW_FRAME_OFFSETS: Dictionary = {
    "the_chariot": {
        0: Vector2(-4, 0),
        1: Vector2(-2, 0),
        2: Vector2(-1, 0),
        4: Vector2(1, 0),
        5: Vector2(2, 0),
        6: Vector2(4, 0),
        7: Vector2(5, 0),
    },
}
const SAVE_SLOT_PANEL_SCENE_PATH: String = "res://scenes/ui/save_slot_panel.tscn"
const SETTINGS_SCENE_PATH: String = "res://scenes/settings.tscn"
const NEON_OPTION_BUTTON_SCRIPT: Script = preload("res://scripts/ui/neon_option_button.gd")
const BG_TUTORIAL_TEXTURE: Texture2D = preload("res://sprite/maps/map_tutorial_dream_entrance.png")
const BG_COMBAT_TEXTURE: Texture2D = preload("res://sprite/maps/map_stage_combat_default.png")
const BG_BOSS_TEXTURE: Texture2D = preload("res://sprite/maps/map_stage_boss_arena.png")
const MELEE_ARC_EFFECT_SCRIPT: Script = preload("res://scripts/effects/melee_arc_effect.gd")
const MELEE_HIT_EFFECT_SCRIPT: Script = preload("res://scripts/effects/melee_hit_effect.gd")
const ELITE_CHEST_DROP_SCRIPT: Script = preload("res://scripts/entities/elite_chest_drop.gd")
const ShopSystemScript: Script = preload("res://scripts/systems/shop_system.gd")
const WEAPON_ORBIT_ICON_DIR: String = "res://sprite/weapons/generated_from_doc_v1_alpha_final_v2/"
const WEAPON_ORBIT_ICON_TARGET_WIDTH: float = 22.0
const WEAPON_ORBIT_FORWARD_OFFSET: float = 34.0
const WEAPON_ORBIT_SLOT_SPACING: float = 10.0
const WEAPON_ORBIT_FLASH_DURATION: float = 0.11
const WEAPON_ORBIT_FLASH_SCALE_MAX: float = 1.12
const WEAPON_ORBIT_BASE_TINT: Color = Color(0.86, 0.95, 1.0, 0.9)
const WEAPON_ORBIT_FLASH_TINT: Color = Color(1.0, 1.0, 1.0, 1.0)
const WEAPON_ORBIT_ROTATION_SPEED: float = 0.6
const WEAPON_ORBIT_SMOOTHING_SPEED: float = 16.0
const WEAPON_ORBIT_MUZZLE_OFFSET: float = 16.0
const MELEE_ATTACK_FAMILY_BY_WEAPON_ID: Dictionary = {
    "kunai": "thrust",
    "rebar_spear": "thrust",
    "steel_pipe": "sweep",
    "chain_whip": "sweep",
    "road_sign": "heavy",
    "traffic_cone": "heavy",
    "heavy_wrench": "heavy",
    "meteor_hammer": "heavy",
}
const MELEE_ATTACK_ACTIVE_Z_INDEX: int = 20
const MELEE_ATTACK_BASE_TINT: Color = Color(0.88, 0.97, 1.0, 0.96)
const MELEE_ATTACK_FLASH_TINT: Color = Color(1.0, 1.0, 1.0, 1.0)
const MELEE_ATTACK_ASSET_FORWARD_ANGLE_BY_WEAPON_ID: Dictionary = {
    "kunai": -0.92,
    "rebar_spear": -0.88,
    "steel_pipe": -0.88,
    "chain_whip": 0.36,
    "road_sign": -0.86,
    "traffic_cone": -0.9,
    "heavy_wrench": -0.92,
    "meteor_hammer": -2.45,
}
const MELEE_ATTACK_ALIGNMENT_BY_FAMILY: Dictionary = {
    "thrust": {
        "tip_forward_ratio": 0.96,
        "grip_back_ratio": 0.34,
        "lateral_offset": 0.0,
        "melee_rotation_offset": PI,
    },
    "sweep": {
        "tip_forward_ratio": 0.82,
        "grip_back_ratio": 0.42,
        "lateral_offset": 0.0,
        "melee_rotation_offset": PI,
    },
    "heavy": {
        "tip_forward_ratio": 0.88,
        "grip_back_ratio": 0.5,
        "lateral_offset": 0.02,
        "melee_rotation_offset": PI,
    },
}
const MELEE_ATTACK_ALIGNMENT_BY_WEAPON_ID: Dictionary = {
    "kunai": {
        "tip_forward_ratio": 1.08,
        "grip_back_ratio": 0.24,
        "lateral_offset": 0.0,
    },
    "rebar_spear": {
        "tip_forward_ratio": 1.16,
        "grip_back_ratio": 0.22,
        "lateral_offset": 0.0,
    },
    "steel_pipe": {
        "tip_forward_ratio": 0.9,
        "grip_back_ratio": 0.36,
        "lateral_offset": -0.02,
    },
    "chain_whip": {
        "tip_forward_ratio": 1.02,
        "grip_back_ratio": 0.28,
        "lateral_offset": 0.0,
    },
    "road_sign": {
        "tip_forward_ratio": 1.02,
        "grip_back_ratio": 0.3,
        "lateral_offset": 0.08,
    },
    "traffic_cone": {
        "tip_forward_ratio": 0.94,
        "grip_back_ratio": 0.38,
        "lateral_offset": 0.06,
    },
    "heavy_wrench": {
        "tip_forward_ratio": 0.96,
        "grip_back_ratio": 0.34,
        "lateral_offset": 0.06,
    },
    "meteor_hammer": {
        "tip_forward_ratio": 1.12,
        "grip_back_ratio": 0.22,
        "lateral_offset": 0.0,
    },
}
const MELEE_CAMERA_PUNCH_DAMPING: float = 16.0
const MELEE_CAMERA_PUNCH_RETURN_SPEED: float = 22.0
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
    "hp_regen_flat": true,
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
var _melee_pressure_spawn_timer: float = 0.0
var _contact_damage_timer: float = 0.0
var _battle_elapsed: float = 0.0
var _next_elite_spawn_time: float = 60.0
var _elite_spawn_relief_timer: float = 0.0
var _elite_schedule_enabled: bool = false
var _elite_respawn_check_interval_runtime: float = 120.0
var _elite_respawn_interval_min_runtime: float = 120.0
var _elite_respawn_interval_max_runtime: float = 120.0
var _elite_max_alive_runtime: int = 1
var _elite_hp_override_runtime: int = 0
var _elite_pool_runtime: Array[Dictionary] = []
var _enemies: Array[Enemy] = []
var _projectiles: Array[Projectile] = []
var _enemy_projectiles: Array[EnemyProjectile] = []
var _pending_enemy_shots: Array[Dictionary] = []
var _experience_orbs: Array[ExperienceOrb] = []
var _consumables: Array[ConsumableDrop] = []
var _tree_spawn_timer: float = 0.0
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
var _level_reward_refresh_button: Button
var _level_reward_hint_label: Label
var _level_reward_stat_labels: Dictionary = {}
var _elite_chest_panel: PanelContainer
var _elite_chest_title: Label
var _elite_chest_icon: TextureRect
var _elite_chest_name: Label
var _elite_chest_rarity: Label
var _elite_chest_desc: RichTextLabel
var _elite_chest_claim_button: Button
var _elite_chest_recycle_button: Button
var _death_settlement_panel: PanelContainer
var _death_settlement_title: Label
var _death_settlement_subtitle: Label
var _death_settlement_value_labels: Dictionary = {}
var _death_retry_button: Button
var _death_menu_button: Button
var _endless_choice_panel: PanelContainer
var _endless_continue_button: Button
var _endless_finish_button: Button
var _level_reward_choices: Array[Dictionary] = []
var _owned_weapon_rewards: Dictionary = {}
var _reward_history_runtime: Array[String] = []
var _recent_categories_runtime: Array[String] = []
var _build_tags_runtime: Array[String] = []
var _reward_pity_state_runtime: Dictionary = {"no_output_streak": 0}
var _pending_level_up_rewards: int = 0
var _level_reward_refresh_count: int = 0
var _pending_elite_chests: int = 0
var _current_elite_chest_offer: Dictionary = {}
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
var _is_endless_mode: bool = false
var _endless_elapsed: float = 0.0
var _endless_level: int = 0
var _endless_shop_timer: float = 0.0
var _endless_base_max_enemy_count: int = 0
var _endless_shop_transitioning: bool = false
var _enemy_hp_multiplier: float = 1.0
var _enemy_hp_stage_multiplier: float = 1.0
var _enemy_move_speed_stage_multiplier: float = 1.0
var _enemy_move_speed_difficulty_multiplier: float = 1.0
var _enemy_damage_multiplier: float = 1.0
var _enemy_damage_stage_multiplier: float = 1.0
var _spawn_interval_multiplier: float = 1.0
var _enemy_count_multiplier: float = 1.0
var _xp_multiplier: float = 1.0
var _gold_multiplier: float = 1.0
var _stage_xp_drop_multiplier: float = 1.0
var _stage_gold_drop_multiplier: float = 1.0
var _run_kill_count: int = 0
var _run_survival_time_runtime: float = 0.0
var _arena_half_extents: Vector2 = Vector2(620.0, 340.0)
var _enemy_spawn_weights_runtime: Dictionary = {}
var _max_enemy_count_runtime: int = MAX_ENEMY_COUNT
var _initial_enemy_count_runtime: int = INITIAL_ENEMY_COUNT
var _enemy_min_spawn_radius_runtime: float = ENEMY_MIN_SPAWN_RADIUS
var _enemy_max_spawn_radius_runtime: float = ENEMY_MAX_SPAWN_RADIUS
var _contact_damage_runtime: int = CONTACT_DAMAGE
var _contact_damage_interval_runtime: float = CONTACT_DAMAGE_INTERVAL
var _spawn_interval_start_runtime: float = ENEMY_SPAWN_INTERVAL
var _spawn_interval_end_runtime: float = ENEMY_SPAWN_INTERVAL
var _spawn_batch_start_runtime: int = 1
var _spawn_batch_end_runtime: int = 1
var _melee_pressure_interval_start_runtime: float = MELEE_PRESSURE_INTERVAL_START
var _melee_pressure_interval_end_runtime: float = MELEE_PRESSURE_INTERVAL_END
var _melee_pressure_fast_weight_runtime: float = MELEE_PRESSURE_FAST_WEIGHT
var _melee_pressure_charger_weight_runtime: float = MELEE_PRESSURE_CHARGER_WEIGHT
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
var _weapon_targets: Dictionary = {}
var _active_melee_attacks: Dictionary = {}
var _melee_camera_punch_offset: Vector2 = Vector2.ZERO
var _melee_camera_punch_velocity: Vector2 = Vector2.ZERO
var _weapon_orbit_placeholder_texture: Texture2D
var _tarot_choice_panel: Control
var _tarot_canvas: CanvasLayer
var _tarot_card_texture_cache: Dictionary = {}
var _pause_character_preview_frames: Array[Texture2D] = []
var _pause_character_preview_time: float = 0.0
var _pause_character_preview_frame_index: int = 0
var _pending_tarot_choice: bool = false
var _intro_active: bool = false
var _pause_transition_tween: Tween
var _death_fx_layer: CanvasLayer
var _death_fx_overlay: ColorRect
var _death_fx_tween: Tween
var _shop_system_runtime: ShopSystem
var _weapon_tag_applied_effects: Array[Dictionary] = []
var _stage_retry_snapshot: Dictionary = {}

const INITIAL_ENEMY_COUNT: int = 40
const MAX_ENEMY_COUNT: int = 120
const HARD_MAX_ACTIVE_ENEMY_COUNT: int = 120
const ENEMY_SPAWN_INTERVAL: float = 0.15
const ENEMY_MIN_SPAWN_RADIUS: float = 380.0
const ENEMY_MAX_SPAWN_RADIUS: float = 620.0
const ENEMY_MELEE_WEIGHT: float = 0.67
const ENEMY_FAST_MELEE_WEIGHT: float = 0.0
const ENEMY_CHARGER_WEIGHT: float = 0.0
const ENEMY_RANGED_WEIGHT: float = 0.25
const ENEMY_BARRAGE_WEIGHT: float = 0.08
const MELEE_PRESSURE_INTERVAL_START: float = 1.35
const MELEE_PRESSURE_INTERVAL_END: float = 0.9
const MELEE_PRESSURE_FAST_WEIGHT: float = 0.32
const MELEE_PRESSURE_CHARGER_WEIGHT: float = 0.0
const MELEE_PRESSURE_MIN_INTERVAL: float = 0.45
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
        "projectile_radius": 6.0,
    },
    "nail_gun": {
        "mode": "ranged_homing",
        "base_damage": 8,
        "interval": 0.22,
        "range": 380.0,
        "projectile_speed": 620.0,
        "projectile_radius": 3.0,
    },
}
const CONTACT_DAMAGE: int = 8
const CONTACT_DAMAGE_INTERVAL: float = 0.34
const XP_CURVE_LEVEL_OFFSET_DEFAULT: int = 3
const XP_CURVE_BASE_MULT_DEFAULT: float = 1.0
const XP_REQUIRED_MIN_DEFAULT: int = 1
const ATTACK_FLAT_TO_GLOBAL_ATTACK_PERCENT_DEFAULT: float = 3.0
const CRIT_MULTIPLIER_TO_CRIT_CHANCE_RATIO_DEFAULT: float = 0.12
const HARVEST_WAVE_GOLD_PER_POINT_DEFAULT: float = 1.0
const LEVEL_UP_MAX_HP_BONUS_DEFAULT: int = 1
const LEVEL_UP_CURRENT_HP_BONUS_DEFAULT: int = 1
const REWARD_TARGET_RANGE_BONUS: float = 80.0
const REWARD_ATTACK_DAMAGE_BONUS: int = 3
const REWARD_MOVE_SPEED_BONUS: float = 15.0
const LEVEL_REWARD_CHOICES_COUNT: int = 3
const MELEE_TARGET_RANGE_BONUS_RATIO: float = 0.35
const MELEE_TARGET_RANGE_BONUS_CAP: float = 36.0
const MELEE_TARGET_RANGE_CAP: float = 150.0
const MELEE_CLOSE_HIT_EXTRA_RADIUS: float = 18.0
const MELEE_CLOSE_HIT_OMNI_EXTRA_RADIUS: float = 6.0
const MELEE_CLOSE_HIT_MIN_DOT: float = -0.15
const KNOCKBACK_DEFAULT_DURATION: float = 0.14
const AOE_KNOCKBACK_MIN_RATIO: float = 0.45
const KNOCKBACK_BY_MODE: Dictionary = {
    "melee_arc": 220.0,
    "ranged_homing": 150.0,
    "ranged_heavy": 245.0,
    "ranged_lob_aoe": 275.0,
    "ranged_bounce_weapon": 180.0,
}
const KNOCKBACK_DURATION_BY_MODE: Dictionary = {
    "melee_arc": 0.16,
    "ranged_homing": 0.14,
    "ranged_heavy": 0.17,
    "ranged_lob_aoe": 0.18,
    "ranged_bounce_weapon": 0.15,
}
const KNOCKBACK_BY_MELEE_FAMILY: Dictionary = {
    "thrust": 200.0,
    "sweep": 250.0,
    "heavy": 320.0,
}
const STAGE_TIMER_DANGER_SECONDS: int = 10
const STAGE_TIMER_BASE_SECONDS: float = 30.0
const STAGE_TIMER_GROWTH_SECONDS: float = 5.0
const STAGE_TIMER_MAX_SECONDS: float = 120.0
const PAUSE_OPEN_DURATION: float = 0.18
const PAUSE_CLOSE_DURATION: float = 0.13
const PAUSE_PANEL_POP_SCALE: float = 0.94
const PAUSE_CHARACTER_PREVIEW_FPS: float = 8.0
const PAUSE_CHARACTER_PREVIEW_FRAME_SIZE: Vector2 = Vector2(32.0, 32.0)
const DEATH_FLASH_DURATION: float = 0.12
const DEATH_FADE_DURATION: float = 0.46
const TREE_SPAWN_INTERVAL: float = 12.0
const MAX_TREE_COUNT: int = 4
const CONSUMABLE_DROP_CHANCE_BASE: float = 0.015
const ENDLESS_ENTRY_STAGE_ID: String = "stage_020"
const ENDLESS_SHOP_INTERVAL: float = 80.0
const ENDLESS_LEVEL_INTERVAL: float = 60.0
const ENDLESS_HP_PER_LEVEL: float = 0.12
const ENDLESS_DAMAGE_PER_LEVEL: float = 0.08
const ENDLESS_SPEED_PER_LEVEL: float = 0.02
const ENDLESS_SPEED_MULT_CAP: float = 1.6
const ENDLESS_SPAWN_INTERVAL_REDUCTION_PER_LEVEL: float = 0.04
const ENDLESS_MIN_SPAWN_INTERVAL: float = 0.18
const ENDLESS_MAX_ENEMY_COUNT_PER_LEVEL: int = 6
const ENDLESS_MAX_ENEMY_COUNT_CAP: int = HARD_MAX_ACTIVE_ENEMY_COUNT
const ENDLESS_ELITE_FIRST_SPAWN_MIN: float = 25.0
const ENDLESS_ELITE_FIRST_SPAWN_MAX: float = 45.0
const ENDLESS_ELITE_RESPAWN_MIN: float = 45.0
const ENDLESS_ELITE_RESPAWN_MAX: float = 90.0
const ENDLESS_ELITE_MAX_ALIVE: int = 2
const ENDLESS_ELITE_BASE_HP: int = 60000
const ENDLESS_ELITE_HP_ENRAGE_MIN: float = 1.15
const ENDLESS_ELITE_HP_ENRAGE_MAX: float = 1.45
const ENDLESS_ELITE_DAMAGE_ENRAGE_MIN: float = 1.08
const ENDLESS_ELITE_DAMAGE_ENRAGE_MAX: float = 1.25
const ENDLESS_ELITE_SPEED_ENRAGE_MIN: float = 1.0
const ENDLESS_ELITE_SPEED_ENRAGE_MAX: float = 1.12

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
    _set_combat_simulation_active(false)
    _ensure_shop_system_runtime()
    if not pending_slot_data.is_empty():
        _apply_loaded_slot_data(pending_slot_data, false)
    _ensure_starter_weapon_equipped()
    _refresh_weapon_tag_state_runtime(true)
    _sync_weapon_orbit_visuals(true)
    if wave_manager != null:
        wave_manager.load_stage_balance(GameManager.current_stage_id)
    _sync_wave_runtime_from_manager()
    _apply_stage_runtime_from_balance(GameManager.current_stage_id)
    _ensure_tarot_choice_panel()
    if state_label != null:
        state_label.visible = false
        state_label.modulate = Color(0.82, 0.96, 1.0, 0.95)
    else:
        push_warning("Stage timer label not found. Expected HUD#StateLabel or HUD/StateLabel.")
    _bind_pause_menu()
    _prepare_pause_sub_scenes()
    _create_pause_sub_panels()
    _set_pause_overlay_visible(false)
    _capture_stage_retry_snapshot()
    _play_battle_intro()

func _play_battle_intro() -> void:
    _intro_active = true
    get_tree().paused = true
    
    var intro_canvas = CanvasLayer.new()
    intro_canvas.layer = 200
    intro_canvas.process_mode = Node.PROCESS_MODE_ALWAYS
    add_child(intro_canvas)
    
    var bg = ColorRect.new()
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    bg.color = Color(0.05, 0.05, 0.08, 0.85)
    intro_canvas.add_child(bg)
    
    var label = Label.new()
    label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    label.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VerticalAlignment.VERTICAL_ALIGNMENT_CENTER
    label.text = _tx("ui.game_scene.intro_ready", "READY")
    label.add_theme_font_size_override("font_size", 80)
    label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
    label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
    label.add_theme_constant_override("outline_size", 12)
    intro_canvas.add_child(label)
    
    # Wait one frame for sizes to initialize before setting pivot
    await get_tree().process_frame
    label.pivot_offset = label.size / 2.0
    label.scale = Vector2(0.1, 0.1)
    
    var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
    tween.tween_property(label, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tween.tween_interval(0.6)
    tween.tween_callback(func():
        label.text = _tx("ui.game_scene.intro_fight", "FIGHT!")
        label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
        label.scale = Vector2(1.5, 1.5)
    )
    tween.tween_property(label, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
    tween.tween_interval(0.4)
    tween.tween_property(bg, "modulate:a", 0.0, 0.3)
    tween.parallel().tween_property(label, "modulate:a", 0.0, 0.3)
    tween.tween_callback(func():
        intro_canvas.queue_free()
        _intro_active = false
        _set_combat_simulation_active(true)
        get_tree().paused = false
        _spawn_initial_enemies()
        wave_manager.start_stage()
    )

func _reset_progress_state() -> void :
    _current_level = 1
    _current_xp = 0
    _xp_required_multiplier_runtime = _resolve_character_xp_required_multiplier(_current_player_id)
    _xp_to_next_level = _xp_required_for_level(_current_level)
    _pending_level_up_rewards = 0
    _pending_elite_chests = 0
    _current_elite_chest_offer = {}
    _reward_opened = false
    _wave_end_reward_gate_active = false
    _pending_wave_shop_snapshot = {}
    _battle_elapsed = 0.0
    _run_kill_count = 0
    _run_survival_time_runtime = 0.0
    _wave_elapsed = 0.0
    _enemy_spawn_timer = 0.0
    _melee_pressure_spawn_timer = 0.0
    _wave_duration_runtime = 30.0
    _wave_progress_index = 0
    _spawn_batch_start_runtime = 1
    _spawn_batch_end_runtime = 1
    _stage_clear_triggered = false
    _is_endless_mode = false
    _endless_elapsed = 0.0
    _endless_level = 0
    _endless_shop_timer = 0.0
    _endless_base_max_enemy_count = 0
    _endless_shop_transitioning = false
    _next_elite_spawn_time = ELITE_FIRST_SPAWN_TIME
    _elite_spawn_relief_timer = 0.0
    _elite_schedule_enabled = false
    _elite_respawn_check_interval_runtime = ELITE_RESPAWN_CHECK_INTERVAL
    _elite_respawn_interval_min_runtime = ELITE_RESPAWN_CHECK_INTERVAL
    _elite_respawn_interval_max_runtime = ELITE_RESPAWN_CHECK_INTERVAL
    _elite_max_alive_runtime = 1
    _elite_hp_override_runtime = 0
    _elite_pool_runtime = []
    _active_elite = null
    _owned_weapon_rewards = {}
    _reward_history_runtime = []
    _recent_categories_runtime = []
    _build_tags_runtime = []
    _reward_pity_state_runtime = {"no_output_streak": 0}
    _level_reward_choices = []
    _level_reward_refresh_count = 0
    _auto_attack_interval_multiplier_runtime = 1.0
    _weapon_cooldowns.clear()
    _weapon_cooldown_signatures.clear()
    _weapon_tag_applied_effects.clear()
    _weapon_targets.clear()
    _clear_active_melee_attacks()
    _reset_melee_camera_punch()
    _tarot_completed_for_wave = false
    _pending_tarot_choice = false
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
    _tick_pause_character_preview(delta)
    if _is_game_over or _reward_opened or _intro_active:
        return
    if GameManager.current_state != GameManager.GameState.PLAYING:
        return
    _battle_elapsed += delta
    _wave_elapsed += delta
    if _is_endless_mode:
        _endless_elapsed += delta
        _endless_shop_timer += delta
        _refresh_endless_level()
    _update_stage_timer(delta)
    if _stage_clear_triggered:
        return
    _enemy_spawn_timer += delta
    _melee_pressure_spawn_timer += delta
    _contact_damage_timer = max(0.0, _contact_damage_timer - delta)
    _elite_spawn_relief_timer = max(0.0, _elite_spawn_relief_timer - delta)

    # Interpolate spawn interval by wave progress.
    var progress_ratio: float = 0.0
    if _is_endless_mode:
        progress_ratio = 1.0
    elif _wave_duration_runtime > 0.0:
        progress_ratio = clampf(_wave_elapsed / _wave_duration_runtime, 0.0, 1.0)
    
    var base_spawn_interval: float = lerpf(_spawn_interval_start_runtime, _spawn_interval_end_runtime, progress_ratio)
    var spawn_interval: float = base_spawn_interval * _spawn_interval_multiplier
    if _is_endless_mode:
        spawn_interval *= _get_endless_spawn_interval_multiplier()
        spawn_interval = max(ENDLESS_MIN_SPAWN_INTERVAL, spawn_interval)
    
    if _elite_spawn_relief_timer > 0.0:
        spawn_interval *= ELITE_SPAWN_RELIEF_MULTIPLIER

    if _enemy_spawn_timer >= spawn_interval:
        _enemy_spawn_timer = 0.0
        var spawn_batch_count: int = max(1, int(round(lerpf(
            float(_spawn_batch_start_runtime),
            float(_spawn_batch_end_runtime),
            progress_ratio
        ))))
        _try_spawn_enemy_batch(spawn_batch_count)

    var melee_pressure_interval: float = lerpf(_melee_pressure_interval_start_runtime, _melee_pressure_interval_end_runtime, progress_ratio)
    melee_pressure_interval *= _spawn_interval_multiplier
    if _is_endless_mode:
        melee_pressure_interval *= _get_endless_spawn_interval_multiplier()
    melee_pressure_interval = max(MELEE_PRESSURE_MIN_INTERVAL, melee_pressure_interval)
    if _elite_spawn_relief_timer > 0.0:
        melee_pressure_interval *= ELITE_SPAWN_RELIEF_MULTIPLIER
    if _melee_pressure_spawn_timer >= melee_pressure_interval:
        _melee_pressure_spawn_timer = 0.0
        _try_spawn_melee_pressure_enemy()

    _try_spawn_elite_by_schedule()
    _tick_equipped_weapon_attacks(delta)
    _tick_active_melee_attacks(delta)
    _tick_melee_camera_punch(delta)
    _tick_weapon_orbit_visuals(delta)
    _handle_projectile_hits()
    _flush_pending_enemy_shots()
    _handle_enemy_projectile_hits()
    _handle_enemy_contact_damage()
    _update_experience_orbs(delta)
    _update_consumables(delta)
    _update_tree_spawning(delta)
    _cleanup_dead_projectiles()
    _cleanup_dead_enemy_projectiles()
    _cleanup_dead_experience_orbs()
    _cleanup_dead_consumables()
    _update_elite_boss_bar()
    _constrain_actor_positions_to_arena()
    _refresh_player_hud()

func _unhandled_input(event: InputEvent) -> void :
    if not event.is_action_pressed("pause"):
        return
    if _intro_active:
        get_viewport().set_input_as_handled()
        return
    if _is_game_over:
        return
    if _wave_end_reward_gate_active:
        if _pending_elite_chests > 0:
            if _elite_chest_panel != null and not _elite_chest_panel.visible:
                _show_elite_chest_panel()
            return
        if _pending_level_up_rewards > 0:
            if _level_reward_panel != null and not _level_reward_panel.visible:
                _show_level_reward_panel()
            return
    if _reward_opened:
        _show_active_reward_panel()
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
    _clear_active_melee_attacks()
    _reset_melee_camera_punch()
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
    if _elite_chest_panel != null:
        _elite_chest_panel.visible = false
    _death_settlement_panel.visible = true

    var stage_text: String = "ENDLESS" if _is_endless_mode else GameManager.current_stage_id
    var survive_text: String = _format_elapsed_time(_run_survival_time_runtime + _battle_elapsed)
    if _death_settlement_title != null:
        _death_settlement_title.text = _tx("ui.game_over.defeat_title", "Defeat")
    if _death_settlement_subtitle != null:
        _death_settlement_subtitle.text = _tx("ui.game_scene.death_subtitle", "Signal interrupted, battle report generated.")
    _set_death_settlement_value("stage", stage_text)
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
    if _is_endless_mode:
        hud.call("set_stage_timer", true, _format_endless_timer_text(), Color(0.72, 1.0, 0.86, 0.98))
        if _endless_shop_timer >= ENDLESS_SHOP_INTERVAL and not _endless_shop_transitioning:
            _trigger_endless_shop()
        return
    if _wave_duration_runtime <= 0.0:
        hud.call("set_stage_timer", false)
        return
    var remain: float = max(0.0, _wave_duration_runtime - _wave_elapsed)
    var timer_tint: Color = _update_stage_timer_color(remain)
    hud.call("set_stage_timer", true, _format_stage_timer_text(remain), timer_tint)
    if remain <= 0.0:
        _on_wave_time_up()

func _format_stage_timer_text(remain: float) -> String:
    var stage_number: int = _extract_stage_number(GameManager.current_stage_id)
    var stage_text: String = "STAGE %02d" % max(1, stage_number)
    return "%s  %s" % [stage_text, _format_stage_countdown(remain)]

func _format_endless_timer_text() -> String:
    return "ENDLESS  %s" % _format_elapsed_time(_endless_elapsed)

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
    _pending_tarot_choice = false
    _tarot_completed_for_wave = false
    _pause_opened = false
    _reward_opened = false
    _wave_end_reward_gate_active = false
    _pending_wave_shop_snapshot = {}
    get_tree().paused = false
    _set_pause_overlay_visible(false)
    _set_combat_simulation_active(false)
    
    # 鏀硅繘锛氫笉鍐嶄粎渚濊禆鏁扮粍锛岃€屾槸鎵弿鍦烘櫙涓墍鏈夌殑 ExperienceOrb 鑺傜偣锛岀‘淇濇棤閬楁紡
    var orbs_to_animate: Array[ExperienceOrb] = []
    for child in get_children():
        if child is ExperienceOrb and is_instance_valid(child):
            orbs_to_animate.append(child)
    
    if orbs_to_animate.size() > 0:
        await _animate_orbs_to_bag(orbs_to_animate)
    
    # NEW: Automatically consume remaining healing items at end of wave
    for drop in _consumables:
        if drop != null and is_instance_valid(drop):
            if _player != null:
                var healed = _player.heal(drop.heal_amount)
                if healed > 0:
                    _spawn_heal_hint(_player.global_position, healed)
            drop.queue_free()
    _consumables.clear()
    
    _clear_experience_orbs()
    _clear_all_enemies()
    _add_gold(_resolve_wave_harvest_gold())
    _add_experience(_resolve_wave_harvest_xp())
    _apply_harvest_growth()
    if GameManager != null and GameManager.has_method("clear_stage_drop_double_active"):
        GameManager.call("clear_stage_drop_double_active")
    
    var next_stage_id: String = _resolve_next_stage_id(GameManager.current_stage_id)
    if next_stage_id.is_empty():
        if GameManager.current_stage_id == ENDLESS_ENTRY_STAGE_ID and not _is_endless_mode:
            _show_endless_choice_panel()
            return
        _stage_clear_triggered = false
        _complete_stage_by_timer()
        return
    var shop_snapshot: Dictionary = _build_wave_runtime_snapshot()
    shop_snapshot["stage_id"] = GameManager.current_stage_id
    shop_snapshot["wave"] = 1
    shop_snapshot["wave_progress_index"] = 0
    shop_snapshot["player_pos_x"] = 0.0
    shop_snapshot["player_pos_y"] = 0.0
    _begin_wave_end_reward_then_shop(shop_snapshot)

func _begin_wave_end_reward_then_shop(shop_snapshot: Dictionary) -> void:
    _wave_end_reward_gate_active = true
    _pending_wave_shop_snapshot = shop_snapshot.duplicate(true)
    
    # NEW: Tarot Choice comes first
    if not _tarot_completed_for_wave:
        _show_tarot_choice_panel()
        return

    if _pending_elite_chests > 0:
        _show_elite_chest_panel()
        return
        
    if _pending_level_up_rewards > 0:
        _try_open_next_level_reward()
        if _reward_opened:
            return
    _open_shop_after_wave_reward()

func _ensure_tarot_choice_panel() -> void:
    if _tarot_canvas != null:
        return
    
    _tarot_canvas = CanvasLayer.new()
    _tarot_canvas.layer = 120
    _tarot_canvas.process_mode = Node.PROCESS_MODE_ALWAYS
    add_child(_tarot_canvas)
    
    _tarot_choice_panel = Control.new()
    _tarot_choice_panel.name = "TarotChoicePanel"
    _tarot_choice_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _tarot_choice_panel.visible = false
    _tarot_canvas.add_child(_tarot_choice_panel)
    
    var bg = ColorRect.new()
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    bg.color = Color(0.07, 0.09, 0.11, 0.98) # Matches ShopScene background
    bg.mouse_filter = Control.MOUSE_FILTER_STOP
    _tarot_choice_panel.add_child(bg)
    
    var center_container = CenterContainer.new()
    center_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _tarot_choice_panel.add_child(center_container)
    
    var v_box = VBoxContainer.new()
    v_box.add_theme_constant_override("separation", 32)
    center_container.add_child(v_box)
    
    var title = Label.new()
    title.text = _tx("ui.tarot.choice_title", "SELECT YOUR FATE")
    title.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 32)
    title.add_theme_color_override("font_color", Color(0.96, 0.86, 0.67, 1.0)) # Matches Boss HUD
    title.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
    title.add_theme_constant_override("outline_size", 8)
    v_box.add_child(title)
    
    var h_box = HBoxContainer.new()
    h_box.alignment = BoxContainer.ALIGNMENT_CENTER
    h_box.add_theme_constant_override("separation", 24)
    v_box.add_child(h_box)
    
    _tarot_choice_panel.set_meta("h_box", h_box)

func _show_tarot_choice_panel() -> void:
    _ensure_tarot_choice_panel()
    _reward_opened = true
    get_tree().paused = true
    
    var h_box: HBoxContainer = _tarot_choice_panel.get_meta("h_box")
    
    for child in h_box.get_children():
        child.queue_free()
        
    var cards: Array[String] = TarotSystem.get_random_choices(3)
    for card_id in cards:
        var card_data: Dictionary = TarotSystem.CARDS[card_id]
        var option_box: VBoxContainer = VBoxContainer.new()
        option_box.custom_minimum_size = Vector2(300, 520)
        option_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        option_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
        option_box.alignment = BoxContainer.ALIGNMENT_CENTER
        option_box.add_theme_constant_override("separation", 12)

        var btn: Button = Button.new()
        
        # Style Box Normal
        var sb_normal = StyleBoxFlat.new()
        sb_normal.bg_color = Color(0.12, 0.14, 0.16, 1.0)
        sb_normal.border_width_left = 2
        sb_normal.border_width_top = 2
        sb_normal.border_width_right = 2
        sb_normal.border_width_bottom = 2
        sb_normal.border_color = Color(0.25, 0.28, 0.3, 1.0)
        sb_normal.corner_radius_top_left = 4
        sb_normal.corner_radius_top_right = 4
        sb_normal.corner_radius_bottom_right = 4
        sb_normal.corner_radius_bottom_left = 4
        
        # Style Box Hover
        var sb_hover = sb_normal.duplicate()
        sb_hover.bg_color = Color(0.18, 0.2, 0.24, 1.0)
        sb_hover.border_color = Color(0.70, 0.63, 0.49, 1.0) # Matches HUD Avatar background
        
        btn.add_theme_stylebox_override("normal", sb_normal)
        btn.add_theme_stylebox_override("hover", sb_hover)
        btn.add_theme_stylebox_override("pressed", sb_hover)
        btn.add_theme_stylebox_override("focus", sb_hover)
        
        btn.text = ""
        btn.custom_minimum_size = Vector2(300, 460)
        btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
        btn.pressed.connect(_on_tarot_selected.bind(card_id))

        var content_margin: MarginContainer = MarginContainer.new()
        content_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        content_margin.add_theme_constant_override("margin_left", 18)
        content_margin.add_theme_constant_override("margin_top", 18)
        content_margin.add_theme_constant_override("margin_right", 18)
        content_margin.add_theme_constant_override("margin_bottom", 18)
        content_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
        btn.add_child(content_margin)

        var card_vbox: VBoxContainer = VBoxContainer.new()
        card_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
        card_vbox.add_theme_constant_override("separation", 10)
        card_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
        content_margin.add_child(card_vbox)

        var image_frame: PanelContainer = PanelContainer.new()
        image_frame.custom_minimum_size = Vector2(260, 390)
        image_frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        image_frame.add_theme_stylebox_override("panel", _build_tarot_image_frame_style())
        image_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
        card_vbox.add_child(image_frame)

        var image_margin: MarginContainer = MarginContainer.new()
        image_margin.add_theme_constant_override("margin_left", 4)
        image_margin.add_theme_constant_override("margin_top", 4)
        image_margin.add_theme_constant_override("margin_right", 4)
        image_margin.add_theme_constant_override("margin_bottom", 4)
        image_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
        image_frame.add_child(image_margin)

        var image_rect: TextureRect = TextureRect.new()
        image_rect.custom_minimum_size = Vector2(252, 382)
        image_rect.texture = _load_tarot_card_texture(card_data)
        image_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        image_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        image_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
        image_margin.add_child(image_rect)

        var name_label: Label = Label.new()
        name_label.text = TarotSystem.get_card_name(card_id).to_upper()
        name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        name_label.add_theme_font_size_override("font_size", 16)
        name_label.add_theme_color_override("font_color", Color(0.96, 0.86, 0.67, 1.0))
        name_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
        name_label.add_theme_constant_override("outline_size", 4)
        name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
        card_vbox.add_child(name_label)

        var desc_label: Label = Label.new()
        desc_label.text = TarotSystem.get_card_desc(card_id)
        desc_label.custom_minimum_size = Vector2(300, 36)
        desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        desc_label.add_theme_font_size_override("font_size", 17)
        desc_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85, 1.0))
        desc_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
        option_box.add_child(btn)
        option_box.add_child(desc_label)

        h_box.add_child(option_box)
        
    _tarot_choice_panel.visible = true

func _build_tarot_image_frame_style() -> StyleBoxFlat:
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = Color(0.05, 0.06, 0.08, 1.0)
    style.border_width_left = 1
    style.border_width_top = 1
    style.border_width_right = 1
    style.border_width_bottom = 1
    style.border_color = Color(0.40, 0.34, 0.25, 1.0)
    style.corner_radius_top_left = 3
    style.corner_radius_top_right = 3
    style.corner_radius_bottom_right = 3
    style.corner_radius_bottom_left = 3
    return style

func _load_tarot_card_texture(card_data: Dictionary) -> Texture2D:
    var path: String = str(card_data.get("image_path", ""))
    if path.is_empty():
        return null
    var crop_region: Array = card_data.get("crop_region", [])
    var cache_key: String = path
    if crop_region.size() >= 4:
        cache_key = "%s:%s,%s,%s,%s" % [
            path,
            str(crop_region[0]),
            str(crop_region[1]),
            str(crop_region[2]),
            str(crop_region[3])
        ]
    if _tarot_card_texture_cache.has(cache_key):
        return _tarot_card_texture_cache[cache_key] as Texture2D

    var texture: Texture2D = load(path) as Texture2D
    if texture == null and FileAccess.file_exists(path):
        var image: Image = Image.new()
        if image.load(path) == OK:
            texture = ImageTexture.create_from_image(image)

    if texture != null:
        if crop_region.size() >= 4:
            var atlas_texture: AtlasTexture = AtlasTexture.new()
            atlas_texture.atlas = texture
            atlas_texture.region = Rect2(
                float(crop_region[0]),
                float(crop_region[1]),
                float(crop_region[2]),
                float(crop_region[3])
            )
            _tarot_card_texture_cache[cache_key] = atlas_texture
            return atlas_texture
        _tarot_card_texture_cache[cache_key] = texture
    return texture

func _on_tarot_selected(card_id: String) -> void:
    if _player != null:
        TarotSystem.apply_card_effect(card_id, _player)
    
    _tarot_choice_panel.visible = false
    _tarot_completed_for_wave = true
    _reward_opened = false
    _begin_wave_end_reward_then_shop(_pending_wave_shop_snapshot)

var _tarot_completed_for_wave: bool = false

func _open_shop_after_wave_reward() -> void:
    if not _wave_end_reward_gate_active:
        return
    if _pending_elite_chests > 0:
        _show_elite_chest_panel()
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
    
    # Restore position overrides injected by stage transition
    if pending_snapshot.has("player_pos_x"):
        shop_snapshot["player_pos_x"] = pending_snapshot["player_pos_x"]
    if pending_snapshot.has("player_pos_y"):
        shop_snapshot["player_pos_y"] = pending_snapshot["player_pos_y"]

    GameManager.open_wave_shop(shop_snapshot)

func _complete_stage_by_timer() -> void:
    if _is_game_over:
        return
    _stage_clear_triggered = true
    _clear_active_melee_attacks()
    _reset_melee_camera_punch()
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

func _show_endless_choice_panel() -> void:
    if _endless_choice_panel == null:
        _complete_stage_by_timer()
        return
    _pause_opened = true
    _reward_opened = false
    _wave_end_reward_gate_active = false
    _pending_wave_shop_snapshot = {}
    _set_pause_overlay_visible(true)
    _set_crt_effects_enabled(true)
    pause_panel.visible = false
    if _level_reward_panel != null:
        _level_reward_panel.visible = false
    if _elite_chest_panel != null:
        _elite_chest_panel.visible = false
    if _death_settlement_panel != null:
        _death_settlement_panel.visible = false
    _endless_choice_panel.visible = true
    get_tree().paused = true

func _on_endless_continue_pressed() -> void:
    _start_endless_mode()

func _on_endless_finish_pressed() -> void:
    get_tree().paused = false
    _pause_opened = false
    if _endless_choice_panel != null:
        _endless_choice_panel.visible = false
    _set_pause_overlay_visible(false)
    _set_crt_effects_enabled(true)
    GameManager.go_to_menu()

func _start_endless_mode() -> void:
    get_tree().paused = false
    _pause_opened = false
    _stage_clear_triggered = false
    _is_endless_mode = true
    _endless_elapsed = 0.0
    _endless_shop_timer = 0.0
    _endless_shop_transitioning = false
    _endless_level = 0
    _endless_base_max_enemy_count = _max_enemy_count_runtime
    _apply_endless_elite_schedule()
    _active_elite = null
    _wave_elapsed = 0.0
    _enemy_spawn_timer = 0.0
    _melee_pressure_spawn_timer = 0.0
    if _endless_choice_panel != null:
        _endless_choice_panel.visible = false
    _set_pause_overlay_visible(false)
    _set_crt_effects_enabled(true)
    _clear_enemy_projectiles()
    _clear_experience_orbs()
    _clear_all_enemies()
    _set_combat_simulation_active(true)
    GameManager.change_state(GameManager.GameState.PLAYING)
    if _pending_level_up_rewards > 0:
        _try_open_next_level_reward()

func _trigger_endless_shop() -> void:
    if _endless_shop_transitioning:
        return
    _endless_shop_transitioning = true
    _stage_clear_triggered = true
    _endless_shop_timer = 0.0
    _set_combat_simulation_active(false)
    _clear_active_melee_attacks()
    _reset_melee_camera_punch()
    _clear_player_projectiles()
    _clear_enemy_projectiles()
    _clear_experience_orbs()
    _clear_consumables()
    var shop_snapshot: Dictionary = _build_wave_runtime_snapshot()
    shop_snapshot["stage_id"] = ENDLESS_ENTRY_STAGE_ID
    shop_snapshot["wave"] = 1
    shop_snapshot["wave_progress_index"] = 0
    shop_snapshot["is_endless_mode"] = true
    shop_snapshot["endless_elapsed"] = _endless_elapsed
    shop_snapshot["endless_level"] = _endless_level
    shop_snapshot["endless_shop_timer"] = _endless_shop_timer
    shop_snapshot["endless_base_max_enemy_count"] = _endless_base_max_enemy_count
    GameManager.open_wave_shop(shop_snapshot)

func _build_stage_transition_payload(next_stage_id: String) -> Dictionary:
    var payload: Dictionary = _build_runtime_save_payload()
    payload["stage_id"] = next_stage_id
    payload["wave"] = 1
    payload["wave_progress_index"] = 0
    payload["player_pos_x"] = 0.0
    payload["player_pos_y"] = 0.0
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
    if not _player.damage_taken.is_connected(_on_player_damage_taken):
        _player.damage_taken.connect(_on_player_damage_taken)
    if not _player.attack_dodged.is_connected(_on_player_attack_dodged):
        _player.attack_dodged.connect(_on_player_attack_dodged)
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
    for i: int in range(_initial_enemy_count_runtime):
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
    if _enemies.size() >= _get_active_max_enemy_count():
        return
    if _player == null or not is_instance_valid(_player):
        return
    _cleanup_dead_enemies()
    if _count_active_enemies() >= _get_active_max_enemy_count():
        return
    var spawn_type: Enemy.EnemyType = _roll_enemy_spawn_type()
    _spawn_enemy(spawn_type, _random_spawn_position())

func _try_spawn_enemy_batch(batch_count: int) -> void:
    var safe_batch_count: int = max(1, batch_count)
    for i: int in range(safe_batch_count):
        if _count_active_enemies() >= _get_active_max_enemy_count():
            return
        _try_spawn_enemy()

func _try_spawn_melee_pressure_enemy() -> void:
    if _enemies.size() >= _get_active_max_enemy_count():
        return
    if _player == null or not is_instance_valid(_player):
        return
    _cleanup_dead_enemies()
    if _count_active_enemies() >= _get_active_max_enemy_count():
        return
    _spawn_enemy(_roll_melee_pressure_spawn_type(), _random_spawn_position())

func _roll_enemy_spawn_type() -> Enemy.EnemyType:
    if _enemy_spawn_weights_runtime.is_empty():
        return Enemy.EnemyType.MELEE

    var total_weight: float = 0.0
    for spawn_type: Variant in _enemy_spawn_weights_runtime.keys():
        total_weight += max(0.0, float(_enemy_spawn_weights_runtime[spawn_type]))
    if total_weight <= 0.0:
        return Enemy.EnemyType.MELEE

    var roll: float = randf() * total_weight
    for spawn_type: Variant in _enemy_spawn_weights_runtime.keys():
        roll -= max(0.0, float(_enemy_spawn_weights_runtime[spawn_type]))
        if roll <= 0.0:
            var selected_type: Enemy.EnemyType = spawn_type
            return selected_type
    return Enemy.EnemyType.MELEE

func _roll_melee_pressure_spawn_type() -> Enemy.EnemyType:
    var melee_weight: float = 1.0
    var fast_weight: float = max(0.0, _melee_pressure_fast_weight_runtime)
    var charger_weight: float = max(0.0, _melee_pressure_charger_weight_runtime)
    if charger_weight <= 0.0:
        var total_no_charger: float = melee_weight + fast_weight
        if total_no_charger <= 0.0:
            return Enemy.EnemyType.MELEE
        return Enemy.EnemyType.FAST_MELEE if randf() * total_no_charger > melee_weight else Enemy.EnemyType.MELEE

    var roll: float = randf() * (melee_weight + fast_weight + charger_weight)
    if roll < melee_weight:
        return Enemy.EnemyType.MELEE
    roll -= melee_weight
    if roll < fast_weight:
        return Enemy.EnemyType.FAST_MELEE
    return Enemy.EnemyType.CHARGER

func _spawn_enemy(spawn_type: Enemy.EnemyType, spawn_position: Vector2) -> Enemy:
    if _count_active_enemies() >= _get_active_max_enemy_count():
        return null
    var enemy: Enemy = null
    match spawn_type:
        Enemy.EnemyType.FAST_MELEE:
            enemy = FastMeleeEnemy.new()
        Enemy.EnemyType.CHARGER:
            enemy = ChargerEnemy.new()
        Enemy.EnemyType.SPLITTER:
            enemy = SplitterEnemy.new()
        Enemy.EnemyType.SNIPER:
            enemy = SniperEnemy.new()
        Enemy.EnemyType.MINE_SEEDER:
            enemy = MineSeederEnemy.new()
        Enemy.EnemyType.RANGED:
            enemy = RangedEnemy.new()
        Enemy.EnemyType.BARRAGE:
            enemy = BarrageEnemy.new()
        Enemy.EnemyType.ELITE_WARDEN:
            enemy = EliteStaticWarden.new()
        Enemy.EnemyType.ELITE_RIFT_CHARGER:
            enemy = EliteRiftCharger.new()
        Enemy.EnemyType.ELITE_CLOCKWORK_SEER:
            enemy = EliteClockworkSeer.new()
        _:
            enemy = Enemy.new()

    enemy.global_position = _clamp_position_to_arena(spawn_position, enemy.body_radius)
    enemy.set_target(_player)
    enemy.died.connect(_on_enemy_died)
    enemy.enemy_projectile_fired.connect(_on_enemy_projectile_fired)
    enemy.damage_multiplier = _get_enemy_damage_scale()
    add_child(enemy)
    var hp_scale: float = max(0.1, _enemy_hp_multiplier * _enemy_hp_stage_multiplier * _get_endless_hp_multiplier())
    var scaled_max_hp: int = max(1, int(round(float(enemy.max_hp) * hp_scale)))
    enemy.max_hp = scaled_max_hp
    enemy.current_hp = scaled_max_hp
    var speed_scale: float = max(0.1, _enemy_move_speed_stage_multiplier * _enemy_move_speed_difficulty_multiplier * _get_endless_speed_multiplier())
    enemy.move_speed = max(10.0, enemy.move_speed * speed_scale)
    enemy.queue_redraw()
    _enemies.append(enemy)
    return enemy

func _get_active_max_enemy_count() -> int:
    if not _is_endless_mode:
        return clampi(_max_enemy_count_runtime, 1, HARD_MAX_ACTIVE_ENEMY_COUNT)
    var base_count: int = _endless_base_max_enemy_count if _endless_base_max_enemy_count > 0 else _max_enemy_count_runtime
    return clampi(base_count + _endless_level * ENDLESS_MAX_ENEMY_COUNT_PER_LEVEL, 1, HARD_MAX_ACTIVE_ENEMY_COUNT)

func _apply_endless_elite_schedule() -> void:
    _elite_schedule_enabled = true
    _elite_respawn_check_interval_runtime = ENDLESS_ELITE_RESPAWN_MAX
    _elite_respawn_interval_min_runtime = ENDLESS_ELITE_RESPAWN_MIN
    _elite_respawn_interval_max_runtime = ENDLESS_ELITE_RESPAWN_MAX
    _elite_max_alive_runtime = ENDLESS_ELITE_MAX_ALIVE
    _elite_hp_override_runtime = 0
    _elite_pool_runtime = [
        {"type": "elite_warden", "weight": 1.0},
        {"type": "elite_rift_charger", "weight": 1.0},
        {"type": "elite_clockwork_seer", "weight": 1.0},
    ]
    _next_elite_spawn_time = _battle_elapsed + randf_range(ENDLESS_ELITE_FIRST_SPAWN_MIN, ENDLESS_ELITE_FIRST_SPAWN_MAX)

func _schedule_next_elite_spawn() -> void:
    var min_interval: float = max(1.0, _elite_respawn_interval_min_runtime)
    var max_interval: float = max(min_interval, _elite_respawn_interval_max_runtime)
    _next_elite_spawn_time = _battle_elapsed + randf_range(min_interval, max_interval)

func _try_spawn_elite_by_schedule() -> void :
    if not _elite_schedule_enabled:
        return
    if _battle_elapsed < _next_elite_spawn_time:
        return
    if _is_endless_mode:
        _schedule_next_elite_spawn()
    else:
        _next_elite_spawn_time += _elite_respawn_check_interval_runtime
    if _count_alive_elites() >= _elite_max_alive_runtime:
        return
    if _count_active_enemies() >= _get_active_max_enemy_count():
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
    if _stage_is_boss_stage:
        var stage_profile: Dictionary = BalanceService.get_stage_profile(GameManager.current_stage_id)
        var boss_config: Dictionary = stage_profile.get("boss", {})
        if not boss_config.is_empty():
            _spawn_stage_boss(boss_config)
            return
    var elite_spawn: Vector2 = _random_spawn_position()
    var enemy: Enemy = _spawn_enemy(_roll_elite_spawn_type(), elite_spawn)
    if enemy == null:
        return
    if _elite_hp_override_runtime > 0:
        enemy.max_hp = max(1, int(round(float(_elite_hp_override_runtime) * max(0.1, _enemy_hp_multiplier))))
        enemy.current_hp = enemy.max_hp
        enemy.queue_redraw()
    if _is_endless_mode:
        _apply_endless_elite_spawn_enrage(enemy)
    _active_elite = enemy
    _elite_spawn_relief_timer = ELITE_SPAWN_RELIEF_DURATION
    print("[Elite] Spawned %s at %.2fs" % [enemy.get_display_name(), _battle_elapsed])

func _apply_endless_elite_spawn_enrage(enemy: Enemy) -> void:
    if enemy == null or not is_instance_valid(enemy):
        return
    var hp_multiplier: float = randf_range(ENDLESS_ELITE_HP_ENRAGE_MIN, ENDLESS_ELITE_HP_ENRAGE_MAX)
    var damage_multiplier: float = randf_range(ENDLESS_ELITE_DAMAGE_ENRAGE_MIN, ENDLESS_ELITE_DAMAGE_ENRAGE_MAX)
    var speed_multiplier: float = randf_range(ENDLESS_ELITE_SPEED_ENRAGE_MIN, ENDLESS_ELITE_SPEED_ENRAGE_MAX)
    var final_hp: int = max(1, int(round(float(ENDLESS_ELITE_BASE_HP) * _get_endless_hp_multiplier() * hp_multiplier)))
    enemy.max_hp = final_hp
    enemy.current_hp = final_hp
    enemy.damage_multiplier *= damage_multiplier
    enemy.move_speed = max(10.0, enemy.move_speed * speed_multiplier)
    enemy.queue_redraw()
    print(
        "[Elite] Endless enrage %s hp=%d dmg=%.2f speed=%.2f" % [
            enemy.get_display_name(),
            enemy.max_hp,
            enemy.damage_multiplier,
            enemy.move_speed,
        ]
    )

func _roll_elite_spawn_type() -> Enemy.EnemyType:
    if _elite_pool_runtime.is_empty():
        return Enemy.EnemyType.ELITE_WARDEN
    var total_weight: float = 0.0
    for entry: Dictionary in _elite_pool_runtime:
        total_weight += max(0.0, float(entry.get("weight", 0.0)))
    if total_weight <= 0.0:
        return Enemy.EnemyType.ELITE_WARDEN

    var roll: float = randf() * total_weight
    for entry: Dictionary in _elite_pool_runtime:
        roll -= max(0.0, float(entry.get("weight", 0.0)))
        if roll <= 0.0:
            return _enemy_type_from_key(str(entry.get("type", "elite_warden")))
    return Enemy.EnemyType.ELITE_WARDEN

func _enemy_type_from_key(type_key: String) -> Enemy.EnemyType:
    match type_key:
        "fast_melee":
            return Enemy.EnemyType.FAST_MELEE
        "charger":
            return Enemy.EnemyType.CHARGER
        "ranged":
            return Enemy.EnemyType.RANGED
        "barrage":
            return Enemy.EnemyType.BARRAGE
        "splitter":
            return Enemy.EnemyType.SPLITTER
        "sniper":
            return Enemy.EnemyType.SNIPER
        "mine_seeder":
            return Enemy.EnemyType.MINE_SEEDER
        "elite_rift_charger":
            return Enemy.EnemyType.ELITE_RIFT_CHARGER
        "elite_clockwork_seer":
            return Enemy.EnemyType.ELITE_CLOCKWORK_SEER
        "elite_warden":
            return Enemy.EnemyType.ELITE_WARDEN
        _:
            return Enemy.EnemyType.MELEE

func _spawn_stage_boss(boss_config: Dictionary) -> Enemy:
    if _player == null or not is_instance_valid(_player):
        return null
    var boss: BossDreamWatcher = BossDreamWatcher.new()
    boss.global_position = _clamp_position_to_arena(Vector2(0.0, -120.0), 24.0)
    boss.set_target(_player)
    boss.died.connect(_on_enemy_died)
    boss.enemy_projectile_fired.connect(_on_enemy_projectile_fired)
    boss.summon_requested.connect(_on_boss_summon_requested)
    boss.damage_multiplier = max(0.1, float(boss_config.get("damage_multiplier", 1.0)))
    boss.contact_damage_override = max(0, int(boss_config.get("contact_damage", 0)))
    add_child(boss)
    boss.configure_from_stage(boss_config)
    var boss_hp_scale: float = max(0.1, _enemy_hp_multiplier)
    boss.max_hp = max(1, int(round(float(boss.max_hp) * boss_hp_scale)))
    boss.current_hp = boss.max_hp
    boss.global_position = _clamp_position_to_arena(boss.global_position, boss.body_radius)
    boss.queue_redraw()
    _enemies.append(boss)
    _active_elite = boss
    _elite_spawn_relief_timer = ELITE_SPAWN_RELIEF_DURATION
    print("[Boss] Spawned %s at %.2fs" % [boss.get_display_name(), _battle_elapsed])
    if hud.has_method("show_boss_bar"):
        hud.call("show_boss_bar", boss.get_display_name(), float(boss.max_hp), float(boss.current_hp))
    return boss

func _on_boss_summon_requested(count: int) -> void:
    if _player == null or not is_instance_valid(_player):
        return
    var summon_count: int = clampi(count, 0, 12)
    for i: int in range(summon_count):
        if _count_active_enemies() >= _get_active_max_enemy_count():
            return
        _spawn_enemy(Enemy.EnemyType.MELEE, _random_spawn_position())

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
        var distance: float = randf_range(_enemy_min_spawn_radius_runtime, _enemy_max_spawn_radius_runtime)
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
        if candidate.distance_to(_player.global_position) >= _enemy_min_spawn_radius_runtime * 0.65:
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
        var effective_interval: float = _resolve_weapon_effective_interval(attack_profile, safe_speed_mult)
        var cooldown_remaining: float = max(0.0, float(_weapon_cooldowns.get(slot_index, 0.0)) - delta)
        if cooldown_remaining > 0.0:
            _weapon_cooldowns[slot_index] = cooldown_remaining
            continue

        var attack_mode: String = str(attack_profile.get("mode", "ranged_homing"))
        if _active_melee_attacks.has(slot_index):
            continue

        var weapon_pos: Vector2 = _player.global_position
        if attack_mode != "melee_arc" and _weapon_orbit_nodes.has(slot_index):
            var sprite: Sprite2D = _weapon_orbit_nodes[slot_index]
            if is_instance_valid(sprite):
                weapon_pos = sprite.global_position
                
        var target_range: float = _resolve_weapon_attack_range(attack_profile)
        var nearest_enemy: Enemy = _find_nearest_enemy_in_range(target_range, weapon_pos)
        if nearest_enemy == null:
            continue
        var attack_slot_index: int = slot_index
        var active_attack_profile: Dictionary = attack_profile
        var active_slot_weapon: Dictionary = slot_weapon
        var active_effective_interval: float = effective_interval
        if attack_mode == "melee_arc":
            attack_slot_index = _resolve_melee_attack_slot_index(slot_index, nearest_enemy, equipped_slots)
            if _active_melee_attacks.has(attack_slot_index):
                continue
            if attack_slot_index != slot_index:
                var active_weapon_value: Variant = equipped_slots[attack_slot_index]
                if _is_valid_weapon_slot(active_weapon_value):
                    active_slot_weapon = active_weapon_value
                    active_attack_profile = _resolve_attack_profile(active_slot_weapon)
                    active_effective_interval = _resolve_weapon_effective_interval(active_attack_profile, safe_speed_mult)
        _attack_with_profile(nearest_enemy, active_attack_profile, attack_slot_index, active_slot_weapon, active_effective_interval)
        _weapon_targets[attack_slot_index] = nearest_enemy
        if attack_mode != "melee_arc":
            _trigger_weapon_orbit_flash(attack_slot_index)
            _weapon_cooldowns[slot_index] = effective_interval

func _attack_with_profile(
    target_enemy: Enemy,
    attack_profile: Dictionary,
    slot_index: int = -1,
    weapon: Dictionary = {},
    cooldown_after_finish: float = 0.0
) -> void:
    if target_enemy == null or not is_instance_valid(target_enemy):
        return
    var mode: String = str(attack_profile.get("mode", "ranged_homing"))
    match mode:
        "melee_arc":
            _perform_melee_arc_attack(target_enemy, attack_profile, slot_index, weapon, cooldown_after_finish)
        "ranged_bounce_weapon":
            _spawn_weapon_projectile(target_enemy, attack_profile, true, slot_index, weapon)
        "ranged_lob_aoe":
            _spawn_weapon_projectile(target_enemy, attack_profile, false, slot_index, weapon)
        "ranged_heavy":
            _spawn_weapon_projectile(target_enemy, attack_profile, false, slot_index, weapon)
        _:
            _spawn_weapon_projectile(target_enemy, attack_profile, true, slot_index, weapon)

func _find_nearest_enemy_in_range(max_distance: float, from_position: Vector2 = Vector2.INF) -> Enemy:
    var ref_pos: Vector2 = from_position
    if ref_pos == Vector2.INF:
        if _player == null:
            return null
        ref_pos = _player.global_position
        
    var best_dist_sq: float = max_distance * max_distance
    var best_enemy: Enemy = null
    for enemy: Enemy in _enemies:
        if not _is_enemy_combat_active(enemy):
            continue
        var dist_sq: float = ref_pos.distance_squared_to(enemy.global_position)
        if dist_sq < best_dist_sq:
            best_dist_sq = dist_sq
            best_enemy = enemy
    return best_enemy

func _spawn_weapon_projectile(target_enemy: Enemy, attack_profile: Dictionary, homing: bool, slot_index: int = -1, weapon: Dictionary = {}) -> void:
    if target_enemy == null or not is_instance_valid(target_enemy):
        return
    var projectile: Projectile = Projectile.new()
    var attack_mode: String = str(attack_profile.get("mode", "ranged_homing"))
    projectile.damage = _resolve_weapon_damage(attack_profile)
    projectile.speed = max(180.0, float(attack_profile.get("projectile_speed", BULLET_SPEED)))
    projectile.hit_radius = max(2.0, float(attack_profile.get("projectile_radius", 4.0)))
    projectile.crit_chance = _player.crit_chance
    projectile.crit_multiplier = _resolve_weapon_crit_multiplier(attack_profile)
    projectile.lifesteal_chance = _resolve_weapon_lifesteal_chance(attack_profile)
    projectile.knockback_strength = _resolve_weapon_knockback_strength(attack_profile)
    projectile.knockback_duration = _resolve_weapon_knockback_duration(attack_profile)
    projectile.owner_player = _player
    var lob_target_position: Vector2 = target_enemy.global_position
    match attack_mode:
        "ranged_bounce_weapon":
            projectile.configure_visual_preset("weapon_bounce")
            projectile.impact_mode = "bounce_weapon"
            projectile.bounce_count = max(0, int(attack_profile.get("bounce_count", 0)))
            projectile.bounce_range = max(0.0, float(attack_profile.get("bounce_range", 0.0)))
            projectile.bounce_damage_mult = clampf(float(attack_profile.get("bounce_damage_mult", 1.0)), 0.05, 1.0)
            var weapon_texture: Texture2D = _get_weapon_projectile_texture(weapon, attack_profile)
            if weapon_texture != null:
                var projectile_width: float = max(18.0, float(attack_profile.get("projectile_visual_width", 30.0)))
                projectile.configure_weapon_projectile(
                    weapon_texture,
                    projectile_width,
                    float(attack_profile.get("spin_speed", 18.0))
                )
        "ranged_homing":
            projectile.configure_visual_preset("homing")
        "ranged_heavy":
            projectile.configure_visual_preset("heavy")
        "ranged_lob_aoe":
            projectile.configure_visual_preset("lob_aoe")
            projectile.impact_mode = "aoe"
            projectile.aoe_radius = max(1.0, float(attack_profile.get("aoe_radius", 72.0)))
            projectile.life_time = max(
                float(attack_profile.get("life_time", 0.0)),
                float(attack_profile.get("flight_time", 0.55)) + 0.15
            )
        _:
            projectile.configure_visual_preset("default")
    var sprite_node: Sprite2D = null
    if slot_index >= 0 and _weapon_orbit_nodes.has(slot_index):
        sprite_node = _weapon_orbit_nodes[slot_index]
    
    var spawn_pos: Vector2 = _player.global_position
    var fire_direction: Vector2 = (_player.global_position.direction_to(lob_target_position)).normalized()
    
    if sprite_node != null and is_instance_valid(sprite_node):
        spawn_pos = sprite_node.global_position
        fire_direction = (spawn_pos.direction_to(lob_target_position)).normalized()
        # Add muzzle offset in the direction of the target
        spawn_pos += fire_direction * WEAPON_ORBIT_MUZZLE_OFFSET
            
    projectile.global_position = spawn_pos
    projectile.direction = fire_direction
    if attack_mode == "ranged_lob_aoe":
        projectile.configure_lob(
            lob_target_position,
            float(attack_profile.get("flight_time", 0.55)),
            float(attack_profile.get("arc_height", 80.0))
        )
    if homing:
        projectile.set_target(target_enemy)
    add_child(projectile)
    _projectiles.append(projectile)

func _perform_melee_arc_attack(
    target_enemy: Enemy,
    attack_profile: Dictionary,
    slot_index: int,
    weapon: Dictionary = {},
    cooldown_after_finish: float = 0.0
) -> void:
    if not _is_enemy_combat_active(target_enemy):
        return
    if slot_index < 0:
        return
    if _player == null or not is_instance_valid(_player):
        return
    if not _weapon_orbit_nodes.has(slot_index):
        return
    var sprite_value: Variant = _weapon_orbit_nodes.get(slot_index, null)
    if not (sprite_value is Sprite2D):
        return
    var sprite: Sprite2D = sprite_value
    if not is_instance_valid(sprite):
        return

    var direction: Vector2 = _player.global_position.direction_to(target_enemy.global_position)
    if direction.length_squared() <= 0.0001:
        direction = _resolve_slot_aim_direction(slot_index, sprite.global_position)
    if direction.length_squared() <= 0.0001:
        direction = Vector2.RIGHT

    var runtime: Dictionary = _build_melee_attack_runtime(slot_index, weapon, attack_profile, sprite, direction)
    runtime["cooldown_after_finish"] = max(0.0, cooldown_after_finish)
    _active_melee_attacks[slot_index] = runtime
    _weapon_orbit_flash_timers.erase(slot_index)
    _spawn_melee_arc_effect(target_enemy.global_position, attack_profile, str(runtime.get("family", "sweep")), float(runtime.get("duration", 0.18)))

func _resolve_melee_attack_slot_index(original_slot_index: int, target_enemy: Enemy, equipped_slots: Array) -> int:
    if _player == null or not is_instance_valid(_player):
        return original_slot_index
    if not _is_enemy_combat_active(target_enemy):
        return original_slot_index
    var target_direction: Vector2 = _player.global_position.direction_to(target_enemy.global_position)
    if target_direction.length_squared() <= 0.0001:
        return original_slot_index
    target_direction = target_direction.normalized()

    var best_slot_index: int = original_slot_index
    var best_score: float = -INF
    for candidate_slot_index: int in range(equipped_slots.size()):
        if _active_melee_attacks.has(candidate_slot_index):
            continue
        if not _weapon_orbit_nodes.has(candidate_slot_index):
            continue
        var weapon_value: Variant = equipped_slots[candidate_slot_index]
        if not _is_valid_weapon_slot(weapon_value):
            continue
        var candidate_weapon: Dictionary = weapon_value
        var candidate_profile: Dictionary = _resolve_attack_profile(candidate_weapon)
        if str(candidate_profile.get("mode", "ranged_homing")) != "melee_arc":
            continue
        if candidate_slot_index != original_slot_index and float(_weapon_cooldowns.get(candidate_slot_index, 0.0)) > 0.0:
            continue
        var sprite_value: Variant = _weapon_orbit_nodes.get(candidate_slot_index, null)
        if not (sprite_value is Sprite2D):
            continue
        var sprite: Sprite2D = sprite_value
        if not is_instance_valid(sprite):
            continue
        var slot_direction: Vector2 = _player.global_position.direction_to(sprite.global_position)
        if slot_direction.length_squared() <= 0.0001:
            continue
        var score: float = slot_direction.normalized().dot(target_direction)
        if candidate_slot_index == original_slot_index:
            score += 0.001
        if score > best_score:
            best_score = score
            best_slot_index = candidate_slot_index
    return best_slot_index

func _resolve_weapon_damage(attack_profile: Dictionary) -> int:
    if _player == null or not is_instance_valid(_player):
        return max(1, int(attack_profile.get("base_damage", AUTO_ATTACK_BASE_DAMAGE)))
    var base_damage: int = int(attack_profile.get("base_damage", AUTO_ATTACK_BASE_DAMAGE))
    var mode: String = str(attack_profile.get("mode", "ranged_homing"))
    var mode_bonus: int = _resolve_mode_damage_bonus(mode)
    var damage_before_global: int = max(1, base_damage + mode_bonus)
    var global_mult: float = max(0.1, 1.0 + _player.get_global_attack_percent() / 100.0)
    return max(1, int(round(float(damage_before_global) * global_mult)))

func _resolve_weapon_effective_interval(attack_profile: Dictionary, safe_speed_mult: float = -1.0) -> float:
    var speed_mult: float = safe_speed_mult
    if speed_mult <= 0.0:
        speed_mult = 1.0
        if _player != null and is_instance_valid(_player):
            speed_mult = _player.get_attack_speed_multiplier()
    speed_mult = max(0.01, speed_mult)
    var base_interval: float = max(0.08, float(attack_profile.get("interval", AUTO_ATTACK_INTERVAL)))
    return clampf(
        base_interval * _auto_attack_interval_multiplier_runtime / speed_mult,
        0.08,
        1.2
    )

func _resolve_weapon_crit_multiplier(attack_profile: Dictionary) -> float:
    return max(1.0, float(attack_profile.get("crit_multiplier", 1.5)))

func _resolve_weapon_lifesteal_chance(attack_profile: Dictionary) -> float:
    if _player == null or not is_instance_valid(_player):
        return 0.0
    var weapon_lifesteal: float = float(attack_profile.get("lifesteal", attack_profile.get("lifesteal_chance", 0.0)))
    return clampf(_player.lifesteal + weapon_lifesteal, 0.0, 1.0)

func _resolve_weapon_knockback_strength(attack_profile: Dictionary, melee_family: String = "") -> float:
    if attack_profile.has("knockback_strength"):
        return max(0.0, float(attack_profile.get("knockback_strength", 0.0)))
    var mode: String = str(attack_profile.get("mode", "ranged_homing"))
    if mode == "melee_arc":
        var family: String = melee_family.to_lower()
        if not family.is_empty() and KNOCKBACK_BY_MELEE_FAMILY.has(family):
            return float(KNOCKBACK_BY_MELEE_FAMILY.get(family, KNOCKBACK_BY_MODE.get("melee_arc", 130.0)))
    return float(KNOCKBACK_BY_MODE.get(mode, KNOCKBACK_BY_MODE.get("ranged_homing", 85.0)))

func _resolve_weapon_knockback_duration(attack_profile: Dictionary) -> float:
    if attack_profile.has("knockback_duration"):
        return max(0.0, float(attack_profile.get("knockback_duration", 0.0)))
    var mode: String = str(attack_profile.get("mode", "ranged_homing"))
    return float(KNOCKBACK_DURATION_BY_MODE.get(mode, KNOCKBACK_DEFAULT_DURATION))

func _apply_weapon_knockback(enemy: Enemy, direction: Vector2, strength: float, duration: float) -> void:
    if enemy == null or not is_instance_valid(enemy):
        return
    if strength <= 0.0 or duration <= 0.0:
        return
    var knockback_direction: Vector2 = direction
    if knockback_direction.length_squared() <= 0.0001 and _player != null and is_instance_valid(_player):
        knockback_direction = _player.global_position.direction_to(enemy.global_position)
    if knockback_direction.length_squared() <= 0.0001:
        knockback_direction = Vector2.RIGHT
    if enemy.has_method("apply_knockback"):
        enemy.apply_knockback(knockback_direction.normalized(), strength, duration)

func _resolve_mode_damage_bonus(mode: String) -> int:
    if _player == null or not is_instance_valid(_player):
        return 0
    match mode:
        "melee_arc":
            return _player.get_melee_attack_damage_bonus()
        "ranged_homing", "ranged_heavy", "ranged_lob_aoe", "ranged_bounce_weapon":
            return _player.get_ranged_attack_damage_bonus()
        _:
            return 0

func _resolve_weapon_attack_range(attack_profile: Dictionary) -> float:
    var mode: String = str(attack_profile.get("mode", "ranged_homing"))
    if mode == "melee_arc":
        return _resolve_melee_effective_range(attack_profile)
    var profile_range: float = float(attack_profile.get("range", _player.get_current_target_range()))
    var final_range: float = profile_range + _player.bonus_target_range
    return max(1.0, final_range)

func _resolve_melee_effective_range(attack_profile: Dictionary) -> float:
    var profile_range: float = float(attack_profile.get("range", 95.0))
    var bonus_range: float = 0.0
    if _player != null and is_instance_valid(_player):
        bonus_range = min(_player.bonus_target_range * MELEE_TARGET_RANGE_BONUS_RATIO, MELEE_TARGET_RANGE_BONUS_CAP)
    return clampf(profile_range + bonus_range, 1.0, MELEE_TARGET_RANGE_CAP)

func _resolve_melee_splash_radius(attack_profile: Dictionary) -> float:
    var melee_range: float = clampf(float(attack_profile.get("range", 95.0)), 55.0, 130.0)
    var default_radius: float = melee_range * 0.58
    var raw_radius: float = float(attack_profile.get("splash_radius", default_radius))
    return clampf(raw_radius, 48.0, 110.0)

func _build_melee_attack_runtime(
    slot_index: int,
    weapon: Dictionary,
    attack_profile: Dictionary,
    sprite: Sprite2D,
    direction: Vector2
) -> Dictionary:
    var family: String = _resolve_melee_attack_family(weapon, attack_profile)
    var attack_range: float = _resolve_weapon_attack_range(attack_profile)
    var rest_radius: float = max(16.0, sprite.position.length())
    var hitbox_length: float = 24.0
    var hitbox_width: float = 18.0
    var duration: float = 0.22
    var active_start_ratio: float = 0.18
    var active_end_ratio: float = 0.86
    var sweep_arc: float = clampf(float(attack_profile.get("arc_width", 1.45)), 0.9, 2.0)
    var attack_radius: float = clampf(attack_range * 0.82, 46.0, 122.0)
    var windup_angle: float = direction.angle() - 1.1
    var impact_angle: float = direction.angle() + 0.14
    var recover_angle: float = direction.angle() - 0.06

    match family:
        "thrust":
            duration = max(0.12, float(attack_profile.get("attack_duration", 0.17)))
            active_start_ratio = clampf(float(attack_profile.get("active_start_ratio", 0.16)), 0.0, 0.95)
            active_end_ratio = clampf(float(attack_profile.get("active_end_ratio", 0.68)), active_start_ratio, 1.0)
            attack_radius = clampf(float(attack_profile.get("attack_radius", attack_range * 0.92)), 52.0, 136.0)
            rest_radius = clampf(rest_radius, 12.0, 28.0)
            hitbox_length = clampf(float(attack_profile.get("hitbox_length", attack_radius * 0.55)), 18.0, 52.0)
            hitbox_width = clampf(float(attack_profile.get("hitbox_width", attack_radius * 0.16)), 12.0, 22.0)
        "heavy":
            duration = max(0.16, float(attack_profile.get("attack_duration", 0.29)))
            active_start_ratio = clampf(float(attack_profile.get("active_start_ratio", 0.42)), 0.0, 0.95)
            active_end_ratio = clampf(float(attack_profile.get("active_end_ratio", 0.78)), active_start_ratio, 1.0)
            attack_radius = clampf(float(attack_profile.get("attack_radius", attack_range * 0.76)), 44.0, 118.0)
            rest_radius = clampf(rest_radius, 16.0, 28.0)
            hitbox_length = clampf(float(attack_profile.get("hitbox_length", attack_radius * 0.34)), 18.0, 40.0)
            hitbox_width = clampf(float(attack_profile.get("hitbox_width", attack_radius * 0.34)), 22.0, 38.0)
            sweep_arc = clampf(float(attack_profile.get("arc_width", 1.15)), 0.78, 1.55)
            windup_angle = direction.angle() - sweep_arc * 0.95
            impact_angle = direction.angle() + sweep_arc * 0.18
            recover_angle = direction.angle() - sweep_arc * 0.06
        _:
            family = "sweep"
            duration = max(0.14, float(attack_profile.get("attack_duration", 0.22)))
            active_start_ratio = clampf(float(attack_profile.get("active_start_ratio", 0.18)), 0.0, 0.95)
            active_end_ratio = clampf(float(attack_profile.get("active_end_ratio", 0.86)), active_start_ratio, 1.0)
            attack_radius = clampf(float(attack_profile.get("attack_radius", attack_range * 0.82)), 46.0, 122.0)
            rest_radius = clampf(rest_radius, 16.0, 30.0)
            hitbox_length = clampf(float(attack_profile.get("hitbox_length", attack_radius * 0.28)), 16.0, 34.0)
            hitbox_width = clampf(float(attack_profile.get("hitbox_width", attack_radius * 0.28)), 18.0, 30.0)

    var forward: Vector2 = direction.normalized()
    if forward.length_squared() <= 0.0001:
        forward = Vector2.RIGHT
    var current_global_point: Vector2 = _player.global_position + forward * rest_radius
    var base_scale: Vector2 = _resolve_weapon_orbit_base_scale(sprite)
    var weapon_id: String = str(weapon.get("weapon_id", ""))
    var alignment: Dictionary = _resolve_melee_weapon_alignment(weapon_id, family, sprite)
    var fx_intensity: float = 1.0
    var camera_punch_strength: float = 1.2
    var impact_scale: float = 1.0
    var hit_pause_duration: float = 0.022

    match family:
        "thrust":
            fx_intensity = 0.96
            camera_punch_strength = 0.9
            impact_scale = 0.88
            hit_pause_duration = 0.018
        "heavy":
            fx_intensity = 1.2
            camera_punch_strength = 2.2
            impact_scale = 1.24
            hit_pause_duration = 0.03
        _:
            fx_intensity = 1.04
            camera_punch_strength = 1.35
            impact_scale = 1.0
            hit_pause_duration = 0.022

    var tip_forward_distance: float = float(alignment.get("tip_forward_distance", 0.0))
    var lateral_offset_distance: float = float(alignment.get("lateral_offset_distance", 0.0))
    var min_attack_radius: float = max(12.0, rest_radius + 4.0)
    var max_attack_radius: float = max(min_attack_radius, (attack_range - tip_forward_distance - 2.0) / 1.06)
    attack_radius = clampf(attack_radius, min_attack_radius, max_attack_radius)
    hitbox_length = min(hitbox_length, max(16.0, attack_radius * 0.58))
    hitbox_width = min(hitbox_width, max(12.0, attack_radius * 0.4))
    current_global_point = _player.global_position + forward * (rest_radius + tip_forward_distance) + forward.orthogonal() * lateral_offset_distance

    return {
        "slot_index": slot_index,
        "weapon_id": weapon_id,
        "family": family,
        "sprite": sprite,
        "elapsed": 0.0,
        "duration": duration,
        "active_start_time": duration * active_start_ratio,
        "active_end_time": duration * active_end_ratio,
        "direction": forward,
        "base_angle": forward.angle(),
        "melee_effective_range": attack_range,
        "attack_radius": attack_radius,
        "rest_radius": rest_radius,
        "hitbox_length": hitbox_length,
        "hitbox_width": hitbox_width,
        "sweep_arc": sweep_arc,
        "sweep_from": forward.angle() - sweep_arc * 0.64,
        "sweep_to": forward.angle() + sweep_arc * 0.54,
        "windup_angle": windup_angle,
        "impact_angle": impact_angle,
        "recover_angle": recover_angle,
        "base_damage": _resolve_weapon_damage(attack_profile),
        "crit_multiplier": _resolve_weapon_crit_multiplier(attack_profile),
        "lifesteal_chance": _resolve_weapon_lifesteal_chance(attack_profile),
        "knockback_strength": _resolve_weapon_knockback_strength(attack_profile, family),
        "knockback_duration": _resolve_weapon_knockback_duration(attack_profile),
        "tip_forward_ratio": float(alignment.get("tip_forward_ratio", 0.9)),
        "grip_back_ratio": float(alignment.get("grip_back_ratio", 0.35)),
        "lateral_offset": float(alignment.get("lateral_offset", 0.0)),
        "melee_rotation_offset": float(alignment.get("melee_rotation_offset", PI)),
        "tip_forward_distance": tip_forward_distance,
        "grip_back_distance": float(alignment.get("grip_back_distance", 0.0)),
        "lateral_offset_distance": lateral_offset_distance,
        "fx_intensity": fx_intensity,
        "camera_punch_strength": camera_punch_strength,
        "impact_scale": impact_scale,
        "hit_pause_remaining": 0.0,
        "hit_pause_duration": hit_pause_duration,
        "has_triggered_primary_hit_fx": false,
        "sprite_base_scale": base_scale,
        "last_damage_point": current_global_point,
        "last_tip_global_position": current_global_point,
        "last_grip_global_position": _player.global_position + forward * max(4.0, rest_radius - float(alignment.get("grip_back_distance", 4.0))),
        "close_hit_extra_radius": MELEE_CLOSE_HIT_EXTRA_RADIUS,
        "hit_segment_thickness": max(6.0, hitbox_width * 0.72),
        "was_active": false,
        "hit_enemy_ids": {},
    }

func _resolve_melee_attack_family(weapon: Dictionary, attack_profile: Dictionary) -> String:
    var explicit_family: String = str(attack_profile.get("melee_family", "")).to_lower()
    if explicit_family == "thrust" or explicit_family == "sweep" or explicit_family == "heavy":
        return explicit_family
    var weapon_id: String = str(weapon.get("weapon_id", "")).to_lower()
    if MELEE_ATTACK_FAMILY_BY_WEAPON_ID.has(weapon_id):
        return str(MELEE_ATTACK_FAMILY_BY_WEAPON_ID.get(weapon_id, "sweep"))
    return "sweep"

func _resolve_melee_weapon_alignment(weapon_id: String, family: String, sprite: Sprite2D) -> Dictionary:
    var resolved_family: String = family if MELEE_ATTACK_ALIGNMENT_BY_FAMILY.has(family) else "sweep"
    var alignment: Dictionary = {}
    var family_value: Variant = MELEE_ATTACK_ALIGNMENT_BY_FAMILY.get(resolved_family, {})
    if family_value is Dictionary:
        alignment = (family_value as Dictionary).duplicate(true)
    var weapon_key: String = weapon_id.to_lower()
    var override_value: Variant = MELEE_ATTACK_ALIGNMENT_BY_WEAPON_ID.get(weapon_key, {})
    if override_value is Dictionary:
        for key in (override_value as Dictionary).keys():
            alignment[key] = (override_value as Dictionary)[key]
    if MELEE_ATTACK_ASSET_FORWARD_ANGLE_BY_WEAPON_ID.has(weapon_key):
        alignment["melee_rotation_offset"] = -float(MELEE_ATTACK_ASSET_FORWARD_ANGLE_BY_WEAPON_ID.get(weapon_key, PI))

    var base_scale: Vector2 = _resolve_weapon_orbit_base_scale(sprite)
    var texture_size: Vector2 = Vector2(WEAPON_ORBIT_ICON_TARGET_WIDTH, WEAPON_ORBIT_ICON_TARGET_WIDTH)
    if sprite != null and sprite.texture != null:
        texture_size = sprite.texture.get_size()
    var half_width: float = max(5.0, texture_size.x * absf(base_scale.x) * 0.5)
    var half_height: float = max(4.0, texture_size.y * absf(base_scale.y) * 0.5)
    var reach_unit: float = max(half_width, half_height)
    var thickness_unit: float = min(half_width, half_height)
    alignment["tip_forward_distance"] = max(6.0, reach_unit * float(alignment.get("tip_forward_ratio", 0.9)))
    alignment["grip_back_distance"] = max(2.0, reach_unit * float(alignment.get("grip_back_ratio", 0.35)))
    alignment["lateral_offset_distance"] = thickness_unit * float(alignment.get("lateral_offset", 0.0))
    alignment["melee_rotation_offset"] = float(alignment.get("melee_rotation_offset", PI))
    return alignment

func _tick_active_melee_attacks(delta: float) -> void:
    if _active_melee_attacks.is_empty():
        return
    if _player == null or not is_instance_valid(_player):
        _clear_active_melee_attacks()
        _reset_melee_camera_punch()
        return
    var active_slots: Array = _active_melee_attacks.keys().duplicate()
    for key in active_slots:
        var slot_index: int = int(key)
        var state_value: Variant = _active_melee_attacks.get(slot_index, null)
        if not (state_value is Dictionary):
            _finish_active_melee_attack(slot_index)
            continue
        var state: Dictionary = state_value
        var sprite_value: Variant = state.get("sprite", null)
        if not (sprite_value is Sprite2D) or not is_instance_valid(sprite_value as Sprite2D):
            _finish_active_melee_attack(slot_index)
            continue

        var hit_pause_remaining: float = max(0.0, float(state.get("hit_pause_remaining", 0.0)))
        if hit_pause_remaining > 0.0:
            state["hit_pause_remaining"] = max(0.0, hit_pause_remaining - delta)
            var paused_pose: Dictionary = _resolve_melee_attack_pose(state)
            _apply_melee_attack_pose(state, paused_pose)
            _active_melee_attacks[slot_index] = state
            continue

        var previous_elapsed: float = max(0.0, float(state.get("elapsed", 0.0)))
        var duration: float = max(0.001, float(state.get("duration", 0.0)))
        var raw_current_elapsed: float = previous_elapsed + max(0.0, delta)
        var current_elapsed: float = min(raw_current_elapsed, duration)
        var active_start_time: float = clampf(float(state.get("active_start_time", 0.0)), 0.0, duration)
        var active_end_time: float = clampf(float(state.get("active_end_time", duration)), active_start_time, duration)
        var frame_overlaps_active_window: bool = current_elapsed >= active_start_time and previous_elapsed <= active_end_time
        var attack_finished: bool = raw_current_elapsed >= duration

        state["elapsed"] = current_elapsed
        var pose: Dictionary = _resolve_melee_attack_pose(state)
        _apply_melee_attack_pose(state, pose)

        var current_damage_point: Vector2 = _player.global_position + Vector2(pose.get("damage_point_local", Vector2.ZERO))
        var current_tip_global: Vector2 = _player.global_position + Vector2(pose.get("tip_local_position", Vector2.ZERO))
        var current_grip_global: Vector2 = _player.global_position + Vector2(pose.get("grip_local_position", Vector2.ZERO))
        var was_active: bool = bool(state.get("was_active", false))
        if frame_overlaps_active_window:
            if not was_active or previous_elapsed < active_start_time:
                var start_state: Dictionary = state.duplicate()
                start_state["elapsed"] = max(previous_elapsed, active_start_time)
                var start_pose: Dictionary = _resolve_melee_attack_pose(start_state)
                state["last_damage_point"] = _player.global_position + Vector2(start_pose.get("damage_point_local", Vector2.ZERO))
                state["last_tip_global_position"] = _player.global_position + Vector2(start_pose.get("tip_local_position", Vector2.ZERO))
                state["last_grip_global_position"] = _player.global_position + Vector2(start_pose.get("grip_local_position", Vector2.ZERO))
            _apply_melee_attack_hits(state, current_damage_point, current_tip_global, current_grip_global, float(pose.get("damage_radius", 14.0)))
        else:
            state["last_damage_point"] = current_damage_point
            state["last_tip_global_position"] = current_tip_global
            state["last_grip_global_position"] = current_grip_global
        state["was_active"] = current_elapsed >= active_start_time and current_elapsed <= active_end_time
        _active_melee_attacks[slot_index] = state
        if attack_finished:
            _finish_active_melee_attack(slot_index)

func _resolve_melee_attack_pose(state: Dictionary) -> Dictionary:
    var family: String = str(state.get("family", "sweep"))
    var progress: float = clampf(float(state.get("elapsed", 0.0)) / max(0.001, float(state.get("duration", 0.001))), 0.0, 1.0)
    var base_angle: float = float(state.get("base_angle", 0.0))
    var attack_radius: float = float(state.get("attack_radius", 64.0))
    var rest_radius: float = float(state.get("rest_radius", 18.0))
    var hitbox_length: float = float(state.get("hitbox_length", 20.0))
    var hitbox_width: float = float(state.get("hitbox_width", 16.0))
    var tip_forward_distance: float = float(state.get("tip_forward_distance", 10.0))
    var grip_back_distance: float = float(state.get("grip_back_distance", 4.0))
    var lateral_offset_distance: float = float(state.get("lateral_offset_distance", 0.0))
    var melee_rotation_offset: float = float(state.get("melee_rotation_offset", PI))

    var tip_local_position: Vector2 = Vector2.RIGHT.rotated(base_angle) * (rest_radius + tip_forward_distance)
    var forward: Vector2 = tip_local_position.normalized() if tip_local_position.length_squared() > 0.0001 else Vector2.RIGHT.rotated(base_angle)
    var rotation: float = forward.angle() + melee_rotation_offset
    var sprite_forward: Vector2 = Vector2.RIGHT.rotated(rotation)
    var sprite_side: Vector2 = sprite_forward.orthogonal()
    var local_position: Vector2 = tip_local_position - sprite_forward * tip_forward_distance - sprite_side * lateral_offset_distance
    var grip_local_position: Vector2 = local_position - sprite_forward * grip_back_distance + sprite_side * lateral_offset_distance
    var scale_mult: Vector2 = Vector2.ONE
    var damage_point_local: Vector2 = tip_local_position
    var damage_radius: float = max(8.0, hitbox_width * 0.5)
    var flash_blend: float = 0.22

    match family:
        "thrust":
            var thrust_progress: float
            if progress < 0.38:
                thrust_progress = _ease_out_cubic(progress / 0.38)
            else:
                thrust_progress = 1.0 - _ease_in_cubic((progress - 0.38) / 0.62)
            thrust_progress = clampf(thrust_progress, 0.0, 1.0)
            forward = Vector2.RIGHT.rotated(base_angle)
            var thrust_distance: float = lerpf(rest_radius, attack_radius, thrust_progress)
            tip_local_position = forward * (thrust_distance + tip_forward_distance)
            rotation = base_angle + melee_rotation_offset
            sprite_forward = Vector2.RIGHT.rotated(rotation)
            sprite_side = sprite_forward.orthogonal()
            local_position = tip_local_position - sprite_forward * tip_forward_distance - sprite_side * lateral_offset_distance
            grip_local_position = local_position - sprite_forward * grip_back_distance + sprite_side * lateral_offset_distance
            scale_mult = Vector2(lerpf(0.94, 1.12, thrust_progress), lerpf(1.02, 0.9, thrust_progress))
            damage_point_local = tip_local_position + forward * min(hitbox_length * 0.12, max(2.0, tip_forward_distance * 0.1))
            damage_radius = max(8.0, hitbox_width * 0.5)
            flash_blend = 0.24 + thrust_progress * 0.42
        "heavy":
            var heavy_windup_ratio: float = 0.34
            var heavy_strike_ratio: float = 0.72
            var heavy_angle: float = base_angle
            var heavy_radius: float = rest_radius
            var impact_strength: float = 0.0
            if progress < heavy_windup_ratio:
                var windup_t: float = _ease_out_quad(progress / heavy_windup_ratio)
                heavy_angle = lerp_angle(base_angle + 0.34, float(state.get("windup_angle", base_angle - 1.0)), windup_t)
                heavy_radius = lerpf(rest_radius * 0.96, attack_radius * 0.72, windup_t)
            elif progress < heavy_strike_ratio:
                var strike_t: float = _ease_in_cubic((progress - heavy_windup_ratio) / (heavy_strike_ratio - heavy_windup_ratio))
                heavy_angle = lerp_angle(float(state.get("windup_angle", base_angle - 1.0)), float(state.get("impact_angle", base_angle + 0.15)), strike_t)
                heavy_radius = lerpf(attack_radius * 0.72, attack_radius * 1.04, strike_t)
                impact_strength = strike_t
            else:
                var recover_t: float = _ease_out_quad((progress - heavy_strike_ratio) / (1.0 - heavy_strike_ratio))
                heavy_angle = lerp_angle(float(state.get("impact_angle", base_angle + 0.15)), float(state.get("recover_angle", base_angle - 0.08)), recover_t)
                heavy_radius = lerpf(attack_radius * 1.04, rest_radius * 1.02, recover_t)
                impact_strength = 1.0 - recover_t * 0.45
            forward = Vector2.RIGHT.rotated(heavy_angle)
            tip_local_position = forward * (heavy_radius + tip_forward_distance)
            rotation = heavy_angle + melee_rotation_offset
            sprite_forward = Vector2.RIGHT.rotated(rotation)
            sprite_side = sprite_forward.orthogonal()
            local_position = tip_local_position - sprite_forward * tip_forward_distance - sprite_side * lateral_offset_distance
            grip_local_position = local_position - sprite_forward * grip_back_distance + sprite_side * lateral_offset_distance
            var settle_pulse: float = sin(clampf((progress - heavy_windup_ratio) / max(0.001, 1.0 - heavy_windup_ratio), 0.0, 1.0) * PI)
            scale_mult = Vector2(1.0 + impact_strength * 0.26, 1.0 + impact_strength * 0.1 + settle_pulse * 0.04)
            damage_point_local = tip_local_position - forward * min(hitbox_length * 0.1, max(2.0, tip_forward_distance * 0.08))
            damage_radius = max(12.0, hitbox_width * lerpf(0.85, 1.18, impact_strength) * 0.5)
            flash_blend = 0.16 + impact_strength * 0.56
        _:
            var sweep_angle: float = lerp_angle(float(state.get("sweep_from", base_angle - 0.8)), float(state.get("sweep_to", base_angle + 0.8)), _ease_in_out_sine(progress))
            forward = Vector2.RIGHT.rotated(sweep_angle)
            var sweep_radius: float = attack_radius * (1.0 + 0.04 * sin(progress * PI))
            tip_local_position = forward * (sweep_radius + tip_forward_distance)
            rotation = sweep_angle + melee_rotation_offset
            sprite_forward = Vector2.RIGHT.rotated(rotation)
            sprite_side = sprite_forward.orthogonal()
            local_position = tip_local_position - sprite_forward * tip_forward_distance - sprite_side * lateral_offset_distance
            grip_local_position = local_position - sprite_forward * grip_back_distance + sprite_side * lateral_offset_distance
            scale_mult = Vector2(1.0 + 0.07 * sin(progress * PI), 1.0 + 0.02 * sin(progress * PI))
            damage_point_local = tip_local_position
            damage_radius = max(10.0, hitbox_width * 0.52)
            flash_blend = 0.18 + 0.3 * sin(progress * PI)

    return {
        "local_position": local_position,
        "tip_local_position": tip_local_position,
        "grip_local_position": grip_local_position,
        "rotation": rotation,
        "scale_mult": scale_mult,
        "damage_point_local": damage_point_local,
        "damage_radius": damage_radius,
        "flash_blend": clampf(flash_blend, 0.0, 1.0),
    }

func _apply_melee_attack_pose(state: Dictionary, pose: Dictionary) -> void:
    var sprite_value: Variant = state.get("sprite", null)
    if not (sprite_value is Sprite2D):
        return
    var sprite: Sprite2D = sprite_value
    if not is_instance_valid(sprite):
        return
    sprite.position = Vector2(pose.get("local_position", Vector2.ZERO))
    sprite.rotation = float(pose.get("rotation", 0.0))
    var base_scale: Vector2 = state.get("sprite_base_scale", _resolve_weapon_orbit_base_scale(sprite))
    var scale_mult: Vector2 = pose.get("scale_mult", Vector2.ONE)
    sprite.scale = Vector2(base_scale.x * scale_mult.x, base_scale.y * scale_mult.y)
    var flash_blend: float = float(pose.get("flash_blend", 0.0))
    sprite.modulate = MELEE_ATTACK_BASE_TINT.lerp(MELEE_ATTACK_FLASH_TINT, flash_blend)
    sprite.z_index = MELEE_ATTACK_ACTIVE_Z_INDEX

func _apply_melee_attack_hits(
    state: Dictionary,
    current_damage_point: Vector2,
    current_tip_global: Vector2,
    current_grip_global: Vector2,
    damage_radius: float
) -> void:
    if _player == null or not is_instance_valid(_player):
        return
    var previous_damage_point: Vector2 = state.get("last_damage_point", current_damage_point)
    var previous_tip_global: Vector2 = state.get("last_tip_global_position", current_tip_global)
    var previous_grip_global: Vector2 = state.get("last_grip_global_position", current_grip_global)
    var segment_thickness: float = max(damage_radius, float(state.get("hit_segment_thickness", damage_radius)))
    var hit_enemy_ids: Dictionary = {}
    var hit_ids_value: Variant = state.get("hit_enemy_ids", {})
    if hit_ids_value is Dictionary:
        hit_enemy_ids = hit_ids_value
    var any_hit: bool = false
    for enemy: Enemy in _enemies:
        if not _is_enemy_combat_active(enemy):
            continue
        var enemy_id: int = enemy.get_instance_id()
        if hit_enemy_ids.has(enemy_id):
            continue
        var effective_radius: float = segment_thickness + enemy.body_radius
        var contact_info: Dictionary = _resolve_melee_enemy_contact(
            enemy.global_position,
            previous_grip_global,
            previous_tip_global,
            current_grip_global,
            current_tip_global
        )
        if float(contact_info.get("distance_sq", INF)) > effective_radius * effective_radius:
            var close_contact_info: Dictionary = _resolve_melee_close_enemy_contact(enemy, state)
            if not bool(close_contact_info.get("hit", false)):
                continue
            contact_info = close_contact_info
        var damage_result: Dictionary = _player.roll_outgoing_damage_result(
            int(state.get("base_damage", 1)),
            _player.crit_chance,
            float(state.get("crit_multiplier", 1.5))
        )
        var dealt_damage: int = enemy.take_damage(int(damage_result.get("damage", 1)))
        hit_enemy_ids[enemy_id] = true
        if dealt_damage > 0:
            _player.try_lifesteal_on_hit(float(state.get("lifesteal_chance", 0.0)))
            var is_primary_hit: bool = not bool(state.get("has_triggered_primary_hit_fx", false))
            var hit_direction: Vector2 = current_damage_point - previous_damage_point
            if hit_direction.length_squared() <= 0.0001:
                hit_direction = _player.global_position.direction_to(enemy.global_position)
            var impact_position: Vector2 = contact_info.get("closest_point", current_damage_point.lerp(enemy.global_position, 0.65))
            _apply_weapon_knockback(
                enemy,
                _player.global_position.direction_to(enemy.global_position),
                float(state.get("knockback_strength", 0.0)),
                float(state.get("knockback_duration", 0.0))
            )
            _spawn_damage_popup(impact_position, dealt_damage, bool(damage_result.get("is_crit", false)))
            _spawn_melee_hit_effect(
                impact_position,
                hit_direction,
                str(state.get("family", "sweep")),
                is_primary_hit,
                float(state.get("fx_intensity", 1.0)),
                float(state.get("impact_scale", 1.0))
            )
            if is_primary_hit:
                state["has_triggered_primary_hit_fx"] = true
                state["hit_pause_remaining"] = float(state.get("hit_pause_duration", 0.022))
                _apply_melee_camera_punch(hit_direction, float(state.get("camera_punch_strength", 1.0)))
        any_hit = true
    state["hit_enemy_ids"] = hit_enemy_ids
    state["last_damage_point"] = current_damage_point
    state["last_tip_global_position"] = current_tip_global
    state["last_grip_global_position"] = current_grip_global
    if any_hit:
        _cleanup_dead_enemies()

func _is_melee_attack_window_active(state: Dictionary) -> bool:
    var elapsed: float = float(state.get("elapsed", 0.0))
    return elapsed >= float(state.get("active_start_time", 0.0)) and elapsed <= float(state.get("active_end_time", 0.0))

func _finish_active_melee_attack(slot_index: int) -> void:
    if not _active_melee_attacks.has(slot_index):
        return
    var cooldown_after_finish: float = 0.0
    var state_value: Variant = _active_melee_attacks.get(slot_index, null)
    if state_value is Dictionary:
        var state: Dictionary = state_value
        cooldown_after_finish = max(0.0, float(state.get("cooldown_after_finish", 0.0)))
        var sprite_value: Variant = state.get("sprite", null)
        if sprite_value is Sprite2D:
            var sprite: Sprite2D = sprite_value
            if is_instance_valid(sprite):
                sprite.scale = state.get("sprite_base_scale", _resolve_weapon_orbit_base_scale(sprite))
                sprite.modulate = WEAPON_ORBIT_BASE_TINT
                sprite.z_index = 2
    _active_melee_attacks.erase(slot_index)
    _weapon_orbit_flash_timers.erase(slot_index)
    _weapon_targets.erase(slot_index)
    if cooldown_after_finish > 0.0:
        _weapon_cooldowns[slot_index] = cooldown_after_finish

func _clear_active_melee_attacks() -> void:
    var active_slots: Array = _active_melee_attacks.keys().duplicate()
    for key in active_slots:
        _finish_active_melee_attack(int(key))
    _active_melee_attacks.clear()

func _tick_melee_camera_punch(delta: float) -> void:
    if _player_camera == null or not is_instance_valid(_player_camera):
        _melee_camera_punch_offset = Vector2.ZERO
        _melee_camera_punch_velocity = Vector2.ZERO
        return
    _melee_camera_punch_offset += _melee_camera_punch_velocity * delta
    _melee_camera_punch_offset = _melee_camera_punch_offset.lerp(Vector2.ZERO, clampf(delta * MELEE_CAMERA_PUNCH_RETURN_SPEED, 0.0, 1.0))
    _melee_camera_punch_velocity = _melee_camera_punch_velocity.lerp(Vector2.ZERO, clampf(delta * MELEE_CAMERA_PUNCH_DAMPING, 0.0, 1.0))
    if _melee_camera_punch_offset.length_squared() <= 0.0004 and _melee_camera_punch_velocity.length_squared() <= 0.0004:
        _melee_camera_punch_offset = Vector2.ZERO
        _melee_camera_punch_velocity = Vector2.ZERO
    _player_camera.offset = _melee_camera_punch_offset

func _apply_melee_camera_punch(hit_direction: Vector2, strength: float) -> void:
    if _player_camera == null or not is_instance_valid(_player_camera):
        return
    var forward: Vector2 = hit_direction.normalized()
    if forward.length_squared() <= 0.0001:
        forward = Vector2.RIGHT
    var side: Vector2 = forward.orthogonal()
    var clamped_strength: float = clampf(strength, 0.4, 3.2)
    _melee_camera_punch_offset += -forward * (clamped_strength * 0.85)
    _melee_camera_punch_velocity += -forward * (clamped_strength * 68.0) + side * randf_range(-1.0, 1.0) * clamped_strength * 14.0

func _reset_melee_camera_punch() -> void:
    _melee_camera_punch_offset = Vector2.ZERO
    _melee_camera_punch_velocity = Vector2.ZERO
    if _player_camera != null and is_instance_valid(_player_camera):
        _player_camera.offset = Vector2.ZERO

func _resolve_melee_close_enemy_contact(enemy: Enemy, state: Dictionary) -> Dictionary:
    if _player == null or not is_instance_valid(_player):
        return {"hit": false}
    if not _is_enemy_combat_active(enemy):
        return {"hit": false}
    var to_enemy: Vector2 = enemy.global_position - _player.global_position
    var distance: float = to_enemy.length()
    var close_radius: float = _player.body_radius + enemy.body_radius + float(state.get("close_hit_extra_radius", MELEE_CLOSE_HIT_EXTRA_RADIUS))
    if distance > close_radius:
        return {"hit": false}
    var omni_close_radius: float = _player.body_radius + enemy.body_radius + MELEE_CLOSE_HIT_OMNI_EXTRA_RADIUS
    var attack_direction: Vector2 = Vector2(state.get("direction", Vector2.RIGHT)).normalized()
    if attack_direction.length_squared() <= 0.0001:
        attack_direction = Vector2.RIGHT
    var enemy_direction: Vector2 = to_enemy.normalized()
    if distance > omni_close_radius and enemy_direction.length_squared() > 0.0001 and enemy_direction.dot(attack_direction) < MELEE_CLOSE_HIT_MIN_DOT:
        return {"hit": false}
    var impact_direction: Vector2 = enemy_direction if enemy_direction.length_squared() > 0.0001 else attack_direction
    var closest_point: Vector2 = _player.global_position + impact_direction * min(_player.body_radius + 2.0, max(2.0, distance * 0.5))
    return {
        "hit": true,
        "distance_sq": 0.0,
        "closest_point": closest_point,
    }

func _distance_squared_point_to_segment(point: Vector2, segment_from: Vector2, segment_to: Vector2) -> float:
    var ab: Vector2 = segment_to - segment_from
    var ab_length_sq: float = ab.length_squared()
    if ab_length_sq <= 0.0001:
        return point.distance_squared_to(segment_from)
    var t: float = clampf((point - segment_from).dot(ab) / ab_length_sq, 0.0, 1.0)
    var closest: Vector2 = segment_from + ab * t
    return point.distance_squared_to(closest)

func _closest_point_on_segment(point: Vector2, segment_from: Vector2, segment_to: Vector2) -> Vector2:
    var ab: Vector2 = segment_to - segment_from
    var ab_length_sq: float = ab.length_squared()
    if ab_length_sq <= 0.0001:
        return segment_from
    var t: float = clampf((point - segment_from).dot(ab) / ab_length_sq, 0.0, 1.0)
    return segment_from + ab * t

func _resolve_melee_enemy_contact(
    enemy_position: Vector2,
    previous_grip_global: Vector2,
    previous_tip_global: Vector2,
    current_grip_global: Vector2,
    current_tip_global: Vector2
) -> Dictionary:
    var candidates: Array[Array] = [
        [current_grip_global, current_tip_global],
        [previous_tip_global, current_tip_global],
        [previous_grip_global, current_grip_global],
        [(previous_grip_global + previous_tip_global) * 0.5, (current_grip_global + current_tip_global) * 0.5],
    ]
    var best_distance_sq: float = INF
    var best_point: Vector2 = current_tip_global
    for candidate in candidates:
        var from_point: Vector2 = candidate[0]
        var to_point: Vector2 = candidate[1]
        var closest_point: Vector2 = _closest_point_on_segment(enemy_position, from_point, to_point)
        var distance_sq: float = enemy_position.distance_squared_to(closest_point)
        if distance_sq < best_distance_sq:
            best_distance_sq = distance_sq
            best_point = closest_point
    return {
        "distance_sq": best_distance_sq,
        "closest_point": best_point,
    }

func _ease_out_cubic(value: float) -> float:
    var t: float = clampf(value, 0.0, 1.0)
    return 1.0 - pow(1.0 - t, 3.0)

func _ease_in_cubic(value: float) -> float:
    var t: float = clampf(value, 0.0, 1.0)
    return t * t * t

func _ease_out_quad(value: float) -> float:
    var t: float = clampf(value, 0.0, 1.0)
    return 1.0 - (1.0 - t) * (1.0 - t)

func _ease_in_out_sine(value: float) -> float:
    var t: float = clampf(value, 0.0, 1.0)
    return -(cos(PI * t) - 1.0) * 0.5

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
            var attack_profile: Dictionary = _resolve_attack_profile(weapon)
            if str(attack_profile.get("mode", "ranged_homing")) == "melee_arc":
                synced_cooldowns[slot_index] = _resolve_weapon_effective_interval(attack_profile)
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
    
    var count: int = active_slots.size()
    # User requested: no rotation effect.
    _weapon_orbit_angle = 0.0
        
    var radius: float = _resolve_weapon_orbit_radius(count)
    var lerp_weight: float = clampf(delta * WEAPON_ORBIT_SMOOTHING_SPEED, 0.0, 1.0)
    
    for i: int in range(count):
        var slot_index: int = active_slots[i]
        var sprite: Sprite2D = _weapon_orbit_nodes[slot_index]
        if not is_instance_valid(sprite):
            continue
        if _active_melee_attacks.has(slot_index):
            continue
            
        # Brotato-style circular distribution
        var target_angle: float = (float(i) / float(count)) * TAU + _weapon_orbit_angle
        var target_local_pos: Vector2 = Vector2.RIGHT.rotated(target_angle) * radius
        sprite.position = sprite.position.lerp(target_local_pos, lerp_weight)
        
        # Point towards specific target or general aim direction
        var aim_dir: Vector2 = _resolve_slot_aim_direction(slot_index, sprite.global_position)
        var target_rotation: float = aim_dir.angle() + PI
        sprite.rotation = lerp_angle(sprite.rotation, target_rotation, lerp_weight)
        
        # Flash effect
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

func _resolve_slot_aim_direction(slot_index: int, from_pos: Vector2) -> Vector2:
    # Check if this slot has a specific target
    var specific_target: Variant = _weapon_targets.get(slot_index, null)
    if _is_enemy_combat_active(specific_target):
        var target_enemy: Enemy = specific_target
        return from_pos.direction_to(target_enemy.global_position).normalized()
    
    # Fallback to general nearest enemy or movement
    var nearest: Enemy = _find_nearest_enemy_any_distance()
    if nearest != null:
        return from_pos.direction_to(nearest.global_position).normalized()
        
    return _resolve_weapon_orbit_aim_direction()

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
    _clear_active_melee_attacks()
    _reset_melee_camera_punch()
    var existing_slots: Array = _weapon_orbit_nodes.keys().duplicate()
    for key in existing_slots:
        _remove_weapon_orbit_slot(int(key))
    _weapon_orbit_nodes.clear()
    _weapon_orbit_signatures.clear()
    _weapon_orbit_flash_timers.clear()
    _weapon_orbit_angle = 0.0
    _weapon_targets.clear()
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
    _finish_active_melee_attack(slot_index)
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

func _get_weapon_projectile_texture(weapon: Dictionary, attack_profile: Dictionary) -> Texture2D:
    var explicit_path: String = str(attack_profile.get("weapon_projectile_texture_path", ""))
    if not explicit_path.is_empty() and ResourceLoader.exists(explicit_path):
        return load(explicit_path) as Texture2D
    var weapon_id: String = str(weapon.get("weapon_id", ""))
    if weapon_id.is_empty():
        weapon_id = str(attack_profile.get("weapon_id", ""))
    return _get_weapon_orbit_texture(weapon_id)

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
    var factor: float = clampf(WEAPON_ORBIT_ICON_TARGET_WIDTH / raw_size.x, 0.02, 1.8)
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

func _spawn_melee_arc_effect(target_position: Vector2, attack_profile: Dictionary, family: String = "sweep", duration: float = 0.11) -> void:
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
    var effect_radius: float = profile_range * 0.85
    var effect_width: float = 8.0
    var tint: Color = Color(0.9, 0.98, 1.0, 0.92)
    var intensity: float = 1.0
    match family:
        "thrust":
            effect_radius = profile_range * 0.94
            effect_width = 6.5
            arc_width = clampf(arc_width * 0.58, 0.22, 1.0)
            tint = Color(0.86, 0.97, 1.0, 0.9)
            intensity = 0.95
        "heavy":
            effect_radius = profile_range * 0.82
            effect_width = 11.0
            arc_width = clampf(arc_width * 0.86, 0.65, 1.75)
            tint = Color(0.92, 0.98, 1.0, 0.96)
            intensity = 1.18
        _:
            intensity = 1.0
    if effect.has_method("configure"):
        effect.call(
            "configure",
            direction.angle(),
            effect_radius,
            arc_width,
            effect_width,
            tint,
            duration,
            family,
            intensity
        )

func _spawn_melee_hit_effect(
    hit_position: Vector2,
    hit_direction: Vector2,
    family: String,
    is_primary_hit: bool,
    intensity: float,
    impact_scale: float
) -> void:
    if _player == null or not is_instance_valid(_player):
        return
    var effect: Node2D = MELEE_HIT_EFFECT_SCRIPT.new() as Node2D
    if effect == null:
        return
    effect.global_position = hit_position
    add_child(effect)
    if effect.has_method("configure"):
        effect.call(
            "configure",
            family,
            hit_direction,
            is_primary_hit,
            intensity if is_primary_hit else intensity * 0.74,
            impact_scale if is_primary_hit else impact_scale * 0.82,
            Color(0.05, 0.26, 0.42, 0.72),
            Color(0.48, 0.95, 1.0, 1.0),
            Color(0.98, 1.0, 1.0, 1.0)
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
        if projectile.is_aoe_projectile() and projectile.consume_impact_request():
            _explode_projectile_aoe(projectile, Vector2.ZERO)
            continue
        for enemy: Enemy in _enemies:
            if not _is_enemy_combat_active(enemy):
                continue
            if projectile.is_bounce_weapon_projectile() and projectile.has_hit_enemy(enemy.get_instance_id()):
                continue
            var hit_distance: float = projectile.hit_radius + enemy.body_radius
            if projectile.global_position.distance_squared_to(enemy.global_position) <= hit_distance * hit_distance:
                var impact_direction: Vector2 = enemy.global_position - projectile.global_position
                if projectile.is_aoe_projectile():
                    _explode_projectile_aoe(projectile, impact_direction)
                    break
                var projectile_owner: Player = projectile.owner_player
                var outgoing_damage: int = projectile.damage
                var is_crit: bool = false
                if projectile_owner != null and is_instance_valid(projectile_owner):
                    var damage_result: Dictionary = projectile_owner.roll_outgoing_damage_result(
                        projectile.damage,
                        projectile.crit_chance,
                        projectile.crit_multiplier
                    )
                    outgoing_damage = int(damage_result.get("damage", projectile.damage))
                    is_crit = bool(damage_result.get("is_crit", false))
                var dealt_damage: int = enemy.take_damage(outgoing_damage)
                if dealt_damage > 0:
                    _apply_weapon_knockback(enemy, impact_direction, projectile.knockback_strength, projectile.knockback_duration)
                    _spawn_damage_popup(enemy.global_position, dealt_damage, is_crit)
                if projectile_owner != null and is_instance_valid(projectile_owner):
                    projectile_owner.heal_from_lifesteal(dealt_damage, projectile.lifesteal_chance)
                if projectile.is_bounce_weapon_projectile():
                    projectile.register_hit_enemy(enemy.get_instance_id())
                    var next_target: Enemy = _find_next_bounce_target(projectile, enemy)
                    if next_target != null:
                        projectile.spawn_impact_fx(impact_direction)
                        projectile.bounce_to(next_target)
                        break
                projectile.despawn(true, impact_direction)
                break
    _cleanup_dead_enemies()

func _find_next_bounce_target(projectile: Projectile, current_enemy: Enemy) -> Enemy:
    if projectile == null or not is_instance_valid(projectile):
        return null
    if not projectile.can_bounce():
        return null
    var origin: Vector2 = current_enemy.global_position if _is_enemy_combat_active(current_enemy) else projectile.global_position
    var best_enemy: Enemy = null
    var best_dist_sq: float = projectile.bounce_range * projectile.bounce_range
    for enemy: Enemy in _enemies:
        if not _is_enemy_combat_active(enemy):
            continue
        if enemy == current_enemy:
            continue
        if projectile.has_hit_enemy(enemy.get_instance_id()):
            continue
        var dist_sq: float = origin.distance_squared_to(enemy.global_position)
        if dist_sq <= best_dist_sq:
            best_dist_sq = dist_sq
            best_enemy = enemy
    return best_enemy

func _explode_projectile_aoe(projectile: Projectile, impact_direction: Vector2) -> void:
    if projectile == null or not is_instance_valid(projectile):
        return
    var explosion_position: Vector2 = projectile.global_position
    var explosion_radius: float = max(projectile.hit_radius, projectile.aoe_radius)
    var projectile_owner: Player = projectile.owner_player
    if (projectile_owner == null or not is_instance_valid(projectile_owner)) and _player != null and is_instance_valid(_player):
        projectile_owner = _player
    for enemy: Enemy in _enemies:
        if not _is_enemy_combat_active(enemy):
            continue
        var hit_distance: float = explosion_radius + enemy.body_radius
        if explosion_position.distance_squared_to(enemy.global_position) > hit_distance * hit_distance:
            continue
        var outgoing_damage: int = projectile.damage
        var is_crit: bool = false
        if projectile_owner != null and is_instance_valid(projectile_owner):
            var damage_result: Dictionary = projectile_owner.roll_outgoing_damage_result(
                projectile.damage,
                projectile.crit_chance,
                projectile.crit_multiplier
            )
            outgoing_damage = int(damage_result.get("damage", projectile.damage))
            is_crit = bool(damage_result.get("is_crit", false))
        var dealt_damage: int = enemy.take_damage(outgoing_damage)
        if dealt_damage > 0:
            var knockback_direction: Vector2 = enemy.global_position - explosion_position
            var distance_ratio: float = clampf(knockback_direction.length() / max(1.0, explosion_radius), 0.0, 1.0)
            var knockback_falloff: float = lerpf(1.0, AOE_KNOCKBACK_MIN_RATIO, distance_ratio)
            _apply_weapon_knockback(
                enemy,
                knockback_direction,
                projectile.knockback_strength * knockback_falloff,
                projectile.knockback_duration
            )
            _spawn_damage_popup(enemy.global_position, dealt_damage, is_crit)
        if projectile_owner != null and is_instance_valid(projectile_owner):
            projectile_owner.heal_from_lifesteal(dealt_damage, projectile.lifesteal_chance)
    projectile.despawn(true, impact_direction)

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
        var base_damage: int = max(1, int(shot.get("damage", 1)))
        var shooter_enemy: Enemy = shooter_value as Enemy
        if shooter_enemy != null:
            projectile.damage = shooter_enemy.scale_outgoing_damage(base_damage)
        else:
            projectile.damage = _scale_enemy_damage(base_damage)
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
            projectile.despawn(true, _player.global_position - projectile.global_position)
            _refresh_player_hud()
            if _is_game_over:
                return

func _handle_enemy_contact_damage() -> void :
    if _player == null or not is_instance_valid(_player):
        return
    if _contact_damage_timer > 0.0:
        return
    var contact_damage: int = 0
    for enemy: Enemy in _enemies:
        if not _is_enemy_combat_active(enemy):
            continue
        var contact_distance: float = enemy.body_radius + _player.body_radius + 2.0
        if enemy.global_position.distance_squared_to(_player.global_position) <= contact_distance * contact_distance:
            var enemy_contact_damage: int = _scale_enemy_damage(_contact_damage_runtime)
            if enemy.contact_damage_override > 0:
                enemy_contact_damage = enemy.scale_outgoing_damage(enemy.contact_damage_override)
            contact_damage = max(contact_damage, enemy_contact_damage)
    if contact_damage <= 0:
        return
    _contact_damage_timer = _contact_damage_interval_runtime
    _player.take_damage(contact_damage)
    _refresh_player_hud()

func _get_enemy_damage_scale() -> float:
    return max(0.1, _enemy_damage_multiplier * _enemy_damage_stage_multiplier * _get_endless_damage_multiplier())

func _scale_enemy_damage(base_damage: int) -> int:
    return max(1, int(round(float(max(1, base_damage)) * _get_enemy_damage_scale())))

func _refresh_endless_level() -> void:
    if not _is_endless_mode:
        return
    _endless_level = max(0, int(floor(_endless_elapsed / ENDLESS_LEVEL_INTERVAL)))

func _get_endless_hp_multiplier() -> float:
    if not _is_endless_mode:
        return 1.0
    return 1.0 + float(_endless_level) * ENDLESS_HP_PER_LEVEL

func _get_endless_damage_multiplier() -> float:
    if not _is_endless_mode:
        return 1.0
    return 1.0 + float(_endless_level) * ENDLESS_DAMAGE_PER_LEVEL

func _get_endless_speed_multiplier() -> float:
    if not _is_endless_mode:
        return 1.0
    return min(ENDLESS_SPEED_MULT_CAP, 1.0 + float(_endless_level) * ENDLESS_SPEED_PER_LEVEL)

func _get_endless_spawn_interval_multiplier() -> float:
    if not _is_endless_mode:
        return 1.0
    return max(0.2, 1.0 - float(_endless_level) * ENDLESS_SPAWN_INTERVAL_REDUCTION_PER_LEVEL)

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
            var multiplier: int = 1
            if GameManager.recycling_bag_amount > 0:
                multiplier = 2
                GameManager.recycling_bag_amount -= 1
                _spawn_double_pickup_hint(orb.global_position)
                if hud != null and hud.has_method("refresh_recycling_bag"):
                    hud.call("refresh_recycling_bag")

            _add_experience(orb.xp_value * multiplier)
            if orb.gold_value > 0:
                _add_gold(orb.gold_value * multiplier)
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

func _clear_consumables() -> void:
    for drop: ConsumableDrop in _consumables:
        if drop != null and is_instance_valid(drop):
            drop.queue_free()
    _consumables.clear()

func _clear_player_projectiles() -> void:
    for projectile: Projectile in _projectiles:
        if projectile != null and is_instance_valid(projectile):
            projectile.queue_free()
    _projectiles.clear()

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
    if not _stage_is_boss_stage:
        return
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
    _refresh_pause_summary()
    resume_button.pressed.connect(_on_resume_button_pressed)
    main_menu_button.pressed.connect(_on_main_menu_button_pressed)
    save_button.pressed.connect(_on_save_button_pressed)
    settings_button.pressed.connect(_on_settings_button_pressed)

func _refresh_pause_summary() -> void:
    _refresh_pause_character_summary()
    _refresh_pause_weapon_summary()
    _refresh_pause_item_summary()
    _refresh_pause_stat_summary()

func _refresh_pause_character_summary() -> void:
    var character_id: String = _current_player_id
    if character_id.is_empty():
        character_id = GameManager.selected_character
    if character_id.is_empty():
        character_id = "the_fool"
    if pause_character_name_label != null:
        pause_character_name_label.text = _tx("data.character.%s.name" % character_id, character_id)
    if pause_character_preview == null:
        return
    var sheet_path: String = str(CHARACTER_BATTLE_SHEET_PATHS.get(character_id, ""))
    if sheet_path.is_empty() or not ResourceLoader.exists(sheet_path):
        pause_character_preview.texture = null
        _pause_character_preview_frames.clear()
        return
    var sheet_texture: Texture2D = load(sheet_path) as Texture2D
    _pause_character_preview_frames = _build_pause_character_preview_frames(sheet_texture, character_id)
    _pause_character_preview_time = 0.0
    _pause_character_preview_frame_index = 0
    _apply_pause_character_preview_frame()

func _build_pause_character_preview_frames(sheet_texture: Texture2D, character_id: String = "") -> Array[Texture2D]:
    var frames: Array[Texture2D] = []
    if sheet_texture == null:
        return frames
    var preview_offsets: Dictionary = {}
    var preview_offsets_value: Variant = CHARACTER_PREVIEW_FRAME_OFFSETS.get(character_id, {})
    if preview_offsets_value is Dictionary:
        preview_offsets = preview_offsets_value
    var source_image: Image = sheet_texture.get_image()
    for frame_index: int in range(8):
        if source_image == null or source_image.is_empty() or preview_offsets.is_empty():
            var frame_texture: AtlasTexture = AtlasTexture.new()
            frame_texture.atlas = sheet_texture
            frame_texture.region = Rect2(
                PAUSE_CHARACTER_PREVIEW_FRAME_SIZE.x * float(frame_index),
                0.0,
                PAUSE_CHARACTER_PREVIEW_FRAME_SIZE.x,
                PAUSE_CHARACTER_PREVIEW_FRAME_SIZE.y
            )
            frames.append(frame_texture)
            continue
        var frame_image: Image = Image.create(
            int(PAUSE_CHARACTER_PREVIEW_FRAME_SIZE.x),
            int(PAUSE_CHARACTER_PREVIEW_FRAME_SIZE.y),
            false,
            Image.FORMAT_RGBA8
        )
        frame_image.fill(Color.TRANSPARENT)
        var offset: Vector2i = Vector2i(
            int(round(float(Vector2(preview_offsets.get(frame_index, Vector2.ZERO)).x))),
            int(round(float(Vector2(preview_offsets.get(frame_index, Vector2.ZERO)).y)))
        )
        var frame_size: Vector2i = Vector2i(
            int(PAUSE_CHARACTER_PREVIEW_FRAME_SIZE.x),
            int(PAUSE_CHARACTER_PREVIEW_FRAME_SIZE.y)
        )
        var src_pos: Vector2i = Vector2i(int(PAUSE_CHARACTER_PREVIEW_FRAME_SIZE.x) * frame_index, 0)
        var dst_pos: Vector2i = offset
        if dst_pos.x < 0:
            src_pos.x -= dst_pos.x
            frame_size.x += dst_pos.x
            dst_pos.x = 0
        if dst_pos.y < 0:
            src_pos.y -= dst_pos.y
            frame_size.y += dst_pos.y
            dst_pos.y = 0
        if dst_pos.x + frame_size.x > int(PAUSE_CHARACTER_PREVIEW_FRAME_SIZE.x):
            frame_size.x = int(PAUSE_CHARACTER_PREVIEW_FRAME_SIZE.x) - dst_pos.x
        if dst_pos.y + frame_size.y > int(PAUSE_CHARACTER_PREVIEW_FRAME_SIZE.y):
            frame_size.y = int(PAUSE_CHARACTER_PREVIEW_FRAME_SIZE.y) - dst_pos.y
        if frame_size.x > 0 and frame_size.y > 0:
            frame_image.blit_rect(source_image, Rect2i(src_pos, frame_size), dst_pos)
        frames.append(ImageTexture.create_from_image(frame_image))
    return frames

func _tick_pause_character_preview(delta: float) -> void:
    if pause_overlay == null or pause_panel == null or pause_character_preview == null:
        return
    if not pause_overlay.visible or not pause_panel.visible:
        return
    if _pause_character_preview_frames.is_empty():
        return
    var frame_duration: float = 1.0 / max(1.0, PAUSE_CHARACTER_PREVIEW_FPS)
    _pause_character_preview_time += delta
    var did_advance: bool = false
    while _pause_character_preview_time >= frame_duration:
        _pause_character_preview_time -= frame_duration
        _pause_character_preview_frame_index = (_pause_character_preview_frame_index + 1) % _pause_character_preview_frames.size()
        did_advance = true
    if did_advance:
        _apply_pause_character_preview_frame()

func _apply_pause_character_preview_frame() -> void:
    if pause_character_preview == null:
        return
    if _pause_character_preview_frames.is_empty():
        pause_character_preview.texture = null
        return
    var frame_index: int = clampi(_pause_character_preview_frame_index, 0, _pause_character_preview_frames.size() - 1)
    pause_character_preview.texture = _pause_character_preview_frames[frame_index]

func _refresh_pause_weapon_summary() -> void:
    if pause_weapon_list == null:
        return
    for child: Node in pause_weapon_list.get_children():
        child.queue_free()

    var has_weapon: bool = false
    var equipped_slots: Array = _normalize_equipped_weapon_slots(_shop_runtime_state.get("equipped_weapons", []))
    for slot_index: int in range(equipped_slots.size()):
        var slot_value: Variant = equipped_slots[slot_index]
        if not _is_valid_weapon_slot(slot_value):
            continue
        var weapon: Dictionary = slot_value
        pause_weapon_list.add_child(_build_pause_weapon_row(weapon, slot_index))
        has_weapon = true

    if has_weapon:
        return
    var empty_label: Label = Label.new()
    empty_label.text = _tx("ui.game_scene.no_weapon", "No Weapon")
    empty_label.add_theme_color_override("font_color", Color(0.58, 0.72, 0.75, 0.9))
    empty_label.add_theme_font_size_override("font_size", 18)
    pause_weapon_list.add_child(empty_label)

func _build_pause_weapon_row(weapon: Dictionary, slot_index: int) -> HBoxContainer:
    var row: HBoxContainer = HBoxContainer.new()
    row.custom_minimum_size = Vector2(0.0, 34.0)
    row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_theme_constant_override("separation", 8)

    var icon_rect: TextureRect = TextureRect.new()
    icon_rect.custom_minimum_size = Vector2(32.0, 32.0)
    icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    var weapon_id: String = str(weapon.get("weapon_id", ""))
    icon_rect.texture = _get_weapon_orbit_texture(weapon_id)
    row.add_child(icon_rect)

    var label: Label = Label.new()
    label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    label.add_theme_color_override("font_color", Color(0.88, 0.98, 1.0, 0.96))
    label.add_theme_font_size_override("font_size", 18)
    label.text = "%d. %s  Lv.%d" % [
        slot_index + 1,
        _resolve_weapon_display_name(weapon),
        max(1, int(weapon.get("level", 1))),
    ]
    label.clip_text = true
    row.add_child(label)
    return row

func _refresh_pause_item_summary() -> void:
    if pause_item_list == null:
        return
    for child: Node in pause_item_list.get_children():
        child.queue_free()

    var owned_items_value: Variant = _shop_runtime_state.get("owned_items", [])
    var has_item: bool = false
    if owned_items_value is Array:
        for item_value: Variant in owned_items_value:
            if not (item_value is Dictionary):
                continue
            var item: Dictionary = item_value
            if str(item.get("item_id", "")).is_empty():
                continue
            pause_item_list.add_child(_build_pause_item_row(item))
            has_item = true

    if has_item:
        return
    var empty_label: Label = Label.new()
    empty_label.text = _tx("ui.game_scene.no_items", "No Items")
    empty_label.add_theme_color_override("font_color", Color(0.48, 0.62, 0.64, 0.86))
    empty_label.add_theme_font_size_override("font_size", 18)
    pause_item_list.add_child(empty_label)

func _build_pause_item_row(item: Dictionary) -> PanelContainer:
    var rarity: String = str(item.get("rarity", "common")).to_lower()
    var rarity_color: Color = _pause_item_rarity_color(rarity)

    var panel: PanelContainer = PanelContainer.new()
    panel.custom_minimum_size = Vector2(0.0, 36.0)
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    panel.add_theme_stylebox_override("panel", _build_neon_panel_style(
        Color(0.01, 0.035, 0.052, 0.74),
        rarity_color,
        1,
        4
    ))

    var margin: MarginContainer = MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 6)
    margin.add_theme_constant_override("margin_top", 2)
    margin.add_theme_constant_override("margin_right", 6)
    margin.add_theme_constant_override("margin_bottom", 2)
    panel.add_child(margin)

    var row: HBoxContainer = HBoxContainer.new()
    row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_theme_constant_override("separation", 8)
    margin.add_child(row)

    var item_id: String = str(item.get("item_id", ""))
    var icon_rect: TextureRect = TextureRect.new()
    icon_rect.custom_minimum_size = Vector2(30.0, 30.0)
    icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    icon_rect.texture = _load_pause_item_icon(item, item_id)
    row.add_child(icon_rect)

    var name_label: Label = Label.new()
    name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    name_label.add_theme_color_override("font_color", Color(0.88, 0.98, 1.0, 0.96))
    name_label.add_theme_font_size_override("font_size", 16)
    name_label.text = _resolve_item_display_name_for_pause(item, item_id)
    name_label.clip_text = true
    row.add_child(name_label)

    var count: int = max(1, int(item.get("count", 1)))
    var count_label: Label = Label.new()
    count_label.custom_minimum_size = Vector2(42.0, 0.0)
    count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    count_label.add_theme_color_override("font_color", rarity_color)
    count_label.add_theme_font_size_override("font_size", 15)
    count_label.text = "x%d" % count if count > 1 else ""
    row.add_child(count_label)
    return panel

func _load_pause_item_icon(item: Dictionary, item_id: String) -> Texture2D:
    var icon_path: String = str(item.get("icon_path", ""))
    if icon_path.is_empty() and not item_id.is_empty():
        icon_path = "res://sprite/items/%s.png" % item_id
    if icon_path.is_empty() or not ResourceLoader.exists(icon_path):
        return null
    return ResourceLoader.load(icon_path) as Texture2D

func _resolve_item_display_name_for_pause(item: Dictionary, item_id: String) -> String:
    if item_id.is_empty():
        return str(item.get("name", "Item"))
    return LocaleService.t_data("item", item_id, "name", str(item.get("name", item_id)))

func _pause_item_rarity_color(rarity: String) -> Color:
    match rarity:
        "rare":
            return Color(0.0, 0.92, 1.0, 0.92)
        "epic":
            return Color(0.72, 0.38, 1.0, 0.94)
        "legendary":
            return Color(1.0, 0.68, 0.0, 0.96)
        _:
            return Color(0.56, 0.66, 0.72, 0.86)

func _refresh_pause_stat_summary() -> void:
    if pause_stats_grid == null:
        return
    for child: Node in pause_stats_grid.get_children():
        child.queue_free()
    if _player == null or not is_instance_valid(_player):
        return

    var stat_defs: Array[Dictionary] = [
        {"label": _stat_label("hp"), "value": "%d/%d" % [_player.current_hp, _player.max_hp]},
        {"label": _stat_label("stamina"), "value": "%d/%d" % [int(round(_player.current_stamina)), int(round(_player.stamina_max))]},
        {"label": _stat_label("level"), "value": str(_current_level)},
        {"label": _stat_label("xp"), "value": "%d/%d" % [_current_xp, _xp_to_next_level]},
        {"label": _stat_label("gold"), "value": str(_current_gold_runtime)},
        {"label": _stat_label("move"), "value": _format_number(_player.move_speed)},
        {"label": _stat_label("armor"), "value": _format_number(_player.armor)},
        {"label": _stat_label("dodge"), "value": _format_percent_plain(_player.dodge_chance)},
        {"label": _stat_label("crit"), "value": _format_percent_plain(_player.crit_chance)},
        {"label": _stat_label("attack_speed"), "value": _format_percent_plain(_player.get_attack_speed_multiplier() - 1.0)},
        {"label": _stat_label("lifesteal"), "value": _format_percent_plain(_player.lifesteal)},
        {"label": _stat_label("luck"), "value": _format_number(_player.luck)},
        {"label": _stat_label("harvest"), "value": _format_number(_player.get_harvest())},
        {"label": _stat_label("attack"), "value": "+%d / +%s" % [_player.get_attack_damage_bonus(), _format_percent_plain(_player.get_global_attack_percent() / 100.0)]},
    ]
    for stat: Dictionary in stat_defs:
        _add_pause_stat_row(str(stat.get("label", "")), str(stat.get("value", "")))

func _add_pause_stat_row(label_text: String, value_text: String) -> void:
    var name_label: Label = Label.new()
    name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    name_label.add_theme_color_override("font_color", Color(0.58, 0.78, 0.82, 0.92))
    name_label.add_theme_font_size_override("font_size", 17)
    name_label.text = label_text
    pause_stats_grid.add_child(name_label)

    var value_label: Label = Label.new()
    value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    value_label.add_theme_color_override("font_color", Color(0.9, 1.0, 0.94, 0.98))
    value_label.add_theme_font_size_override("font_size", 17)
    value_label.text = value_text
    pause_stats_grid.add_child(value_label)

func _resolve_weapon_display_name(weapon: Dictionary) -> String:
    var weapon_id: String = str(weapon.get("weapon_id", ""))
    if weapon_id.is_empty():
        return _tx("ui.game_scene.no_weapon", "No Weapon")
    return LocaleService.t_data("weapon", weapon_id, "name", str(weapon.get("name", weapon_id)))

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
    _create_elite_chest_panel()
    _create_death_settlement_panel()
    _create_endless_choice_panel()

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
    panel.custom_minimum_size = Vector2(980.0, 390.0)
    panel.anchors_preset = Control.PRESET_CENTER
    panel.anchor_left = 0.5
    panel.anchor_top = 0.5
    panel.anchor_right = 0.5
    panel.anchor_bottom = 0.5
    panel.offset_left = -490.0
    panel.offset_top = -195.0
    panel.offset_right = 490.0
    panel.offset_bottom = 195.0
    panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
    panel.grow_vertical = Control.GROW_DIRECTION_BOTH
    panel.add_theme_stylebox_override("panel", _build_neon_panel_style(
        Color(0.012, 0.045, 0.07, 0.94),
        Color(0.0, 0.82, 0.9, 0.85),
        2,
        20
    ))

    var margin: MarginContainer = MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 20)
    margin.add_theme_constant_override("margin_top", 16)
    margin.add_theme_constant_override("margin_right", 20)
    margin.add_theme_constant_override("margin_bottom", 18)
    panel.add_child(margin)

    var vbox: VBoxContainer = VBoxContainer.new()
    vbox.add_theme_constant_override("separation", 14)
    margin.add_child(vbox)

    _level_reward_title = Label.new()
    _level_reward_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _level_reward_title.add_theme_font_size_override("font_size", 30)
    _level_reward_title.add_theme_color_override("font_color", Color(0.86, 0.98, 1.0, 1.0))
    vbox.add_child(_level_reward_title)

    var body: HBoxContainer = HBoxContainer.new()
    body.add_theme_constant_override("separation", 16)
    body.size_flags_vertical = Control.SIZE_EXPAND_FILL
    vbox.add_child(body)

    var cards_row: HBoxContainer = HBoxContainer.new()
    cards_row.add_theme_constant_override("separation", 12)
    cards_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    cards_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
    body.add_child(cards_row)

    _level_reward_buttons.clear()
    for i: int in range(LEVEL_REWARD_CHOICES_COUNT):
        var button: Button = _build_reward_button("Loading...", "none")
        _level_reward_buttons.append(button)
        cards_row.add_child(button)

    var reward_actions: VBoxContainer = VBoxContainer.new()
    reward_actions.custom_minimum_size = Vector2(150.0, 0.0)
    reward_actions.alignment = BoxContainer.ALIGNMENT_CENTER
    reward_actions.add_theme_constant_override("separation", 8)
    body.add_child(reward_actions)

    _level_reward_refresh_button = Button.new()
    _level_reward_refresh_button.custom_minimum_size = Vector2(140.0, 48.0)
    _level_reward_refresh_button.add_theme_font_size_override("font_size", 20)
    if NEON_OPTION_BUTTON_SCRIPT != null:
        _level_reward_refresh_button.set_script(NEON_OPTION_BUTTON_SCRIPT)
    _level_reward_refresh_button.pressed.connect(_on_level_reward_refresh_pressed)
    reward_actions.add_child(_level_reward_refresh_button)

    _level_reward_hint_label = Label.new()
    _level_reward_hint_label.custom_minimum_size = Vector2(140.0, 52.0)
    _level_reward_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _level_reward_hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _level_reward_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _level_reward_hint_label.add_theme_font_size_override("font_size", 15)
    _level_reward_hint_label.add_theme_color_override("font_color", Color(0.58, 0.9, 0.94, 0.92))
    reward_actions.add_child(_level_reward_hint_label)

    var stat_panel: PanelContainer = PanelContainer.new()
    stat_panel.custom_minimum_size = Vector2(280.0, 0.0)
    stat_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    stat_panel.add_theme_stylebox_override("panel", _build_neon_panel_style(
        Color(0.008, 0.035, 0.055, 0.9),
        Color(0.12, 0.62, 0.72, 0.78),
        1,
        8
    ))
    body.add_child(stat_panel)

    var stat_margin: MarginContainer = MarginContainer.new()
    stat_margin.add_theme_constant_override("margin_left", 12)
    stat_margin.add_theme_constant_override("margin_top", 10)
    stat_margin.add_theme_constant_override("margin_right", 12)
    stat_margin.add_theme_constant_override("margin_bottom", 10)
    stat_panel.add_child(stat_margin)

    var stat_box: VBoxContainer = VBoxContainer.new()
    stat_box.add_theme_constant_override("separation", 6)
    stat_margin.add_child(stat_box)

    var stat_title: Label = Label.new()
    stat_title.text = _tx("ui.game_scene.player_stats_title", "PLAYER STATS")
    stat_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    stat_title.add_theme_font_size_override("font_size", 20)
    stat_title.add_theme_color_override("font_color", Color(0.58, 1.0, 0.96, 1.0))
    stat_box.add_child(stat_title)

    _level_reward_stat_labels.clear()
    var stat_grid: GridContainer = GridContainer.new()
    stat_grid.columns = 2
    stat_grid.add_theme_constant_override("h_separation", 14)
    stat_grid.add_theme_constant_override("v_separation", 4)
    stat_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
    stat_box.add_child(stat_grid)
    var stat_defs: Array[Dictionary] = [
        {"key": "hp", "label": _stat_label("hp")},
        {"key": "damage", "label": _stat_label("damage")},
        {"key": "melee", "label": _stat_label("melee")},
        {"key": "ranged", "label": _stat_label("ranged")},
        {"key": "attack_speed", "label": _stat_label("attack_speed")},
        {"key": "crit", "label": _stat_label("crit")},
        {"key": "armor", "label": _stat_label("armor")},
        {"key": "dodge", "label": _stat_label("dodge")},
        {"key": "move", "label": _stat_label("move")},
        {"key": "range", "label": _stat_label("range")},
        {"key": "lifesteal", "label": _stat_label("lifesteal")},
        {"key": "luck", "label": _stat_label("luck")},
        {"key": "harvest", "label": _stat_label("harvest")},
        {"key": "xp", "label": _stat_label("xp")},
        {"key": "gold", "label": _stat_label("gold")},
    ]
    for stat_def: Dictionary in stat_defs:
        _create_level_reward_stat_row(stat_grid, str(stat_def.get("key", "")), str(stat_def.get("label", "")))

    _level_reward_panel = panel
    _add_pause_sub_panel(_level_reward_panel)

func _create_elite_chest_panel() -> void:
    var panel: PanelContainer = PanelContainer.new()
    panel.visible = false
    panel.custom_minimum_size = Vector2(560.0, 390.0)
    panel.anchors_preset = Control.PRESET_CENTER
    panel.anchor_left = 0.5
    panel.anchor_top = 0.5
    panel.anchor_right = 0.5
    panel.anchor_bottom = 0.5
    panel.offset_left = -280.0
    panel.offset_top = -195.0
    panel.offset_right = 280.0
    panel.offset_bottom = 195.0
    panel.add_theme_stylebox_override("panel", _build_neon_panel_style(
        Color(0.015, 0.05, 0.085, 0.96),
        Color(0.0, 0.85, 0.9, 0.92),
        2,
        22
    ))

    var margin: MarginContainer = MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 18)
    margin.add_theme_constant_override("margin_top", 16)
    margin.add_theme_constant_override("margin_right", 18)
    margin.add_theme_constant_override("margin_bottom", 16)
    panel.add_child(margin)

    var vbox: VBoxContainer = VBoxContainer.new()
    vbox.add_theme_constant_override("separation", 12)
    margin.add_child(vbox)

    _elite_chest_title = Label.new()
    _elite_chest_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _elite_chest_title.add_theme_font_size_override("font_size", 30)
    _elite_chest_title.add_theme_color_override("font_color", Color(0.55, 1.0, 0.96, 1.0))
    vbox.add_child(_elite_chest_title)

    var body: HBoxContainer = HBoxContainer.new()
    body.add_theme_constant_override("separation", 14)
    body.size_flags_vertical = Control.SIZE_EXPAND_FILL
    vbox.add_child(body)

    var icon_frame: PanelContainer = PanelContainer.new()
    icon_frame.custom_minimum_size = Vector2(116.0, 116.0)
    icon_frame.add_theme_stylebox_override("panel", _build_neon_panel_style(
        Color(0.02, 0.07, 0.11, 0.92),
        Color(1.0, 0.66, 0.0, 0.86),
        2,
        10
    ))
    body.add_child(icon_frame)

    _elite_chest_icon = TextureRect.new()
    _elite_chest_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    _elite_chest_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    _elite_chest_icon.custom_minimum_size = Vector2(96.0, 96.0)
    icon_frame.add_child(_elite_chest_icon)

    var text_box: VBoxContainer = VBoxContainer.new()
    text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    text_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
    text_box.add_theme_constant_override("separation", 6)
    body.add_child(text_box)

    _elite_chest_name = Label.new()
    _elite_chest_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _elite_chest_name.add_theme_font_size_override("font_size", 24)
    text_box.add_child(_elite_chest_name)

    _elite_chest_rarity = Label.new()
    _elite_chest_rarity.add_theme_font_size_override("font_size", 18)
    text_box.add_child(_elite_chest_rarity)

    _elite_chest_desc = RichTextLabel.new()
    _elite_chest_desc.bbcode_enabled = true
    _elite_chest_desc.fit_content = false
    _elite_chest_desc.scroll_active = false
    _elite_chest_desc.custom_minimum_size = Vector2(0.0, 120.0)
    _elite_chest_desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
    text_box.add_child(_elite_chest_desc)

    var button_row: HBoxContainer = HBoxContainer.new()
    button_row.alignment = BoxContainer.ALIGNMENT_CENTER
    button_row.add_theme_constant_override("separation", 12)
    vbox.add_child(button_row)

    _elite_chest_claim_button = Button.new()
    _style_neon_action_button(_elite_chest_claim_button, _tx("ui.elite_chest.claim", "Claim"))
    _elite_chest_claim_button.pressed.connect(_on_elite_chest_claim_pressed)
    button_row.add_child(_elite_chest_claim_button)

    _elite_chest_recycle_button = Button.new()
    _style_neon_action_button(_elite_chest_recycle_button, _tx("ui.elite_chest.recycle", "Recycle"))
    _elite_chest_recycle_button.pressed.connect(_on_elite_chest_recycle_pressed)
    button_row.add_child(_elite_chest_recycle_button)

    _elite_chest_panel = panel
    _add_pause_sub_panel(_elite_chest_panel)

func _create_endless_choice_panel() -> void:
    var panel: PanelContainer = PanelContainer.new()
    panel.visible = false
    panel.custom_minimum_size = Vector2(700.0, 320.0)
    panel.anchors_preset = Control.PRESET_CENTER
    panel.anchor_left = 0.5
    panel.anchor_top = 0.5
    panel.anchor_right = 0.5
    panel.anchor_bottom = 0.5
    panel.offset_left = -350.0
    panel.offset_top = -160.0
    panel.offset_right = 350.0
    panel.offset_bottom = 160.0
    panel.add_theme_stylebox_override("panel", _build_neon_panel_style(
        Color(0.012, 0.045, 0.07, 0.96),
        Color(0.0, 0.9, 0.72, 0.92),
        2,
        22
    ))

    var margin: MarginContainer = MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 22)
    margin.add_theme_constant_override("margin_top", 18)
    margin.add_theme_constant_override("margin_right", 22)
    margin.add_theme_constant_override("margin_bottom", 18)
    panel.add_child(margin)

    var vbox: VBoxContainer = VBoxContainer.new()
    vbox.alignment = BoxContainer.ALIGNMENT_CENTER
    vbox.add_theme_constant_override("separation", 16)
    margin.add_child(vbox)

    var title: Label = Label.new()
    title.text = _tx("ui.endless_choice.title", "无尽模式")
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 34)
    title.add_theme_color_override("font_color", Color(0.62, 1.0, 0.86, 1.0))
    vbox.add_child(title)

    var desc: Label = Label.new()
    desc.text = _tx("ui.endless_choice.desc", "第20关已完成。进入无尽模式后计时会继续累加，商店每80秒开启一次，敌人会持续成长。")
    desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    desc.add_theme_font_size_override("font_size", 20)
    desc.add_theme_color_override("font_color", Color(0.82, 0.96, 1.0, 0.94))
    vbox.add_child(desc)

    var button_row: HBoxContainer = HBoxContainer.new()
    button_row.alignment = BoxContainer.ALIGNMENT_CENTER
    button_row.add_theme_constant_override("separation", 16)
    vbox.add_child(button_row)

    _endless_finish_button = Button.new()
    _style_neon_action_button(_endless_finish_button, _tx("ui.endless_choice.finish", "完成"))
    _endless_finish_button.pressed.connect(_on_endless_finish_pressed)
    button_row.add_child(_endless_finish_button)

    _endless_continue_button = Button.new()
    _style_neon_action_button(_endless_continue_button, _tx("ui.endless_choice.enter", "进入无尽"))
    _endless_continue_button.pressed.connect(_on_endless_continue_pressed)
    button_row.add_child(_endless_continue_button)

    _endless_choice_panel = panel
    _add_pause_sub_panel(_endless_choice_panel)

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

func _create_level_reward_stat_row(parent: GridContainer, key: String, label_text: String) -> void:
    var label: Label = Label.new()
    label.text = label_text
    label.add_theme_font_size_override("font_size", 15)
    label.add_theme_color_override("font_color", Color(0.48, 0.88, 0.92, 0.95))
    label.custom_minimum_size = Vector2(82.0, 0.0)
    parent.add_child(label)

    var value: Label = Label.new()
    value.text = "--"
    value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    value.add_theme_font_size_override("font_size", 15)
    value.add_theme_color_override("font_color", Color(0.92, 0.98, 1.0, 1.0))
    value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    parent.add_child(value)
    _level_reward_stat_labels[key] = value

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
    button.custom_minimum_size = Vector2(210.0, 250.0)
    button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    button.size_flags_vertical = Control.SIZE_EXPAND_FILL
    button.text = ""
    button.alignment = HORIZONTAL_ALIGNMENT_CENTER
    button.add_theme_font_size_override("font_size", 21)
    button.set_meta("reward_id", reward_id)
    button.tooltip_text = ""

    var margin: MarginContainer = MarginContainer.new()
    margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
    margin.set_anchors_preset(Control.PRESET_FULL_RECT)
    margin.offset_left = 12.0
    margin.offset_top = 12.0
    margin.offset_right = -12.0
    margin.offset_bottom = -12.0
    button.add_child(margin)

    var vbox: VBoxContainer = VBoxContainer.new()
    vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
    vbox.add_theme_constant_override("separation", 8)
    margin.add_child(vbox)

    var title: Label = Label.new()
    title.name = "RewardTitle"
    title.mouse_filter = Control.MOUSE_FILTER_IGNORE
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    title.add_theme_font_size_override("font_size", 22)
    title.add_theme_color_override("font_color", Color(0.95, 1.0, 1.0, 1.0))
    vbox.add_child(title)

    var rarity: Label = Label.new()
    rarity.name = "RewardRarity"
    rarity.mouse_filter = Control.MOUSE_FILTER_IGNORE
    rarity.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    rarity.add_theme_font_size_override("font_size", 17)
    vbox.add_child(rarity)

    var divider: ColorRect = ColorRect.new()
    divider.name = "RewardDivider"
    divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
    divider.custom_minimum_size = Vector2(0.0, 1.0)
    divider.color = Color(0.2, 0.9, 0.95, 0.32)
    vbox.add_child(divider)

    var effect: Label = Label.new()
    effect.name = "RewardEffect"
    effect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    effect.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    effect.vertical_alignment = VERTICAL_ALIGNMENT_TOP
    effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    effect.add_theme_font_size_override("font_size", 21)
    effect.add_theme_color_override("font_color", Color(0.88, 0.96, 1.0, 1.0))
    effect.size_flags_vertical = Control.SIZE_EXPAND_FILL
    vbox.add_child(effect)

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
    _refresh_pause_summary()
    GameManager.pause_game()
    _play_pause_overlay_open_transition()

func _resume_game_from_pause() -> void :
    if _reward_opened:
        _show_active_reward_panel()
        return
    _pause_opened = false
    _hide_pause_sub_panels()
    _play_pause_overlay_close_transition(func() -> void:
        _set_crt_effects_enabled(true)
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
        _set_crt_effects_enabled(true)

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
        _show_active_reward_panel()
        return
    _resume_game_from_pause()

func _on_main_menu_button_pressed() -> void :
    _pause_opened = false
    _play_pause_overlay_close_transition(func() -> void:
        _set_crt_effects_enabled(true)
        GameManager.go_to_menu()
    )

func _on_save_button_pressed() -> void :
    _show_slot_panel(SaveSlotPanel.MODE_SAVE)

func _on_settings_button_pressed() -> void :
    _show_settings_panel()

func _show_slot_panel(mode: String) -> void :
    if _reward_opened:
        _show_active_reward_panel()
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
        _show_active_reward_panel()
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
        if _elite_chest_panel != null:
            _elite_chest_panel.visible = _pending_elite_chests > 0
        if _level_reward_panel != null:
            _level_reward_panel.visible = _pending_elite_chests <= 0
        return
    _set_crt_effects_enabled(true)
    if _slot_panel != null:
        _slot_panel.visible = false
    if _settings_panel != null:
        _settings_panel.visible = false
    if _level_reward_panel != null:
        _level_reward_panel.visible = false
    if _elite_chest_panel != null:
        _elite_chest_panel.visible = false
    if _death_settlement_panel != null:
        _death_settlement_panel.visible = false
    if pause_panel != null:
        pause_panel.visible = true
    _refresh_pause_summary()

func _is_pause_sub_panel_open() -> bool:
    var slot_open: bool = _slot_panel != null and _slot_panel.visible
    var settings_open: bool = _settings_panel != null and _settings_panel.visible
    var reward_open: bool = _level_reward_panel != null and _level_reward_panel.visible
    var chest_open: bool = _elite_chest_panel != null and _elite_chest_panel.visible
    var death_summary_open: bool = _death_settlement_panel != null and _death_settlement_panel.visible
    return slot_open or settings_open or reward_open or chest_open or death_summary_open

func _on_death_retry_pressed() -> void:
    get_tree().paused = false
    _pause_opened = false
    _set_pause_overlay_visible(false)
    var retry_payload: Dictionary = _build_stage_retry_payload()
    var retry_stage_id: String = str(retry_payload.get("stage_id", GameManager.current_stage_id))
    if retry_stage_id.is_empty():
        retry_stage_id = GameManager.current_stage_id
    GameManager.start_game_with_runtime(retry_stage_id, retry_payload)

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
        if _stage_is_boss_stage and hud.has_method("hide_boss_bar"):
            hud.call("hide_boss_bar")

    if enemy.enemy_type == Enemy.EnemyType.SPLITTER:
        _spawn_splitter_fragments(enemy.global_position)
    
    _spawn_enemy_resource_drops(enemy)
    
    # Roll for consumable drop (from monsters)
    var luck: float = 0.0
    if _player != null and is_instance_valid(_player):
        luck = _player.luck
    
    var final_drop_chance: float = CONSUMABLE_DROP_CHANCE_BASE * (1.0 + luck / 100.0)
    if enemy.is_elite:
        final_drop_chance = 0.20 * (1.0 + luck / 100.0) 
        if not _is_endless_mode:
            _pending_elite_chests += 1
            _spawn_elite_chest_reward_visual(enemy.global_position)
        
    if randf() < final_drop_chance:
        _spawn_consumable(enemy.global_position)

func _spawn_elite_chest_reward_visual(pos: Vector2) -> void:
    if ELITE_CHEST_DROP_SCRIPT == null:
        return
    var chest: Node2D = ELITE_CHEST_DROP_SCRIPT.new() as Node2D
    if chest == null:
        return
    chest.global_position = pos
    add_child(chest)
    var target_position: Vector2 = pos + Vector2(0.0, -72.0)
    if _player != null and is_instance_valid(_player):
        target_position = _player.global_position + Vector2(0.0, -76.0)
    var impulse: Vector2 = _random_drop_impulse(90.0, 165.0)
    if chest.has_method("setup"):
        chest.call("setup", impulse, target_position)
    _spawn_pickup_hint(pos, "CHEST", Color(1.0, 0.68, 0.0, 0.96), 18, Vector2(-28.0, -34.0), 0.85, 54.0)

func _resolve_enemy_gold_drop(enemy: Enemy) -> int:
    var combat_params: Dictionary = BalanceService.get_global_combat_params()
    var gold_drop: Dictionary = combat_params.get("gold_drop", {})
    if enemy.is_elite:
        return int(gold_drop.get("elite", 8))
    if _is_ranged_resource_enemy(enemy):
        return int(gold_drop.get("ranged", 2))
    return int(gold_drop.get("melee", 1))

func _is_ranged_resource_enemy(enemy: Enemy) -> bool:
    return (
        enemy.enemy_type == Enemy.EnemyType.RANGED
        or enemy.enemy_type == Enemy.EnemyType.BARRAGE
        or enemy.enemy_type == Enemy.EnemyType.SNIPER
        or enemy.enemy_type == Enemy.EnemyType.MINE_SEEDER
    )

func _spawn_enemy_resource_drops(enemy: Enemy) -> void:
    var xp_total: int = _randomized_scaled_resource_amount(enemy.xp_drop_amount, _stage_xp_drop_multiplier)
    var gold_total: int = _randomized_scaled_resource_amount(_resolve_enemy_gold_drop(enemy), _stage_gold_drop_multiplier)
    if GameManager != null and GameManager.has_method("is_stage_drop_double_active"):
        if bool(GameManager.call("is_stage_drop_double_active")):
            xp_total *= 2
            gold_total *= 2
    var xp_count: int = 1
    var gold_count: int = 1
    if enemy.is_elite:
        xp_count = randi_range(4, 6)
        gold_count = randi_range(2, 4)
    elif _is_ranged_resource_enemy(enemy):
        xp_count = randi_range(2, 3)
        gold_count = randi_range(1, 2)
    else:
        xp_count = randi_range(1, 2)
        gold_count = 1
    _spawn_split_resource_orbs(enemy.global_position, xp_total, 0, xp_count)
    _spawn_split_resource_orbs(enemy.global_position, 0, gold_total, gold_count)

func _spawn_splitter_fragments(origin: Vector2) -> void:
    if _player == null or not is_instance_valid(_player):
        return
    var fragment_count: int = 2
    for i: int in range(fragment_count):
        if _count_active_enemies() >= _get_active_max_enemy_count():
            return
        var offset: Vector2 = Vector2.RIGHT.rotated(float(i) * TAU / float(fragment_count) + randf_range(-0.35, 0.35)) * randf_range(18.0, 30.0)
        var fragment: Enemy = _spawn_enemy(Enemy.EnemyType.FAST_MELEE, _clamp_position_to_arena(origin + offset, 8.0))
        if fragment == null:
            continue
        fragment.max_hp = max(1, int(round(float(fragment.max_hp) * 0.45)))
        fragment.current_hp = fragment.max_hp
        fragment.xp_drop_amount = 0
        fragment.queue_redraw()

func _randomized_scaled_resource_amount(base_amount: int, multiplier: float) -> int:
    if base_amount <= 0:
        return 0
    var scaled_value: float = max(0.0, float(base_amount) * max(0.0, multiplier))
    var guaranteed: int = int(floor(scaled_value))
    var fractional: float = scaled_value - float(guaranteed)
    if randf() < fractional:
        guaranteed += 1
    return max(0, guaranteed)

func _spawn_split_resource_orbs(spawn_position: Vector2, xp_total: int, gold_total: int, desired_count: int) -> void:
    var total: int = max(0, xp_total + gold_total)
    if total <= 0:
        return
    var count: int = clampi(desired_count, 1, total)
    var remaining: int = total
    for i: int in range(count):
        var slots_left: int = count - i
        var amount: int = 1
        if slots_left <= 1:
            amount = remaining
        else:
            var max_for_slot: int = max(1, remaining - (slots_left - 1))
            amount = randi_range(1, max_for_slot)
        remaining -= amount
        if xp_total > 0:
            _spawn_experience_orb(spawn_position, amount, 0)
        else:
            _spawn_experience_orb(spawn_position, 0, amount)

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

func _resolve_wave_harvest_xp() -> int:
    if _player == null or not is_instance_valid(_player):
        return 0
    var harvest_value: float = max(0.0, _player.get_harvest())
    if harvest_value <= 0.0:
        return 0
    # In Brotato, Harvest gives roughly 1:1 XP as well.
    return int(harvest_value)

func _apply_harvest_growth() -> void:
    if _player == null or not is_instance_valid(_player):
        return
    var current_harvest: float = _player.get_harvest()
    if current_harvest <= 0.0:
        return
    # Brotato: +5% Harvest at the end of each wave
    var growth: float = ceil(current_harvest * 0.05)
    _player.add_harvest(growth)

func _update_tree_spawning(delta: float) -> void:
    if _is_game_over or _stage_clear_triggered:
        return
        
    _tree_spawn_timer -= delta
    if _tree_spawn_timer <= 0.0:
        _tree_spawn_timer = TREE_SPAWN_INTERVAL
        if _count_active_trees() < MAX_TREE_COUNT:
            _spawn_tree()

func _count_active_trees() -> int:
    var count = 0
    for enemy in _enemies:
        if enemy is DestructibleTree and is_instance_valid(enemy):
            count += 1
    return count

func _spawn_tree() -> void:
    var tree = DestructibleTree.new()
    # Random position within arena, ideally slightly away from player
    tree.global_position = _random_spawn_position()
    tree.tree_destroyed.connect(_on_tree_destroyed)
    add_child(tree)
    _enemies.append(tree)

func _on_tree_destroyed(pos: Vector2) -> void:
    # Trees always drop a consumable
    _spawn_consumable(pos)

func _spawn_consumable(pos: Vector2) -> void:
    var drop = ConsumableDrop.new()
    var impulse: Vector2 = _random_drop_impulse(76.0, 150.0)
    drop.global_position = pos + impulse.normalized() * randf_range(3.0, 12.0)
    if drop.has_method("set_spawn_impulse"):
        drop.call("set_spawn_impulse", impulse)
    add_child(drop)
    _consumables.append(drop)

func _update_consumables(delta: float) -> void:
    if _player == null or not is_instance_valid(_player):
        return
        
    var pickup_radius: float = max(0.0, _player.pickup_radius)
    for drop in _consumables:
        if drop == null or not is_instance_valid(drop):
            continue
        if drop.tick_collect(_player.global_position, pickup_radius, delta):
            var healed = _player.heal(drop.heal_amount)
            if healed > 0:
                _spawn_pickup_hint(drop.global_position, "+", Color(0.0, 1.0, 0.25, 0.9), 16, Vector2(-8.0, -18.0), 0.5, 24.0)
                _spawn_heal_hint(_player.global_position, healed)
            
            drop.queue_free()

func _spawn_heal_hint(pos: Vector2, amount: int) -> void:
    _spawn_pickup_hint(
        pos,
        "+" + str(amount),
        Color(0.0, 1.0, 0.25, 0.95),
        20,
        Vector2(-10.0, -30.0),
        0.8,
        50.0
    )

func _cleanup_dead_consumables() -> void:
    var alive: Array[ConsumableDrop] = []
    for drop in _consumables:
        if drop != null and is_instance_valid(drop):
            alive.append(drop)
    _consumables = alive

func _spawn_experience_orb(spawn_position: Vector2, xp_value: int, gold_value: int = 0) -> void :
    if xp_value <= 0 and gold_value <= 0:
        return
    var orb: ExperienceOrb = ExperienceOrb.new()
    var impulse: Vector2 = _random_drop_impulse(56.0, 128.0)
    orb.global_position = spawn_position + impulse.normalized() * randf_range(2.0, 10.0)
    orb.setup(xp_value, gold_value)
    if orb.has_method("set_spawn_impulse"):
        orb.call("set_spawn_impulse", impulse)
    add_child(orb)
    _experience_orbs.append(orb)

func _random_drop_impulse(min_speed: float, max_speed: float) -> Vector2:
    var angle: float = randf_range(0.0, TAU)
    var speed: float = randf_range(min_speed, max_speed)
    return Vector2.RIGHT.rotated(angle) * speed

func _animate_orbs_to_bag(orbs: Array[ExperienceOrb]) -> void:
    # Resolve the recycling bag screen position from the HUD.
    var bag_screen_pos = Vector2(70, 50)
    if hud != null and hud.recycling_bag_panel != null:
        var panel = hud.recycling_bag_panel
        bag_screen_pos = panel.global_position + (panel.size * 0.5)
    
    # 2. 鑰冭檻鎽勫儚澶村拰鐢诲竷缂╂斁锛屽皢灞忓箷鍧愭爣杞负涓栫晫鍧愭爣
    var canvas_transform = get_viewport().get_canvas_transform()
    var target_global_pos = canvas_transform.affine_inverse() * bag_screen_pos
    
    var total_count: int = orbs.size()
    # Keep callback completion state outside the closure.
    var state = {"finished": 0}
    
    var timeout_timer = get_tree().create_timer(1.8)
    
    for i in range(orbs.size()):
        var orb = orbs[i]
        if not is_instance_valid(orb):
            state["finished"] += 1
            continue
            
        # 3. 褰诲簳鏂紑鍘熸湁閫昏緫
        orb.set_process(false)
        orb.set_physics_process(false)
        
        # 4. 瑙嗚灞傜骇鎻愬崌
        if orb.get_parent() != self:
            orb.get_parent().remove_child(orb)
            add_child(orb)
        
        var tween = create_tween()
        tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
        
        # All orbs fly at the same time, slowed down to 1.0s for better visual impact
        tween.tween_property(orb, "global_position", target_global_pos, 1.0)
        tween.parallel().tween_property(orb, "scale", Vector2.ZERO, 1.0)
        
        # Safe reference in closure
        tween.tween_callback(func(): 
            state["finished"] += 1
            GameManager.recycling_bag_amount += 1
            if hud != null and hud.has_method("refresh_recycling_bag"):
                hud.call("refresh_recycling_bag")
            if is_instance_valid(orb):
                orb.queue_free()
        )
    
    # Wait for all orbs or timeout
    while state["finished"] < total_count and timeout_timer.time_left > 0:
        await get_tree().process_frame

func _spawn_double_pickup_hint(pos: Vector2) -> void:
    _spawn_pickup_hint(pos, "x2", Color(0.0, 1.0, 0.25, 0.95), 18, Vector2(-10.0, -20.0), 0.6, 40.0)
    
    # 绉婚櫎鏈夐棶棰樼殑纭紪鐮佽矾寰勫姞杞斤紝浼樺厛浣跨敤椤圭洰鍏ㄥ眬瀛椾綋

func _spawn_damage_popup(pos: Vector2, amount: int, is_crit: bool) -> void:
    if amount <= 0:
        return

    var label: Label = Label.new()
    label.text = "CRIT %d" % amount if is_crit else str(amount)
    label.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VerticalAlignment.VERTICAL_ALIGNMENT_CENTER
    label.add_theme_color_override("font_color", Color(1.0, 0.28, 0.12, 1.0) if is_crit else Color(1.0, 0.78, 0.18, 0.96))
    label.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.02, 0.96))
    label.add_theme_constant_override("outline_size", 6 if is_crit else 4)
    label.add_theme_font_size_override("font_size", 28 if is_crit else 20)
    label.z_index = 80

    add_child(label)
    label.global_position = pos + Vector2(randf_range(-8.0, 8.0), -24.0 if is_crit else -18.0)
    label.pivot_offset = Vector2(18.0, 12.0)
    if is_crit:
        label.scale = Vector2(0.78, 0.78)

    var duration: float = 0.64 if is_crit else 0.5
    var rise_distance: float = 58.0 if is_crit else 38.0
    var tween: Tween = create_tween()
    tween.set_parallel(true)
    tween.tween_property(label, "global_position:y", label.global_position.y - rise_distance, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tween.tween_property(label, "modulate:a", 0.0, duration).set_delay(duration * 0.42)
    if is_crit:
        tween.tween_property(label, "scale", Vector2(1.18, 1.18), duration * 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
        tween.tween_property(label, "rotation", randf_range(-0.12, 0.12), duration * 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
    tween.set_parallel(false)
    tween.tween_callback(label.queue_free)

func _on_player_damage_taken(amount: int) -> void:
    if _player == null or not is_instance_valid(_player):
        return
    _spawn_player_damage_hint(_player.global_position, amount)

func _on_player_attack_dodged() -> void:
    if _player == null or not is_instance_valid(_player):
        return
    _spawn_player_dodge_hint(_player.global_position)

func _spawn_player_damage_hint(pos: Vector2, amount: int) -> void:
    if amount <= 0:
        return
    _spawn_pickup_hint(
        pos,
        "-%d" % amount,
        Color(1.0, 0.18, 0.16, 0.98),
        24,
        Vector2(randf_range(-18.0, 8.0), -34.0),
        0.58,
        46.0
    )

func _spawn_player_dodge_hint(pos: Vector2) -> void:
    _spawn_pickup_hint(
        pos,
        "闪避",
        Color(0.36, 0.96, 1.0, 0.98),
        23,
        Vector2(randf_range(-18.0, 8.0), -36.0),
        0.56,
        42.0
    )

func _spawn_pickup_hint(
    pos: Vector2,
    text: String,
    font_color: Color,
    font_size: int,
    offset: Vector2,
    duration: float,
    rise_distance: float
) -> void:
    var label = Label.new()
    label.text = text
    label.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
    label.add_theme_color_override("font_color", font_color)
    label.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.08, 0.95))
    label.add_theme_constant_override("outline_size", 4)
    label.add_theme_font_size_override("font_size", font_size)

    add_child(label)
    label.global_position = pos + offset

    var tween = create_tween()
    tween.tween_property(label, "global_position:y", label.global_position.y - rise_distance, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tween.parallel().tween_property(label, "modulate:a", 0.0, duration).set_delay(duration * 0.35)
    tween.tween_callback(label.queue_free)

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
        AudioManager.play_level_up_sfx()
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
    if not _wave_end_reward_gate_active and not _is_endless_mode:
        return
    if _reward_opened or _is_game_over:
        return
    _show_level_reward_panel()

func _show_active_reward_panel() -> void:
    if _pending_elite_chests > 0:
        _show_elite_chest_panel()
        return
    if _pending_level_up_rewards > 0:
        _show_level_reward_panel()

func _show_level_reward_panel() -> void :
    if _level_reward_panel == null:
        return
    var was_reward_opened: bool = _reward_opened
    _reward_opened = true
    get_tree().paused = true
    _set_pause_overlay_visible(true)
    pause_panel.visible = false
    if _slot_panel != null:
        _slot_panel.visible = false
    if _settings_panel != null:
        _settings_panel.visible = false
    if not was_reward_opened or _level_reward_choices.is_empty():
        _level_reward_refresh_count = 0
        _refresh_level_reward_choices()
    else:
        _refresh_level_reward_cards()
        _refresh_level_reward_refresh_controls("")
    _level_reward_panel.visible = true
    if _level_reward_title != null:
        _level_reward_title.text = _tf("ui.game_scene.level_reward_title_fmt", [_current_level], "Level %d Reward Choice")

func _show_elite_chest_panel() -> void:
    if _elite_chest_panel == null or _shop_system_runtime == null:
        return
    if _pending_elite_chests <= 0:
        _open_shop_after_wave_reward()
        return
    _reward_opened = true
    get_tree().paused = true
    _set_pause_overlay_visible(true)
    pause_panel.visible = false
    if _slot_panel != null:
        _slot_panel.visible = false
    if _settings_panel != null:
        _settings_panel.visible = false
    if _level_reward_panel != null:
        _level_reward_panel.visible = false
    if _current_elite_chest_offer.is_empty():
        _current_elite_chest_offer = _shop_system_runtime.roll_elite_chest_item(_build_elite_chest_context())
    _refresh_elite_chest_panel()
    _elite_chest_panel.visible = true

func _build_elite_chest_context() -> Dictionary:
    var context: Dictionary = _build_wave_runtime_snapshot()
    var player_luck: float = 0.0
    if _player != null and is_instance_valid(_player):
        player_luck = _player.luck
    context["luck"] = player_luck
    context["wave"] = max(1, GameManager.current_wave)
    return context

func _refresh_elite_chest_panel() -> void:
    var offer: Dictionary = _current_elite_chest_offer
    var rarity: String = str(offer.get("rarity", "common")).to_lower()
    var rarity_color: Color = _elite_chest_rarity_color(rarity)
    if _elite_chest_panel != null:
        _elite_chest_panel.add_theme_stylebox_override("panel", _build_neon_panel_style(
            Color(0.015, 0.05, 0.085, 0.96),
            rarity_color,
            2,
            22
        ))
    if _elite_chest_title != null:
        _elite_chest_title.text = _tf("ui.elite_chest.title_fmt", [_pending_elite_chests], "Elite Chest %d")
    if _elite_chest_name != null:
        _elite_chest_name.text = _resolve_item_display_name(offer)
        _elite_chest_name.add_theme_color_override("font_color", Color(0.92, 0.98, 1.0, 1.0))
    if _elite_chest_rarity != null:
        _elite_chest_rarity.text = _elite_chest_rarity_label(rarity)
        _elite_chest_rarity.add_theme_color_override("font_color", rarity_color)
    if _elite_chest_desc != null:
        _elite_chest_desc.text = _resolve_item_display_desc(offer)
    if _elite_chest_icon != null:
        _elite_chest_icon.texture = _load_reward_icon_texture(str(offer.get("icon_path", "")))
    if _elite_chest_claim_button != null:
        _elite_chest_claim_button.text = _tx("ui.elite_chest.claim", "Claim")
    if _elite_chest_recycle_button != null:
        _elite_chest_recycle_button.text = _tf("ui.elite_chest.recycle_fmt", [max(1, int(offer.get("recycle_value", 1)))], "Recycle +%dG")

func _on_elite_chest_claim_pressed() -> void:
    if _current_elite_chest_offer.is_empty() or _shop_system_runtime == null:
        return
    var result: Dictionary = _shop_system_runtime.claim_item_reward(
        _current_elite_chest_offer,
        _build_wave_runtime_snapshot()
    )
    if bool(result.get("ok", false)):
        _apply_item_reward_runtime_state(result.get("state", {}))
        _finish_one_elite_chest_reward()

func _on_elite_chest_recycle_pressed() -> void:
    if _current_elite_chest_offer.is_empty() or _shop_system_runtime == null:
        return
    var result: Dictionary = _shop_system_runtime.recycle_item_reward(
        _current_elite_chest_offer,
        _build_wave_runtime_snapshot()
    )
    if bool(result.get("ok", false)):
        _apply_item_reward_runtime_state(result.get("state", {}))
        _finish_one_elite_chest_reward()

func _finish_one_elite_chest_reward() -> void:
    _pending_elite_chests = max(0, _pending_elite_chests - 1)
    _current_elite_chest_offer = {}
    if _pending_elite_chests > 0:
        _show_elite_chest_panel()
        return
    _close_elite_chest_panel()
    if _pending_level_up_rewards > 0:
        _try_open_next_level_reward()
        return
    _open_shop_after_wave_reward()

func _close_elite_chest_panel() -> void:
    _reward_opened = false
    _current_elite_chest_offer = {}
    if _elite_chest_panel != null:
        _elite_chest_panel.visible = false
    get_tree().paused = false
    _set_pause_overlay_visible(false)

func _apply_item_reward_runtime_state(raw_state: Variant) -> void:
    if not (raw_state is Dictionary):
        return
    var state: Dictionary = raw_state
    _current_gold_runtime = max(0, int(state.get("current_gold", _current_gold_runtime)))
    _shop_runtime_state = _normalize_shop_runtime_state(state.get("shop_runtime_state", _shop_runtime_state))
    _gold_multiplier = max(0.1, float(state.get("gold_gain_multiplier", _gold_multiplier)))
    _xp_multiplier = max(0.1, float(state.get("xp_gain_mult", _xp_multiplier)))
    if _player != null and is_instance_valid(_player):
        _player.max_hp = max(1, int(state.get("player_max_hp", _player.max_hp)))
        _player.current_hp = clampi(int(state.get("player_hp", _player.current_hp)), 0, _player.max_hp)
        _player.move_speed = float(state.get("player_move_speed", _player.move_speed))
        _player.bonus_target_range = float(state.get("bonus_target_range", _player.bonus_target_range))
        _player.pickup_radius = float(state.get("pickup_radius", _player.pickup_radius))
        var stats_value: Variant = state.get("player_stats", {})
        if stats_value is Dictionary:
            _player.import_runtime_stats((stats_value as Dictionary).duplicate(true))
    _refresh_weapon_tag_state_runtime(true)
    _refresh_player_hud()

func _resolve_item_display_name(offer: Dictionary) -> String:
    var item_id: String = str(offer.get("item_id", ""))
    if LocaleService != null and not item_id.is_empty():
        return LocaleService.t_data("item", item_id, "name", str(offer.get("name", "Item")))
    return str(offer.get("name", "Item"))

func _resolve_item_display_desc(offer: Dictionary) -> String:
    var item_id: String = str(offer.get("item_id", ""))
    if LocaleService != null and not item_id.is_empty():
        return LocaleService.t_data("item", item_id, "desc", str(offer.get("description", "")))
    return str(offer.get("description", ""))

func _load_reward_icon_texture(path: String) -> Texture2D:
    if path.is_empty():
        return null
    var resource: Resource = ResourceLoader.load(path)
    if resource is Texture2D:
        return resource as Texture2D
    return null

func _elite_chest_rarity_color(rarity: String) -> Color:
    match rarity:
        "rare":
            return Color(0.0, 1.0, 1.0, 0.92)
        "epic":
            return Color(0.73, 0.4, 1.0, 0.94)
        "legendary":
            return Color(1.0, 0.68, 0.0, 0.96)
        _:
            return Color(0.55, 0.62, 0.72, 0.9)

func _elite_chest_rarity_label(rarity: String) -> String:
    match rarity:
        "rare":
            return _tx("ui.common.rarity.rare", "Rare")
        "epic":
            return _tx("ui.common.rarity.epic", "Epic")
        "legendary":
            return _tx("ui.common.rarity.legendary", "Legendary")
        _:
            return _tx("ui.common.rarity.common", "Common")

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
        _level_reward_refresh_count = 0
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
    _refresh_level_reward_cards()

func _refresh_level_reward_cards() -> void:
    _refresh_level_reward_refresh_controls("")
    _refresh_level_reward_stat_panel()
    for i: int in range(_level_reward_buttons.size()):
        var button: Button = _level_reward_buttons[i]
        if button == null:
            continue
        if i >= _level_reward_choices.size():
            button.disabled = true
            button.set_meta("reward_id", "none")
            button.tooltip_text = ""
            _set_reward_card_labels(button, _tx("ui.game_scene.no_weapon", "No Reward"), "", "", Color(0.62, 0.72, 0.78, 0.9))
            button.add_theme_stylebox_override("normal", _build_reward_card_style("common", false))
            button.add_theme_stylebox_override("hover", _build_reward_card_style("common", true))
            button.add_theme_stylebox_override("pressed", _build_reward_card_style("common", true))
            continue
        var reward: Dictionary = _level_reward_choices[i]
        var rarity: String = str(reward.get("rarity", "common")).to_lower()
        var rarity_color: Color = _level_reward_rarity_color(rarity)
        var effect_text: String = _format_reward_effects(reward.get("effects", []))
        button.disabled = false
        button.text = ""
        button.set_meta("reward_id", str(reward.get("id", "")))
        button.tooltip_text = ""
        var body_effect_text: String = effect_text
        if _reward_effect_line_count(reward.get("effects", [])) <= 1:
            body_effect_text = ""
        _set_reward_card_labels(
            button,
            _format_level_reward_title(reward),
            _level_reward_rarity_label(rarity),
            body_effect_text,
            rarity_color
        )
        button.add_theme_color_override("font_color", Color(0.92, 0.98, 1.0, 1.0))
        button.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
        button.add_theme_stylebox_override("normal", _build_reward_card_style(rarity, false))
        button.add_theme_stylebox_override("hover", _build_reward_card_style(rarity, true))
        button.add_theme_stylebox_override("pressed", _build_reward_card_style(rarity, true))

func _on_level_reward_refresh_pressed() -> void:
    var refresh_price: int = _calculate_level_reward_refresh_price()
    if _current_gold_runtime < refresh_price:
        _refresh_level_reward_refresh_controls(_tx("msg.level_reward.not_enough_gold", "Not enough gold"))
        return
    _current_gold_runtime = max(0, _current_gold_runtime - refresh_price)
    _level_reward_refresh_count += 1
    _refresh_player_hud()
    _refresh_level_reward_choices()
    _refresh_level_reward_refresh_controls(_tx("msg.level_reward.refreshed", "Rewards refreshed"))

func _refresh_level_reward_refresh_controls(hint_text: String = "") -> void:
    var refresh_price: int = _calculate_level_reward_refresh_price()
    if _level_reward_refresh_button != null:
        _level_reward_refresh_button.text = _tf("ui.game_scene.level_reward_refresh_fmt", [refresh_price], "Refresh (%dG)")
        _level_reward_refresh_button.disabled = _current_gold_runtime < refresh_price
    if _level_reward_hint_label != null:
        if hint_text.is_empty() and _current_gold_runtime < refresh_price:
            _level_reward_hint_label.text = _tx("msg.level_reward.not_enough_gold", "Not enough gold")
        else:
            _level_reward_hint_label.text = hint_text

func _calculate_level_reward_refresh_price() -> int:
    var stage_num: int = _parse_stage_number(GameManager.current_stage_id)
    var inflation: int = 1 + int(max(0, stage_num - 1) / 5)
    return max(1, stage_num) + (_level_reward_refresh_count * inflation)

func _parse_stage_number(stage_id: String) -> int:
    var parts: PackedStringArray = stage_id.strip_edges().split("_")
    for i: int in range(parts.size() - 1, -1, -1):
        if parts[i].is_valid_int():
            return max(1, int(parts[i]))
    return 1

func _set_reward_card_labels(button: Button, title_text: String, rarity_text: String, effect_text: String, rarity_color: Color) -> void:
    var title := button.find_child("RewardTitle", true, false) as Label
    if title != null:
        title.text = title_text
    var rarity := button.find_child("RewardRarity", true, false) as Label
    if rarity != null:
        rarity.text = rarity_text
        rarity.add_theme_color_override("font_color", rarity_color)
    var divider := button.find_child("RewardDivider", true, false) as ColorRect
    if divider != null:
        divider.color = Color(rarity_color.r, rarity_color.g, rarity_color.b, 0.34)
    var effect := button.find_child("RewardEffect", true, false) as Label
    if effect != null:
        effect.text = effect_text

func _format_level_reward_title(reward: Dictionary) -> String:
    var effect_text: String = _format_reward_effects(reward.get("effects", []))
    var first_line_index: int = effect_text.find("\n")
    if first_line_index >= 0:
        return effect_text.substr(0, first_line_index)
    if not effect_text.is_empty():
        return effect_text
    return str(reward.get("name", "Reward"))

func _format_reward_effects(raw_effects: Variant) -> String:
    if not (raw_effects is Array):
        return ""
    var lines: PackedStringArray = PackedStringArray()
    for effect_value: Variant in raw_effects:
        if not (effect_value is Dictionary):
            continue
        var effect: Dictionary = effect_value
        var effect_type: String = str(effect.get("type", ""))
        var value: float = float(effect.get("value", 0.0))
        var line: String = _format_reward_effect_line(effect_type, value)
        if not line.is_empty():
            lines.append(line)
    return "\n".join(lines)

func _reward_effect_line_count(raw_effects: Variant) -> int:
    if not (raw_effects is Array):
        return 0
    var count: int = 0
    for effect_value: Variant in raw_effects:
        if not (effect_value is Dictionary):
            continue
        var effect: Dictionary = effect_value
        if not _format_reward_effect_line(str(effect.get("type", "")), float(effect.get("value", 0.0))).is_empty():
            count += 1
    return count

func _format_reward_effect_line(effect_type: String, value: float) -> String:
    match effect_type:
        "attack_damage_flat":
            return _reward_effect_text("damage", _format_signed_number(value), "Damage %s")
        "melee_damage_flat":
            return _reward_effect_text("melee", _format_signed_number(value), "Melee Damage %s")
        "ranged_damage_flat":
            return _reward_effect_text("ranged", _format_signed_number(value), "Ranged Damage %s")
        "global_attack_percent_flat":
            return _reward_effect_text("damage", _format_signed_percent(value / 100.0), "Damage %s")
        "target_range_flat":
            return _reward_effect_text("range", _format_signed_number(value), "Range %s")
        "move_speed_flat":
            return _reward_effect_text("move", _format_signed_number(value), "Move Speed %s")
        "max_hp_flat":
            return _reward_effect_text("max_hp", _format_signed_number(value), "Max HP %s")
        "heal_flat":
            return _reward_effect_text("heal", _format_signed_number(value), "Heal %s")
        "armor_flat":
            return _reward_effect_text("armor", _format_signed_number(value), "Armor %s")
        "dodge_chance_flat":
            return _reward_effect_text("dodge", _format_signed_percent(value), "Dodge %s")
        "crit_chance_flat":
            return _reward_effect_text("crit", _format_signed_percent(value), "Crit Chance %s")
        "crit_multiplier_flat":
            return _reward_effect_text("crit_damage", _format_signed_percent(value), "Crit Damage %s")
        "lifesteal_flat":
            return _reward_effect_text("lifesteal", _format_signed_percent(value), "Lifesteal %s")
        "luck_flat":
            return _reward_effect_text("luck", _format_signed_number(value), "Luck %s")
        "harvest_flat":
            return _reward_effect_text("harvest", _format_signed_number(value), "Harvest %s")
        "hp_regen_flat":
            return _reward_effect_text("hp_regen", _format_signed_number(value), "HP Regen %s")
        "xp_gain_mult":
            return _reward_effect_text("xp_gain", _format_multiplier_bonus(value), "XP Gain %s")
        "gold_gain_mult":
            return _reward_effect_text("gold_gain", _format_multiplier_bonus(value), "Gold Gain %s")
        "stamina_recover_mult":
            return _reward_effect_text("stamina_regen", _format_multiplier_bonus(value), "Stamina Regen %s")
        "auto_attack_interval_mult":
            return _reward_effect_text("attack_speed", _format_interval_multiplier_as_attack_speed(value), "Attack Speed %s")
        "attack_speed_mult":
            return _reward_effect_text("attack_speed", _format_multiplier_bonus(value), "Attack Speed %s")
        _:
            return ""

func _reward_effect_text(effect_key: String, value_text: String, fallback: String) -> String:
    return _tf("ui.game_scene.reward_effect.%s_fmt" % effect_key, [value_text], fallback)

func _refresh_level_reward_stat_panel() -> void:
    if _player == null or not is_instance_valid(_player):
        return
    _set_level_reward_stat("hp", "%d/%d" % [_player.current_hp, _player.max_hp])
    _set_level_reward_stat("damage", "+%d / +%s" % [_player.get_attack_damage_bonus(), _format_percent_plain(_player.get_global_attack_percent() / 100.0)])
    _set_level_reward_stat("melee", "+%d" % _player.get_melee_attack_damage_bonus())
    _set_level_reward_stat("ranged", "+%d" % _player.get_ranged_attack_damage_bonus())
    _set_level_reward_stat("attack_speed", _format_percent_plain(_player.get_attack_speed_multiplier() - 1.0))
    _set_level_reward_stat("crit", _format_percent_plain(_player.crit_chance))
    _set_level_reward_stat("armor", _format_number(_player.armor))
    _set_level_reward_stat("dodge", _format_percent_plain(_player.dodge_chance))
    _set_level_reward_stat("move", _format_number(_player.move_speed))
    _set_level_reward_stat("range", _format_number(_player.get_current_target_range()))
    _set_level_reward_stat("lifesteal", _format_percent_plain(_player.lifesteal))
    _set_level_reward_stat("luck", _format_number(_player.luck))
    _set_level_reward_stat("harvest", _format_number(_player.get_harvest()))
    _set_level_reward_stat("xp", _format_percent_plain(_player.get_xp_gain_multiplier() - 1.0))
    _set_level_reward_stat("gold", _format_percent_plain(_gold_multiplier - 1.0))

func _set_level_reward_stat(key: String, value: String) -> void:
    var label_value: Variant = _level_reward_stat_labels.get(key, null)
    if label_value is Label:
        var label: Label = label_value
        label.text = value

func _stat_label(stat_key: String) -> String:
    return _tx("ui.stat.%s" % stat_key, _stat_label_fallback(stat_key))

func _stat_label_fallback(stat_key: String) -> String:
    match stat_key:
        "hp":
            return "HP"
        "stamina":
            return "Stamina"
        "level":
            return "Level"
        "xp":
            return "XP"
        "gold":
            return "Gold"
        "damage":
            return "Damage"
        "attack":
            return "Attack"
        "melee":
            return "Melee Damage"
        "ranged":
            return "Ranged Damage"
        "attack_speed":
            return "Attack Speed"
        "crit":
            return "Crit Chance"
        "armor":
            return "Armor"
        "dodge":
            return "Dodge"
        "move":
            return "Move Speed"
        "range":
            return "Range"
        "lifesteal":
            return "Lifesteal"
        "luck":
            return "Luck"
        "harvest":
            return "Harvest"
        _:
            return stat_key

func _build_reward_card_style(rarity: String, highlighted: bool) -> StyleBoxFlat:
    var border: Color = _level_reward_rarity_color(rarity)
    var fill_alpha: float = 0.88 if highlighted else 0.78
    var style: StyleBoxFlat = _build_neon_panel_style(
        Color(0.01, 0.04, 0.065, fill_alpha),
        border,
        2,
        10 if highlighted else 6
    )
    style.content_margin_left = 12
    style.content_margin_top = 12
    style.content_margin_right = 12
    style.content_margin_bottom = 12
    return style

func _level_reward_rarity_color(rarity: String) -> Color:
    match rarity:
        "rare":
            return Color(0.0, 0.92, 1.0, 0.95)
        "epic":
            return Color(0.72, 0.38, 1.0, 0.95)
        "legendary":
            return Color(1.0, 0.68, 0.0, 0.98)
        _:
            return Color(0.62, 0.72, 0.78, 0.9)

func _level_reward_rarity_label(rarity: String) -> String:
    match rarity:
        "rare":
            return _tx("ui.common.rarity.rare", "Rare").to_upper()
        "epic":
            return _tx("ui.common.rarity.epic", "Epic").to_upper()
        "legendary":
            return _tx("ui.common.rarity.legendary", "Legendary").to_upper()
        _:
            return _tx("ui.common.rarity.common", "Common").to_upper()

func _format_signed_number(value: float) -> String:
    var prefix: String = "+" if value >= 0.0 else ""
    return "%s%s" % [prefix, _format_number(value)]

func _format_number(value: float) -> String:
    if absf(value - round(value)) < 0.01:
        return str(int(round(value)))
    return "%.1f" % value

func _format_signed_percent(value: float) -> String:
    var prefix: String = "+" if value >= 0.0 else ""
    return "%s%s" % [prefix, _format_percent_plain(value)]

func _format_percent_plain(value: float) -> String:
    var percent_value: float = value * 100.0
    if absf(percent_value - round(percent_value)) < 0.01:
        return "%d%%" % int(round(percent_value))
    return "%.1f%%" % percent_value

func _format_multiplier_bonus(multiplier: float) -> String:
    return _format_signed_percent(multiplier - 1.0)

func _format_interval_multiplier_as_attack_speed(multiplier: float) -> String:
    var safe_multiplier: float = max(0.05, multiplier)
    return _format_signed_percent((1.0 / safe_multiplier) - 1.0)

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

func _capture_stage_retry_snapshot() -> void:
    _stage_retry_snapshot = _sanitize_stage_retry_payload(_build_runtime_save_payload())

func _build_stage_retry_payload() -> Dictionary:
    if not _stage_retry_snapshot.is_empty():
        return _sanitize_stage_retry_payload(_stage_retry_snapshot)
    var fallback_payload: Dictionary = _sanitize_stage_retry_payload(_build_runtime_save_payload())
    var max_hp: int = max(1, int(fallback_payload.get("player_max_hp", 1)))
    fallback_payload["player_hp"] = max_hp
    fallback_payload["player_stamina"] = float(fallback_payload.get("player_stamina_max", 100.0))
    return fallback_payload

func _sanitize_stage_retry_payload(raw_payload: Dictionary) -> Dictionary:
    var payload: Dictionary = raw_payload.duplicate(true)
    payload["stage_id"] = str(payload.get("stage_id", GameManager.current_stage_id))
    payload["wave"] = 1
    payload["wave_progress_index"] = 0
    payload["player_pos_x"] = 0.0
    payload["player_pos_y"] = 0.0
    payload["pending_elite_chests"] = 0
    payload["current_elite_chest_offer"] = {}
    payload["reward_opened"] = false
    payload["wave_end_reward_gate_active"] = false
    payload["pending_wave_shop_snapshot"] = {}
    payload["battle_elapsed"] = 0.0
    payload["endless_shop_transitioning"] = false
    payload["selected_starter_weapon_id"] = str(payload.get("selected_starter_weapon_id", _selected_starter_weapon_id_runtime))
    if str(payload.get("selected_character", "")).is_empty():
        payload["selected_character"] = _current_player_id
    var shop_state: Dictionary = _normalize_shop_runtime_state(payload.get("shop_runtime_state", {}))
    payload["shop_runtime_state"] = shop_state
    payload["equipped_weapons"] = _extract_weapon_list_from_shop_state(shop_state)
    payload["locked_shop_offers"] = _extract_locked_offer_list_from_shop_state(shop_state)
    return payload

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
    var player_move_speed: float = 150.0
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
        "stage_drop_double_active": bool(GameManager.call("is_stage_drop_double_active")) if GameManager != null and GameManager.has_method("is_stage_drop_double_active") else false,
        "next_stage_drop_double_pending": bool(GameManager.next_stage_drop_double_pending) if GameManager != null else false,
        "run_kill_count": _run_kill_count,
        "run_survival_time": _run_survival_time_runtime + _battle_elapsed,
        "pending_elite_chests": _pending_elite_chests,
        "is_endless_mode": _is_endless_mode,
        "endless_elapsed": _endless_elapsed,
        "endless_level": _endless_level,
        "endless_shop_timer": _endless_shop_timer,
        "endless_base_max_enemy_count": _endless_base_max_enemy_count,
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
    GameManager.current_difficulty = GameManager._normalize_difficulty(str(slot_data.get("difficulty", "danger_1")))
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
    if _player_camera != null and is_instance_valid(_player_camera):
        _player_camera.reset_smoothing()
        _player_camera.force_update_scroll()


    _player.move_speed = float(slot_data.get("player_move_speed", _player.move_speed))
    _player.bonus_target_range = float(slot_data.get("bonus_target_range", 0.0))
    _player.pickup_radius = float(slot_data.get("pickup_radius", _player.pickup_radius))
    _xp_multiplier = max(0.1, float(slot_data.get("xp_gain_mult", _xp_multiplier)))
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
    _pending_elite_chests = max(0, int(slot_data.get("pending_elite_chests", 0)))
    _current_elite_chest_offer = {}
    _reward_opened = false
    _wave_end_reward_gate_active = false
    _pending_wave_shop_snapshot = {}
    _wave_progress_index = max(0, int(slot_data.get("wave_progress_index", wave_id - 1)))
    _current_gold_runtime = max(0, int(slot_data.get("current_gold", _current_gold_runtime)))
    _run_kill_count = max(0, int(slot_data.get("run_kill_count", 0)))
    _run_survival_time_runtime = max(0.0, float(slot_data.get("run_survival_time", 0.0)))
    _is_endless_mode = bool(slot_data.get("is_endless_mode", false))
    _endless_elapsed = max(0.0, float(slot_data.get("endless_elapsed", 0.0)))
    _endless_level = max(0, int(slot_data.get("endless_level", 0)))
    _endless_shop_timer = clampf(float(slot_data.get("endless_shop_timer", 0.0)), 0.0, ENDLESS_SHOP_INTERVAL)
    _endless_base_max_enemy_count = max(0, int(slot_data.get("endless_base_max_enemy_count", _max_enemy_count_runtime)))
    _endless_shop_transitioning = false
    if _is_endless_mode:
        GameManager.current_stage_id = ENDLESS_ENTRY_STAGE_ID
        _apply_endless_elite_schedule()
        _next_elite_spawn_time = _battle_elapsed + randf_range(8.0, ENDLESS_ELITE_FIRST_SPAWN_MAX)
        _active_elite = null
        _refresh_endless_level()
    var has_explicit_shop_runtime_state: bool = slot_data.has("shop_runtime_state") and slot_data.get("shop_runtime_state", {}) is Dictionary
    _shop_runtime_state = _normalize_shop_runtime_state(slot_data.get("shop_runtime_state", {}))
    if _shop_runtime_state.get("equipped_weapons", []).is_empty():
        var legacy_equipped: Variant = slot_data.get("equipped_weapons", [])
        if legacy_equipped is Array:
            _shop_runtime_state["equipped_weapons"] = legacy_equipped.duplicate(true)
    if not has_explicit_shop_runtime_state and _shop_runtime_state.get("locked_shop_offers", []).is_empty():
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
    _enemy_count_multiplier = max(0.1, float(difficulty_modifiers.get("enemy_count", 1.0)))
    _enemy_move_speed_difficulty_multiplier = max(0.1, float(difficulty_modifiers.get("enemy_speed", 1.0)))
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

    var melee_weight: float = float(enemy_mix.get("melee_weight", ENEMY_MELEE_WEIGHT))
    var fast_melee_weight: float = float(enemy_mix.get("fast_melee_weight", ENEMY_FAST_MELEE_WEIGHT))
    var charger_weight: float = float(enemy_mix.get("charger_weight", ENEMY_CHARGER_WEIGHT))
    var ranged_weight: float = float(enemy_mix.get("ranged_weight", ENEMY_RANGED_WEIGHT))
    var barrage_weight: float = float(enemy_mix.get("barrage_weight", ENEMY_BARRAGE_WEIGHT))
    var splitter_weight: float = float(enemy_mix.get("splitter_weight", 0.0))
    var sniper_weight: float = float(enemy_mix.get("sniper_weight", 0.0))
    var mine_seeder_weight: float = float(enemy_mix.get("mine_seeder_weight", 0.0))
    melee_weight = max(0.0, melee_weight)
    fast_melee_weight = max(0.0, fast_melee_weight)
    charger_weight = max(0.0, charger_weight)
    ranged_weight = max(0.0, ranged_weight)
    barrage_weight = max(0.0, barrage_weight)
    splitter_weight = max(0.0, splitter_weight)
    sniper_weight = max(0.0, sniper_weight)
    mine_seeder_weight = max(0.0, mine_seeder_weight)
    var target_melee_ratio: float = _target_melee_spawn_ratio(_extract_stage_number(stage_id), bool(stage_profile.get("is_boss_stage", false)))
    var melee_total: float = melee_weight + fast_melee_weight + charger_weight + splitter_weight
    var ranged_total: float = ranged_weight + barrage_weight + sniper_weight + mine_seeder_weight
    if melee_total > 0.0 and ranged_total > 0.0:
        var current_melee_ratio: float = melee_total / (melee_total + ranged_total)
        if current_melee_ratio < target_melee_ratio:
            var capped_ranged_total: float = melee_total * (1.0 - target_melee_ratio) / target_melee_ratio
            var ranged_scale: float = capped_ranged_total / ranged_total
            ranged_weight *= ranged_scale
            barrage_weight *= ranged_scale
            sniper_weight *= ranged_scale
            mine_seeder_weight *= ranged_scale

    _enemy_spawn_weights_runtime = {
        Enemy.EnemyType.MELEE: melee_weight,
        Enemy.EnemyType.FAST_MELEE: fast_melee_weight,
        Enemy.EnemyType.CHARGER: charger_weight,
        Enemy.EnemyType.RANGED: ranged_weight,
        Enemy.EnemyType.BARRAGE: barrage_weight,
        Enemy.EnemyType.SPLITTER: splitter_weight,
        Enemy.EnemyType.SNIPER: sniper_weight,
        Enemy.EnemyType.MINE_SEEDER: mine_seeder_weight,
    }

func _target_melee_spawn_ratio(stage_number: int, is_boss_stage: bool) -> float:
    if is_boss_stage:
        return 0.82
    if stage_number <= 4:
        return 0.78
    if stage_number <= 7:
        return 0.74
    if stage_number <= 10:
        return 0.70
    if stage_number <= 13:
        return 0.76
    if stage_number <= 16:
        return 0.80
    if stage_number <= 19:
        return 0.84
    return 0.70

func _apply_stage_runtime_from_balance(stage_id: String) -> void:
    var stage_profile: Dictionary = BalanceService.get_stage_profile(stage_id)
    _stage_is_boss_stage = bool(stage_profile.get("is_boss_stage", false))
    _stage_background_key = str(stage_profile.get("background_key", "")).to_lower()
    _apply_elite_schedule_from_stage_profile(stage_profile)
    _enemy_hp_stage_multiplier = clampf(float(stage_profile.get("enemy_hp_multiplier", 1.0)), 0.1, 10.0)
    _enemy_move_speed_stage_multiplier = clampf(
        float(stage_profile.get("enemy_move_speed_multiplier", 1.0)),
        0.1,
        3.0
    )
    _enemy_damage_stage_multiplier = clampf(float(stage_profile.get("enemy_damage_multiplier", 1.0)), 0.1, 10.0)
    var wave_profile: Dictionary = {}
    if wave_manager != null and wave_manager.has_method("get_current_wave_definition"):
        wave_profile = wave_manager.get_current_wave_definition()
    
    # 鍔犺浇鐢熸垚閰嶇疆
    var combat_params: Dictionary = BalanceService.get_global_combat_params()
    var spawn_profile: Dictionary = stage_profile.get("spawn_profile", {})
    var resource_profile: Dictionary = stage_profile.get("resource_profile", {})
    
    var base_initial_enemy_count: int = int(combat_params.get("initial_enemy_count", INITIAL_ENEMY_COUNT))
    _initial_enemy_count_runtime = max(0, int(round(float(base_initial_enemy_count) * _enemy_count_multiplier)))
    _enemy_min_spawn_radius_runtime = max(
        0.0,
        float(combat_params.get("enemy_min_spawn_radius", ENEMY_MIN_SPAWN_RADIUS))
    )
    _enemy_max_spawn_radius_runtime = max(
        _enemy_min_spawn_radius_runtime,
        float(combat_params.get("enemy_max_spawn_radius", ENEMY_MAX_SPAWN_RADIUS))
    )
    _contact_damage_runtime = max(1, int(combat_params.get("contact_damage_default", CONTACT_DAMAGE)))
    _contact_damage_interval_runtime = max(
        0.01,
        float(combat_params.get("contact_damage_interval", CONTACT_DAMAGE_INTERVAL))
    )
    var base_max_enemy_count: int = int(spawn_profile.get("max_enemy_count", MAX_ENEMY_COUNT))
    _max_enemy_count_runtime = clampi(
        int(round(float(base_max_enemy_count) * _enemy_count_multiplier)),
        1,
        HARD_MAX_ACTIVE_ENEMY_COUNT
    )
    _spawn_interval_start_runtime = float(spawn_profile.get("spawn_interval_start", ENEMY_SPAWN_INTERVAL))
    _spawn_interval_end_runtime = float(spawn_profile.get("spawn_interval_end", ENEMY_SPAWN_INTERVAL))
    _spawn_batch_start_runtime = max(1, int(spawn_profile.get("spawn_batch_start", 1)))
    _spawn_batch_end_runtime = max(1, int(spawn_profile.get("spawn_batch_end", _spawn_batch_start_runtime)))
    var stage_number: int = max(1, _extract_stage_number(stage_id))
    var default_melee_pressure_start: float = _default_melee_pressure_interval_start(stage_number, _stage_is_boss_stage)
    var default_melee_pressure_end: float = _default_melee_pressure_interval_end(stage_number, _stage_is_boss_stage)
    _melee_pressure_interval_start_runtime = max(
        MELEE_PRESSURE_MIN_INTERVAL,
        float(spawn_profile.get("melee_pressure_interval_start", default_melee_pressure_start))
    )
    _melee_pressure_interval_end_runtime = max(
        MELEE_PRESSURE_MIN_INTERVAL,
        float(spawn_profile.get("melee_pressure_interval_end", default_melee_pressure_end))
    )
    _melee_pressure_fast_weight_runtime = max(
        0.0,
        float(spawn_profile.get("melee_pressure_fast_weight", _default_melee_pressure_fast_weight(stage_number)))
    )
    _melee_pressure_charger_weight_runtime = max(
        0.0,
        float(spawn_profile.get("melee_pressure_charger_weight", _default_melee_pressure_charger_weight(stage_number, _stage_is_boss_stage)))
    )
    _stage_xp_drop_multiplier = max(0.0, float(resource_profile.get("xp_drop_multiplier", 1.0)))
    _stage_gold_drop_multiplier = max(0.0, float(resource_profile.get("gold_drop_multiplier", 1.0)))

    _stage_target_duration = _resolve_stage_duration_runtime(stage_id, stage_profile, wave_profile)
    _wave_duration_runtime = _stage_target_duration
    _apply_arena_size_from_background_texture()
    queue_redraw()

func _default_melee_pressure_interval_start(stage_number: int, is_boss_stage: bool) -> float:
    if is_boss_stage:
        return 1.45
    if stage_number <= 4:
        return 1.5
    if stage_number <= 7:
        return 1.2
    if stage_number <= 14:
        return 0.95
    return 0.8

func _default_melee_pressure_interval_end(stage_number: int, is_boss_stage: bool) -> float:
    if is_boss_stage:
        return 1.05
    if stage_number <= 4:
        return 1.2
    if stage_number <= 7:
        return 0.9
    if stage_number <= 14:
        return 0.72
    return 0.62

func _default_melee_pressure_fast_weight(stage_number: int) -> float:
    if stage_number <= 4:
        return 0.18
    if stage_number <= 7:
        return 0.34
    return 0.5

func _default_melee_pressure_charger_weight(stage_number: int, is_boss_stage: bool) -> float:
    if is_boss_stage:
        return 0.08
    if stage_number <= 7:
        return 0.0
    if stage_number <= 14:
        return 0.08
    return 0.14

func _apply_elite_schedule_from_stage_profile(stage_profile: Dictionary) -> void:
    var elite_schedule_value: Variant = stage_profile.get("elite_schedule", {})
    if not (elite_schedule_value is Dictionary):
        _elite_schedule_enabled = false
        _next_elite_spawn_time = INF
        _elite_respawn_check_interval_runtime = ELITE_RESPAWN_CHECK_INTERVAL
        _elite_respawn_interval_min_runtime = ELITE_RESPAWN_CHECK_INTERVAL
        _elite_respawn_interval_max_runtime = ELITE_RESPAWN_CHECK_INTERVAL
        _elite_max_alive_runtime = 1
        _elite_hp_override_runtime = 0
        _elite_pool_runtime = []
        return
    var elite_schedule: Dictionary = elite_schedule_value
    if elite_schedule.is_empty() and bool(stage_profile.get("is_boss_stage", false)):
        var boss_config: Dictionary = stage_profile.get("boss", {})
        if not boss_config.is_empty():
            # Boss stages reuse the elite scheduling gate, then spawn the dedicated boss class.
            _elite_schedule_enabled = true
            _next_elite_spawn_time = 0.5
            _elite_respawn_check_interval_runtime = 999.0 # Don't respawn
            _elite_respawn_interval_min_runtime = 999.0
            _elite_respawn_interval_max_runtime = 999.0
            _elite_max_alive_runtime = 1
            _elite_hp_override_runtime = 0
            _elite_pool_runtime = []
            print("[Boss] Scheduled stage boss with HP %d" % int(boss_config.get("hp", 2000)))
            return

    _elite_schedule_enabled = not elite_schedule.is_empty()
    print("[Elite] Loading schedule for %s: enabled=%s, data=%s" % [GameManager.current_stage_id, _elite_schedule_enabled, elite_schedule])
    if not _elite_schedule_enabled:
        _next_elite_spawn_time = INF
        _elite_respawn_check_interval_runtime = ELITE_RESPAWN_CHECK_INTERVAL
        _elite_respawn_interval_min_runtime = ELITE_RESPAWN_CHECK_INTERVAL
        _elite_respawn_interval_max_runtime = ELITE_RESPAWN_CHECK_INTERVAL
        _elite_max_alive_runtime = 1
        _elite_hp_override_runtime = 0
        _elite_pool_runtime = []
        return
    _next_elite_spawn_time = max(0.0, float(elite_schedule.get("first_spawn_time", ELITE_FIRST_SPAWN_TIME)))
    _elite_respawn_check_interval_runtime = max(
        1.0,
        float(elite_schedule.get("respawn_check_interval", ELITE_RESPAWN_CHECK_INTERVAL))
    )
    _elite_respawn_interval_min_runtime = max(
        1.0,
        float(elite_schedule.get("respawn_interval_min", _elite_respawn_check_interval_runtime))
    )
    _elite_respawn_interval_max_runtime = max(
        _elite_respawn_interval_min_runtime,
        float(elite_schedule.get("respawn_interval_max", _elite_respawn_check_interval_runtime))
    )
    _elite_max_alive_runtime = max(1, int(elite_schedule.get("max_alive", 1)))
    _elite_hp_override_runtime = max(0, int(elite_schedule.get("elite_hp_override", 0)))
    _elite_pool_runtime = _normalize_elite_pool(elite_schedule.get("elite_pool", []))

func _normalize_elite_pool(raw_pool: Variant) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    if raw_pool is Array:
        var pool_array: Array = raw_pool
        for entry_value: Variant in pool_array:
            if not (entry_value is Dictionary):
                continue
            var entry: Dictionary = entry_value
            var type_key: String = str(entry.get("type", "elite_warden"))
            var weight: float = max(0.0, float(entry.get("weight", 0.0)))
            if weight <= 0.0:
                continue
            result.append({"type": type_key, "weight": weight})
    if result.is_empty():
        result.append({"type": "elite_warden", "weight": 1.0})
    return result

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
        return wave_duration
        
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
    var weapon_id_to_use: String = _selected_starter_weapon_id_runtime
    if weapon_id_to_use.is_empty():
        weapon_id_to_use = "kunai" # Fallback
        
    var starter_weapon: Dictionary = _build_weapon_instance_by_id(weapon_id_to_use)
    if starter_weapon.is_empty():
        _shop_runtime_state["equipped_weapons"] = equipped
        _sync_weapon_cooldowns_with_equipped_slots()
        _refresh_weapon_tag_state_runtime(false)
        return
        
    # Only equip the selected weapon in the first slot
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
