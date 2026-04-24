extends Node2D

var _sprite: Sprite2D
var _death_frames: Array[int] = []
var _death_anim_fps: float = 10.0
var _death_hold_seconds: float = 0.1
var _elapsed: float = 0.0
var _frame_index: int = 0
var _playback_finished: bool = false

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_PAUSABLE

func setup_from_enemy(
    texture: Texture2D,
    hframes: int,
    vframes: int,
    sprite_scale: Vector2,
    flip_h: bool,
    death_frames: Array,
    death_anim_fps: float,
    death_hold_seconds: float,
    z_index_value: int
) -> void:
    _sprite = Sprite2D.new()
    _sprite.texture = texture
    _sprite.centered = true
    _sprite.hframes = max(1, hframes)
    _sprite.vframes = max(1, vframes)
    _sprite.scale = sprite_scale
    _sprite.flip_h = flip_h
    _sprite.z_index = z_index_value
    add_child(_sprite)

    _death_frames.clear()
    for frame_value: Variant in death_frames:
        _death_frames.append(int(frame_value))
    if _death_frames.is_empty():
        queue_free()
        return

    _death_anim_fps = max(0.01, death_anim_fps)
    _death_hold_seconds = max(0.0, death_hold_seconds)
    _elapsed = 0.0
    _frame_index = 0
    _playback_finished = false
    _apply_frame()

func _process(delta: float) -> void:
    if _sprite == null:
        queue_free()
        return
    if _death_frames.is_empty():
        queue_free()
        return

    if _playback_finished:
        _elapsed += delta
        if _elapsed >= _death_hold_seconds:
            queue_free()
        return

    var frame_step: float = 1.0 / _death_anim_fps
    _elapsed += delta
    while _elapsed >= frame_step and not _playback_finished:
        _elapsed -= frame_step
        if _frame_index < _death_frames.size() - 1:
            _frame_index += 1
            _apply_frame()
        else:
            _playback_finished = true
            _elapsed = 0.0
            break

func _apply_frame() -> void:
    if _sprite == null:
        return
    if _death_frames.is_empty():
        return
    var safe_index: int = clampi(_frame_index, 0, _death_frames.size() - 1)
    _sprite.frame = _death_frames[safe_index]
