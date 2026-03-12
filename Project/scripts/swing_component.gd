extends Node

var player

var is_swinging = false
var pivot_point = Vector2.ZERO
var swing_radius = 0.0
var swing_angle = 0.0
var swing_speed = 4
var swing_direction = 1
var min_angle = -1.2
var max_angle = 1.2
var base_angle = PI/2
var start_fraction = 0.25
var swing_radius_offset = 0  # pixels closer to pivot


func _ready() -> void:
	player = get_parent()

func _physics_process(delta):
	

	if !is_swinging:
		return

	swing_angle += swing_speed * delta * swing_direction

	if swing_angle > max_angle:
		swing_angle = max_angle
		swing_direction *= -1

	if swing_angle < min_angle:
		swing_angle = min_angle
		swing_direction *= -1

	var x = pivot_point.x + cos(base_angle + swing_angle) * swing_radius
	var y = pivot_point.y + sin(base_angle + swing_angle) * swing_radius

	player.global_position = Vector2(x, y)
	 

func start_swing(pivot_position: Vector2):
	is_swinging = true
	pivot_point = pivot_position
	swing_radius = max(30, player.global_position.distance_to(pivot_point) - swing_radius_offset)

	# Determine swing direction from facing
	if player.facing_right:
		swing_direction = -1
		swing_angle = lerp(max_angle, min_angle, 0.25)
	else:
		swing_direction = 1
		swing_angle = lerp(min_angle, max_angle, 0.25)

	player.velocity = Vector2.ZERO
	
func release_swing():

	is_swinging = false

	var launch_speed = 450

	var launch_direction = Vector2(
		-sin(swing_angle),
		cos(swing_angle)
	)

	# add upward boost
	launch_direction.y -= 0.4

	launch_direction = launch_direction.normalized()

	player.velocity = launch_direction * launch_speed
