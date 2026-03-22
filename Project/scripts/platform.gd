extends AnimatableBody2D

var last_position: Vector2
var platform_velocity: Vector2

func _physics_process(delta):
	platform_velocity = (global_position - last_position) / delta
	last_position = global_position

func set_active(active: bool):
	visible = active
	set_physics_process(active)

	for c in get_children():
		if c is CollisionShape2D:
			c.disabled = not active
