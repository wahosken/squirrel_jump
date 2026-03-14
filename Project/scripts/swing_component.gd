extends Node

var player
var grab_point: Marker2D

var is_swinging = false
var pivot_point = Vector2.ZERO
var swing_radius = 0.0
var swing_angle = 0.0
var swing_speed = 5.0
var swing_cooldown = 0.1
var cooldown_timer = 0.0

var swing_direction = 1
var min_angle = -1.2
var max_angle = 1.2
var base_angle = PI/2
var base_angle_right = PI / 2
var base_angle_left  = -PI / 2
var pivot_offset_left := Vector2(0, 0)

var start_fraction = 0.25
var swing_radius_offset = 0.0


func _ready() -> void:
	player = get_parent()

func _physics_process(delta):

	# Swing movement
	if is_swinging:
		

		swing_angle += swing_speed * delta * swing_direction

		if swing_angle > max_angle:
			swing_angle = max_angle
			swing_direction *= -1
		elif swing_angle < min_angle:
			swing_angle = min_angle
			swing_direction *= -1

		var x = pivot_point.x + cos(base_angle + swing_angle) * swing_radius
		var y = pivot_point.y + sin(base_angle + swing_angle) * swing_radius

		# Move player so grab point stays on the arc
		var grab_target = Vector2(x, y)
		var offset = grab_point.global_position - player.global_position
		


		player.global_position = grab_target - offset
		
		var angle = base_angle + swing_angle + PI
		player.rotation = angle


	# Countdown cooldown
	if cooldown_timer > 0:
		cooldown_timer -= delta
		if cooldown_timer < 0:
			cooldown_timer = 0



func start_swing(pivot_position: Vector2):

	if is_swinging or cooldown_timer > 0:
		return
		
	player.snap_to_grab(pivot_position)

	is_swinging = true

	if player.facing_right:
		base_angle = base_angle_right
		pivot_point = pivot_position
		swing_direction = -1
		swing_angle = lerp(max_angle, min_angle, start_fraction)
	else:
		base_angle = base_angle_left
		pivot_point = pivot_position + pivot_offset_left
		swing_direction = 1
		swing_angle = lerp(min_angle, max_angle, start_fraction)

	# Calculate radius using grab point
	var grab_pos = grab_point.global_position
	swing_radius = max(0, grab_pos.distance_to(pivot_point) - swing_radius_offset)

	player.velocity = Vector2.ZERO





func release_swing():
	
	player.rotation = 0.0

	is_swinging = false

	# Start cooldown
	cooldown_timer = swing_cooldown

	var launch_speed = 450

	var launch_direction = Vector2(
		-sin(swing_angle),
		cos(swing_angle)
	)

	# upward boost
	launch_direction.y -= 0.4
	launch_direction = launch_direction.normalized()

	player.velocity = launch_direction * launch_speed
