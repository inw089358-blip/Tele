class_name ConsumableDrop
extends Node2D

@export var heal_amount: int = 3
@export var magnet_radius: float = 140.0
@export var magnet_speed: float = 520.0
@export var collect_radius: float = 14.0

var _collected: bool = false

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_PAUSABLE
    queue_redraw()

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

func _draw() -> void:
    # Outer Glow
    draw_circle(Vector2.ZERO, 9.0, Color(1.0, 0.4, 0.6, 0.3))
    # Main Body (Pink/Red)
    draw_circle(Vector2.ZERO, 7.0, Color(0.9, 0.1, 0.3, 0.95))
    # White Cross
    var cross_size: float = 4.0
    var cross_width: float = 2.0
    draw_line(Vector2(-cross_size, 0), Vector2(cross_size, 0), Color.WHITE, cross_width)
    draw_line(Vector2(0, -cross_size), Vector2(0, cross_size), Color.WHITE, cross_width)
