extends AnimatableBody2D

# --- Activation System ---
func set_active(active: bool):
	set_physics_process(active)

	for c in get_children():
		if c is CollisionShape2D:
			c.disabled = not active

# --- Bounce Settings ---
@export var bounce_force: float = -550.0
@export var directional_boost: float = 120.0
@export var min_fall_speed: float = 0.0

# --- Juice ---
@export var squash_amount: float = 0.2
@export var squash_time: float = 0.08

@onready var visuals: Sprite2D = $Sprite2D

var tween: Tween

func _on_area_2d_body_entered(body):
	if not body.is_in_group("player"):
		return
	
	# Only trigger if falling
	if body.velocity.y < min_fall_speed:
		return

	# --- APPLY BOUNCE ---
	body.velocity.y = bounce_force

	# Optional horizontal influence
	var input_dir = Input.get_axis("move_left", "move_right")
	body.velocity.x += input_dir * directional_boost
	

	# --- JUICE (squash + stretch) ---
	play_squash()

func play_squash():
	if tween:
		tween.kill()

	tween = create_tween()

	# Squash
	tween.tween_property(visuals, "scale", Vector2(1.2, 0.8), squash_time)

	# Return to normal
	tween.tween_property(visuals, "scale", Vector2(1, 1), squash_time)
