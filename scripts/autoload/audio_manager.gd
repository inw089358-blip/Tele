extends Node

const SFX_POOL_SIZE: int = 8
const BUS_MASTER: StringName = &"Master"
const BUS_SFX: StringName = &"SFX"
const BGM_MENU_PATH: String = "res://audio/CRT_Transformer.mp3"
const BGM_PREPARE_PATH: String = "res://audio/Velvet_Hexagon.mp3"
const BGM_COMBAT_PATH: String = "res://audio/Factory_Synapse.mp3"
const UI_SELECT_SFX_PATH: String = "res://audio/ui_select.mp3"
const UI_SELECT_SFX_VOLUME_DB: float = -4.0
const UI_SELECT_SFX_MIN_INTERVAL: float = 0.035
const LEVEL_UP_SFX_PATH: String = "res://audio/level_up.mp3"
const LEVEL_UP_SFX_VOLUME_DB: float = -2.0

var _bgm_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _bgm_cache: Dictionary = {}
var _sfx_cache: Dictionary = {}
var _last_ui_select_sfx_msec: int = -1000

func _ready() -> void :
    process_mode = Node.PROCESS_MODE_ALWAYS
    _ensure_audio_bus(BUS_SFX, BUS_MASTER)
    _bgm_player = AudioStreamPlayer.new()
    _bgm_player.bus = BUS_MASTER
    add_child(_bgm_player)

    for i in SFX_POOL_SIZE:
        var sfx_player: AudioStreamPlayer = AudioStreamPlayer.new()
        sfx_player.bus = BUS_SFX
        add_child(sfx_player)
        _sfx_players.append(sfx_player)

func _input(event: InputEvent) -> void:
    if _is_pointer_button_select_event(event):
        var hovered_control: Control = get_viewport().gui_get_hovered_control()
        if _is_selectable_ui_control(hovered_control):
            play_ui_select_sfx()
        return
    if event.is_action_pressed("ui_accept"):
        var focused_control: Control = get_viewport().gui_get_focus_owner()
        if _is_selectable_ui_control(focused_control):
            play_ui_select_sfx()

func play_bgm(stream: AudioStream) -> void :
    if stream == null:
        return
    _ensure_stream_loop(stream)
    if _bgm_player.stream == stream and _bgm_player.playing:
        return
    _bgm_player.stream = stream
    _bgm_player.play()

func play_menu_bgm() -> void :
    _play_bgm_by_path(BGM_MENU_PATH)

func play_prepare_bgm() -> void :
    _play_bgm_by_path(BGM_PREPARE_PATH)

func play_combat_bgm() -> void :
    _play_bgm_by_path(BGM_COMBAT_PATH)

func stop_bgm() -> void :
    _bgm_player.stop()

func play_sfx(stream: AudioStream, volume_db: float = 0.0) -> void :
    if stream == null:
        return
    var player: AudioStreamPlayer = _get_available_sfx_player()
    player.stream = stream
    player.volume_db = volume_db
    player.play()

func play_sfx_by_path(path: String, volume_db: float = 0.0) -> void:
    var stream: AudioStream = _get_or_load_sfx_stream(path)
    play_sfx(stream, volume_db)

func play_ui_select_sfx() -> void:
    var now_msec: int = Time.get_ticks_msec()
    var elapsed_seconds: float = float(now_msec - _last_ui_select_sfx_msec) / 1000.0
    if elapsed_seconds < UI_SELECT_SFX_MIN_INTERVAL:
        return
    _last_ui_select_sfx_msec = now_msec
    play_sfx_by_path(UI_SELECT_SFX_PATH, UI_SELECT_SFX_VOLUME_DB)

func play_level_up_sfx() -> void:
    play_sfx_by_path(LEVEL_UP_SFX_PATH, LEVEL_UP_SFX_VOLUME_DB)

func _is_pointer_button_select_event(event: InputEvent) -> bool:
    if not (event is InputEventMouseButton):
        return false
    var mouse_event: InputEventMouseButton = event
    return mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT

func _is_selectable_ui_control(control: Control) -> bool:
    var current: Control = control
    while current != null:
        if current is BaseButton:
            var button: BaseButton = current
            return not button.disabled and button.visible and button.is_inside_tree()
        if current is OptionButton:
            var option_button: OptionButton = current
            return not option_button.disabled and option_button.visible and option_button.is_inside_tree()
        current = current.get_parent_control()
    return false

func _get_available_sfx_player() -> AudioStreamPlayer:
    for player in _sfx_players:
        if not player.playing:
            return player
    return _sfx_players[0]

func _ensure_audio_bus(bus_name: StringName, send_bus_name: StringName) -> void:
    if AudioServer.get_bus_index(bus_name) >= 0:
        return
    AudioServer.add_bus(AudioServer.bus_count)
    var bus_index: int = AudioServer.bus_count - 1
    AudioServer.set_bus_name(bus_index, bus_name)
    if AudioServer.get_bus_index(send_bus_name) >= 0:
        AudioServer.set_bus_send(bus_index, send_bus_name)

func _ensure_stream_loop(stream: AudioStream) -> void :
    if stream is AudioStreamMP3:
        var mp3_stream: AudioStreamMP3 = stream
        mp3_stream.loop = true

func _play_bgm_by_path(path: String) -> void :
    var stream: AudioStream = _get_or_load_mp3_stream(path)
    play_bgm(stream)

func _get_or_load_mp3_stream(path: String) -> AudioStream:
    if _bgm_cache.has(path):
        var cached: Variant = _bgm_cache[path]
        if cached is AudioStream:
            var cached_stream: AudioStream = cached
            return cached_stream

    var loaded_stream: AudioStream = _load_mp3_stream(path)
    _bgm_cache[path] = loaded_stream
    return loaded_stream

func _load_mp3_stream(path: String) -> AudioStream:
    var loaded: Resource = ResourceLoader.load(path)
    if not (loaded is AudioStream):
        push_warning("BGM stream not found/load failed: %s" % path)
        return null

    var stream: AudioStream = loaded
    _ensure_stream_loop(stream)
    return stream

func _get_or_load_sfx_stream(path: String) -> AudioStream:
    if _sfx_cache.has(path):
        var cached: Variant = _sfx_cache[path]
        if cached is AudioStream:
            var cached_stream: AudioStream = cached
            return cached_stream

    var loaded: Resource = ResourceLoader.load(path)
    if loaded is AudioStream:
        var stream: AudioStream = loaded
        _sfx_cache[path] = stream
        return stream

    return null
