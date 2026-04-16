class_name Projectile
extends Area2D

@export var speed: float = 520.0
@export var direction: Vector2 = Vector2.RIGHT
@export var damage: int = 10
@export var hit_radius: float = 4.0
@export var life_time: float = 1.6

var _target: Node2D

func _ready() -> void :
    process_mode = Node.PROCESS_MODE_PAUSABLE
    queue_redraw()

func set_target(target: Node2D) -> void :
    _target = target

func _physics_process(delta: float) -> void :
    if _target != null and is_instance_valid(_target):
        var to_target: Vector2 = _target.global_position - global_position
        if to_target.length_squared() > 0.0001:
            direction = to_target.normalized()
    global_position += direction.normalized() * speed * delta
    life_time -= delta
    if life_time <= 0.0:
        queue_free()

func _draw() -> void :
    draw_circle(Vector2.ZERO, hit_radius + 1.5, Color(0.2, 0.42, 0.54, 0.85))
    draw_circle(Vector2.ZERO, hit_radius, Color(0.6, 0.98, 1.0, 1.0))
