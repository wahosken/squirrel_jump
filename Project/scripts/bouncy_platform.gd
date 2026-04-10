extends AnimatableBody2D

func set_active(active: bool):
	visible = active
	set_physics_process(active)

	if active:
		reset()
	else:
		_disable_collision()

# --- Bounce Settings ---
@export var bounce_force: float = -550.0
@export var directional_boost: float = 120.0
@export var min_fall_speed: float = 50.0

# --- Juice ---
@export var squash_amount: float = 0.2
@export var squash_time: float = 0.08

@onready var visuals: Sprite2D = $Sprite2D

var original_position: Vector2
var original_collision_layer := 0
var original_collision_mask := 0

var tween: Tween

func _ready():
	original_position = position
	original_collision_layer = collision_layer
	original_collision_mask = collision_mask

func play_squash():
	if tween:
		tween.kill()

	tween = create_tween()

	# Squash
	tween.tween_property(visuals, "scale", Vector2(1.2, 0.8), squash_time)

	# Return to normal
	tween.tween_property(visuals, "scale", Vector2(1, 1), squash_time)

func reset():
	# --- POSITION RESET ---
	position = original_position

	# --- VISUAL RESET ---
	visuals.scale = Vector2.ONE

	# --- STOP TWEEN ---
	if tween:
		tween.kill()
		tween = null

	# --- HARD COLLISION RESET ---
	collision_layer = 0
	collision_mask = 0

	await get_tree().process_frame

	collision_layer = original_collision_layer
	collision_mask = original_collision_mask

	# 🔑 IMPORTANT: re-enable shapes
	for c in get_children():
		if c is CollisionShape2D or c is CollisionPolygon2D:
			c.disabled = false
			
func _disable_collision():
	collision_layer = 0
	collision_mask = 0

	for c in get_children():
		if c is CollisionShape2D or c is CollisionPolygon2D:
			c.disabled = true
