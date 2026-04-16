extends Node

const SFX_POOL_SIZE: int = 8
const BGM_MENU_PATH: String = "res://audio/CRT Transformer.mp3"
const BGM_PREPARE_PATH: String = "res://audio/Velvet Hexagon.mp3"
const BGM_COMBAT_PATH: String = "res://audio/Factory Synapse.mp3"

var _bgm_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _bgm_cache: Dictionary = {}

func _ready() -> void :
    _bgm_player = AudioStreamPlayer.new()
    _bgm_player.bus = &"Master"
    add_child(_bgm_player)

    for i in SFX_POOL_SIZE:
        var sfx_player: AudioStreamPlayer = AudioStreamPlayer.new()
        sfx_player.bus = &"Master"
        add_child(sfx_player)
        _sfx_players.append(sfx_player)

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

func _get_available_sfx_player() -> AudioStreamPlayer:
    for player in _sfx_players:
        if not player.playing:
            return player
    return _sfx_players[0]

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
    var file: FileAccess = FileAccess.open(path, FileAccess.READ)
    if file == null:
        push_warning("BGM file not found: %s" % path)
        return null

    var data: PackedByteArray = file.get_buffer(file.get_length())
    var stream: AudioStreamMP3 = AudioStreamMP3.new()
    stream.data = data
    stream.loop = true
    return stream
