class_name EnemyProjectile
extends Node2D

@export var speed: float = 260.0
@export var direction: Vector2 = Vector2.RIGHT
@export var damage: int = 10
@export var hit_radius: float = 5.0
@export var life_time: float = 4.0
@export var tint: Color = Color(1.0, 0.44, 0.34, 1.0)

func _ready() -> void :
    process_mode = Node.PROCESS_MODE_PAUSABLE
    queue_redraw()

func _physics_process(delta: float) -> void :
    if direction.length_squared() <= 0.0001:
        direction = Vector2.RIGHT
    global_position += direction.normalized() * speed * delta
    life_time -= delta
    if life_time <= 0.0:
        queue_free()

func _draw() -> void :
    draw_circle(Vector2.ZERO, hit_radius + 1.4, Color(0.22, 0.08, 0.08, 0.86))
    draw_circle(Vector2.ZERO, hit_radius, tint)
