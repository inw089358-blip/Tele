extends Node

enum GameState{
    MENU, 
    SETTINGS, 
    CHARACTER_SELECT, 
    WEAPON_SELECT,
    DIFFICULTY_SELECT, 
    STAGE_SELECT, 
    PLAYING, 
    PAUSED, 
    REWARD, 
    SHOP,
    STAGE_CLEAR, 
    GAME_OVER, 
    VICTORY, 
}

const SCENE_MENU: String = "res://scenes/main.tscn"
const SCENE_SETTINGS: String = "res://scenes/settings.tscn"
const SCENE_CHARACTER_SELECT: String = "res://scenes/character_select.tscn"
const SCENE_WEAPON_SELECT: String = "res://scenes/weapon_select.tscn"
const SCENE_DIFFICULTY_SELECT: String = "res://scenes/difficulty_select.tscn"
const SCENE_STAGE_SELECT: String = "res://scenes/stage_select.tscn"
const SCENE_GAME: String = "res://scenes/game.tscn"
const SCENE_REWARD: String = "res://scenes/reward_screen.tscn"
const SCENE_GAME_OVER: String = "res://scenes/game_over.tscn"
const SCENE_SHOP: String = "res://scenes/shop_scene.tscn"

var current_state: GameState = GameState.MENU
var selected_character: String = ""
var current_difficulty: String = "normal"
var current_stage_id: String = "stage_001"
var current_wave: int = 0
var selected_starter_weapon_id: String = ""
var _pending_slot_data: Dictionary = {}
var _pending_shop_snapshot: Dictionary = {}
var _scene_transition_busy: bool = false

func _ready() -> void :
    _apply_settings_from_save()
    change_state(GameState.MENU)

func change_state(next_state: GameState) -> void :
    if current_state == next_state:
        return
    var previous_state: GameState = current_state
    current_state = next_state
    EventBus.game_state_changed.emit(previous_state, next_state)

func go_to_menu() -> void :
    _change_scene_with_crt(GameState.MENU, SCENE_MENU)

func go_to_character_select() -> void :
    _change_scene_with_crt(GameState.CHARACTER_SELECT, SCENE_CHARACTER_SELECT)

func go_to_weapon_select(character_id: String) -> void :
    selected_character = character_id
    selected_starter_weapon_id = ""
    _change_scene_with_crt(GameState.WEAPON_SELECT, SCENE_WEAPON_SELECT)

func go_to_settings() -> void :
    _change_scene_with_crt(GameState.SETTINGS, SCENE_SETTINGS)

func apply_runtime_settings(settings: Dictionary) -> void :
    var display_settings: Dictionary = settings.get("display", {})
    var audio_settings: Dictionary = settings.get("audio", {})
    var system_settings: Dictionary = settings.get("system", {})

    if LocaleService != null:
        LocaleService.apply_locale(str(system_settings.get("language", "zh_CN")))

    var window_mode: String = str(display_settings.get("window_mode", "windowed"))
    _apply_window_mode(window_mode)
    _apply_resolution_if_windowed(str(display_settings.get("resolution", "1280x720")), window_mode)
    DisplayServer.window_set_vsync_mode(
        DisplayServer.VSYNC_ENABLED if bool(display_settings.get("vsync", true)) else DisplayServer.VSYNC_DISABLED
    )
    Engine.max_fps = max(0, int(display_settings.get("fps_cap", 60)))
    var ui_scale: float = clamp(float(display_settings.get("ui_scale", 100)) / 100.0, 0.8, 1.2)
    get_window().content_scale_factor = ui_scale

    _apply_bus_volume("Master", int(audio_settings.get("master_volume", 80)))
    _apply_bus_volume("Music", int(audio_settings.get("music_volume", 70)))
    _apply_bus_volume("SFX", int(audio_settings.get("sfx_volume", 90)))
    _apply_bus_volume("UI", int(audio_settings.get("ui_volume", 80)))

func _apply_settings_from_save() -> void :
    var settings: Dictionary = SaveSystem.get_settings()
    if LocaleService != null:
        LocaleService.init_from_settings(settings)
    apply_runtime_settings(settings)

func _apply_window_mode(window_mode: String) -> void :
    match window_mode:
        "windowed":
            DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
            DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
        "borderless":
            DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
            DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
        _:
            DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
            DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)

func _apply_resolution_if_windowed(resolution_text: String, window_mode: String) -> void :
    if window_mode == "fullscreen":
        return
    var parts: PackedStringArray = resolution_text.split("x")
    if parts.size() != 2:
        return
    var width: int = int(parts[0])
    var height: int = int(parts[1])
    if width <= 0 or height <= 0:
        return
    DisplayServer.window_set_size(Vector2i(width, height))

func _apply_bus_volume(bus_name: String, value_percent: int) -> void :
    var bus_index: int = AudioServer.get_bus_index(bus_name)
    if bus_index < 0:
        return
    var clamped_percent: float = clamp(float(value_percent), 0.0, 100.0)
    if clamped_percent <= 0.0:
        AudioServer.set_bus_volume_db(bus_index, -80.0)
        return
    AudioServer.set_bus_volume_db(bus_index, linear_to_db(clamped_percent / 100.0))

func go_to_stage_select(character_id: String) -> void :
    selected_character = character_id
    _change_scene_with_crt(GameState.STAGE_SELECT, SCENE_STAGE_SELECT)

func go_to_difficulty_select(character_id: String) -> void :
    selected_character = character_id
    _change_scene_with_crt(GameState.DIFFICULTY_SELECT, SCENE_DIFFICULTY_SELECT)

func go_to_difficulty_select_with_weapon(weapon_id: String) -> void:
    selected_starter_weapon_id = weapon_id
    _change_scene_with_crt(GameState.DIFFICULTY_SELECT, SCENE_DIFFICULTY_SELECT)

func start_new_run_with_difficulty(difficulty_id: String) -> void :
    current_difficulty = _normalize_difficulty(difficulty_id)
    if selected_starter_weapon_id.is_empty():
        selected_starter_weapon_id = _resolve_default_starter_weapon_id()
    start_game("stage_001")

func get_difficulty_modifiers() -> Dictionary:
    match _normalize_difficulty(current_difficulty):
        "easy":
            return {
                "enemy_hp": 0.85, 
                "enemy_damage": 0.85, 
                "spawn_interval": 1.12, 
                "xp": 0.9, 
                "gold": 0.9, 
            }
        "hard":
            return {
                "enemy_hp": 1.25, 
                "enemy_damage": 1.2, 
                "spawn_interval": 0.9, 
                "xp": 1.15, 
                "gold": 1.15, 
            }
        _:
            return {
                "enemy_hp": 1.0, 
                "enemy_damage": 1.0, 
                "spawn_interval": 1.0, 
                "xp": 1.0, 
                "gold": 1.0, 
            }

func start_game(stage_id: String = "stage_001") -> void :
    current_stage_id = stage_id
    current_wave = 1
    if selected_starter_weapon_id.is_empty():
        selected_starter_weapon_id = _resolve_default_starter_weapon_id()
    _pending_slot_data = {}
    _pending_shop_snapshot = {}
    _change_scene_with_crt(GameState.PLAYING, SCENE_GAME)

func start_game_with_runtime(stage_id: String, runtime_data: Dictionary) -> void:
    current_stage_id = stage_id
    current_wave = 1
    _pending_slot_data = runtime_data.duplicate(true)
    _pending_slot_data["wave"] = 1
    _pending_slot_data["stage_id"] = stage_id
    _pending_slot_data["selected_starter_weapon_id"] = str(
        runtime_data.get("selected_starter_weapon_id", selected_starter_weapon_id)
    )
    if str(_pending_slot_data.get("selected_starter_weapon_id", "")).is_empty():
        _pending_slot_data["selected_starter_weapon_id"] = _resolve_default_starter_weapon_id()
    _pending_shop_snapshot = {}
    _change_scene_with_crt(GameState.PLAYING, SCENE_GAME)

func start_game_from_slot(slot_data: Dictionary) -> void :
    selected_character = str(slot_data.get("selected_character", "the_fool"))
    if selected_character.is_empty():
        selected_character = "the_fool"
    current_difficulty = _normalize_difficulty(str(slot_data.get("difficulty", "normal")))
    current_stage_id = str(slot_data.get("stage_id", "stage_001"))
    selected_starter_weapon_id = str(slot_data.get("selected_starter_weapon_id", ""))
    if selected_starter_weapon_id.is_empty():
        selected_starter_weapon_id = _resolve_default_starter_weapon_id()
    current_wave = 1
    _pending_slot_data = slot_data.duplicate(true)
    _pending_slot_data["wave"] = 1
    _pending_slot_data["selected_starter_weapon_id"] = selected_starter_weapon_id
    _pending_shop_snapshot = {}
    _change_scene_with_crt(GameState.PLAYING, SCENE_GAME)

func consume_pending_slot_data() -> Dictionary:
    var result: Dictionary = _pending_slot_data.duplicate(true)
    _pending_slot_data = {}
    return result

func open_wave_shop(snapshot: Dictionary) -> void:
    _pending_shop_snapshot = snapshot.duplicate(true)
    _change_scene_with_crt(GameState.SHOP, SCENE_SHOP)

func consume_pending_shop_snapshot() -> Dictionary:
    var result: Dictionary = _pending_shop_snapshot.duplicate(true)
    _pending_shop_snapshot = {}
    return result

# Legacy compatibility path for old hub scenes/scripts.
func consume_pending_hub_snapshot() -> Dictionary:
    return consume_pending_shop_snapshot()

func continue_from_shop(snapshot: Dictionary) -> void:
    current_stage_id = str(snapshot.get("stage_id", current_stage_id))
    selected_starter_weapon_id = str(snapshot.get("selected_starter_weapon_id", selected_starter_weapon_id))
    if selected_starter_weapon_id.is_empty():
        selected_starter_weapon_id = _resolve_default_starter_weapon_id()
    current_wave = 1
    _pending_slot_data = snapshot.duplicate(true)
    _pending_slot_data["wave"] = 1
    _pending_slot_data["selected_starter_weapon_id"] = selected_starter_weapon_id
    _pending_shop_snapshot = {}
    _change_scene_with_crt(GameState.PLAYING, SCENE_GAME)

# Legacy compatibility path for the older supply-hub workflow.
func continue_from_hub(snapshot: Dictionary) -> void:
    continue_from_shop(snapshot)

func open_reward() -> void :
    _change_scene_with_crt(GameState.REWARD, SCENE_REWARD, true)

func pause_game() -> void :
    if current_state != GameState.PLAYING:
        return
    change_state(GameState.PAUSED)
    get_tree().paused = true

func resume_game() -> void :
    if current_state != GameState.PAUSED:
        return
    change_state(GameState.PLAYING)
    get_tree().paused = false

func end_game(is_victory: bool, use_crt_shutdown: bool = true) -> void :
    var next_state: GameState = GameState.VICTORY if is_victory else GameState.GAME_OVER
    change_state(next_state)
    get_tree().paused = false
    EventBus.game_over.emit(is_victory)
    _change_scene_with_crt(next_state, SCENE_GAME_OVER, false, false, use_crt_shutdown, true)

func _change_scene_with_crt(
    next_state: GameState,
    scene_path: String,
    pause_after_transition: bool = false,
    emit_state_before_transition: bool = true,
    play_shutdown: bool = true,
    play_startup: bool = true
) -> void:
    if _scene_transition_busy:
        return
    _run_scene_transition(
        next_state,
        scene_path,
        pause_after_transition,
        emit_state_before_transition,
        play_shutdown,
        play_startup
    )

func _run_scene_transition(
    next_state: GameState,
    scene_path: String,
    pause_after_transition: bool,
    emit_state_before_transition: bool,
    play_shutdown: bool,
    play_startup: bool
) -> void:
    _scene_transition_busy = true
    get_tree().paused = false

    if emit_state_before_transition:
        change_state(next_state)

    if play_shutdown and CRTTransition != null and CRTTransition.has_method("play_shutdown"):
        await CRTTransition.play_shutdown()

    get_tree().change_scene_to_file(scene_path)
    await get_tree().process_frame

    if not emit_state_before_transition:
        change_state(next_state)

    if play_startup and CRTTransition != null and CRTTransition.has_method("play_startup"):
        await CRTTransition.play_startup()

    get_tree().paused = pause_after_transition
    _scene_transition_busy = false

func _normalize_difficulty(value: String) -> String:
    var lowered: String = value.to_lower()
    if lowered == "easy" or lowered == "hard":
        return lowered
    return "normal"

func _resolve_default_starter_weapon_id() -> String:
    var shop_catalog: Dictionary = BalanceService.get_shop_catalog()
    var weapon_pool: Variant = shop_catalog.get("weapon_pool", [])
    if weapon_pool is Array:
        for weapon_value in weapon_pool:
            if not (weapon_value is Dictionary):
                continue
            var weapon_entry: Dictionary = weapon_value
            if not bool(weapon_entry.get("starter", false)):
                continue
            var weapon_id: String = str(weapon_entry.get("weapon_id", ""))
            if not weapon_id.is_empty():
                return weapon_id
    return ""
