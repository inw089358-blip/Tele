class_name ExperienceOrb
extends Node2D

@export var xp_value: int = 5
@export var magnet_radius: float = 120.0
@export var magnet_speed: float = 480.0
@export var collect_radius: float = 12.0

var _collected: bool = false

func _ready() -> void :
    process_mode = Node.PROCESS_MODE_PAUSABLE
    queue_redraw()

func setup(value: int) -> void :
    xp_value = max(1, value)

func tick_collect(player_position: Vector2, pickup_radius: float, delta: float) -> bool:
    if _collected:
        return false

    var attract_radius: float = max(magnet_radius, pickup_radius)
    var to_player: Vector2 = player_position - global_position
    var distance_sq: float = to_player.length_squared()
    var collect_dist_sq: float = collect_radius * collect_radius
    if distance_sq <= collect_dist_sq:
        _collected = true
        return true

    var attract_dist_sq: float = attract_radius * attract_radius
    if distance_sq <= attract_dist_sq and distance_sq > 0.0001:
        var distance: float = sqrt(distance_sq)
        var travel: float = min(distance, magnet_speed * delta)
        global_position += to_player / distance * travel

    return false

func is_collected() -> bool:
    return _collected

func _draw() -> void :
    draw_circle(Vector2.ZERO, 7.0, Color(0.08, 0.12, 0.2, 0.95))
    draw_circle(Vector2.ZERO, 5.0, Color(0.33, 0.86, 1.0, 0.95))
    draw_circle(Vector2.ZERO, 2.2, Color(0.9, 1.0, 1.0, 0.9))
