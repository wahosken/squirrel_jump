extends AnimatableBody2D

func set_active(active: bool):
	visible = active
	set_physics_process(active)

	for c in get_children():
		if c is CollisionShape2D:
			c.disabled = not active
