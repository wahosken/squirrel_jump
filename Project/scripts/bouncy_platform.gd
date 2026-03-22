extends AnimatableBody2D

# --- Activation System ---
func set_active(active: bool):
	set_physics_process(active)

	for c in get_children():
		if c is CollisionShape2D or c is CollisionPolygon2D:
			c.disabled = not active

# --- Bounce Settings ---
@export var bounce_force: float = -550.0
@export var directional_boost: float = 120.0
@export var min_fall_speed: float = 50.0

# --- Juice ---
@export var squash_amount: float = 0.2
@export var squash_time: float = 0.08

@onready var visuals: Sprite2D = $Sprite2D

var tween: Tween

func play_squash():
	if tween:
		tween.kill()

	tween = create_tween()

	# Squash
	tween.tween_property(visuals, "scale", Vector2(1.2, 0.8), squash_time)

	# Return to normal
	tween.tween_property(visuals, "scale", Vector2(1, 1), squash_time)
