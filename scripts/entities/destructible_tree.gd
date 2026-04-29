class_name DestructibleTree
extends Enemy

signal tree_destroyed(pos: Vector2)

func _init() -> void:
    # Set base stats for the tree
    max_hp = 12
    move_speed = 0.0
    body_radius = 12.0
    xp_drop_amount = 0 # Trees don't give XP directly, they drop items
    enemy_type = EnemyType.MELEE # Use MELEE type for targeting compatibility
    is_elite = false

func _ready() -> void:
    # Override _ready to skip base enemy setup if needed, or just set current_hp
    current_hp = max_hp
    _is_dead = false
    process_mode = Node.PROCESS_MODE_PAUSABLE
    queue_redraw()

func _physics_process(_delta: float) -> void:
    # Trees don't move
    velocity = Vector2.ZERO

func take_damage(amount: int) -> int:
    if _is_dead:
        return 0
    
    var actual_damage: int = amount
    current_hp -= actual_damage
    
    # Simple hit feedback
    var tween = create_tween()
    tween.tween_property(self, "modulate", Color.RED, 0.05)
    tween.tween_property(self, "modulate", Color.WHITE, 0.05)
    
    if current_hp <= 0:
        _die()
    
    return actual_damage

func _die() -> void:
    if _is_dead:
        return
    _is_dead = true
    tree_destroyed.emit(global_position)
    died.emit(self)
    queue_free()

func _draw() -> void:
    if _is_dead:
        return
    # Simple Tree Visuals (Trunk and Leaves)
    # Trunk
    draw_rect(Rect2(-3, 0, 6, 12), Color(0.4, 0.25, 0.1), true)
    # Leaves
    draw_circle(Vector2(0, -4), 10.0, Color(0.1, 0.6, 0.2, 0.9))
    draw_circle(Vector2(-5, -8), 7.0, Color(0.15, 0.7, 0.25, 0.9))
    draw_circle(Vector2(5, -8), 7.0, Color(0.15, 0.7, 0.25, 0.9))
    draw_circle(Vector2(0, -14), 8.0, Color(0.2, 0.8, 0.3, 0.9))

# Targetable check for weapons
func is_combat_active() -> bool:
    return not _is_dead
