extends CharacterBody2D

# ======================================================
# --- CONSTANTS ---
# ======================================================
const SPEED = 200.0
const JUMP_VELOCITY = -380.0
const GROUND_ACCEL = 2000.0
const AIR_ACCEL = 700.0
const TURN_ACCEL = 2600.0
const FRICTION = 4000.0
const CROUCH_SPEED_MULTIPLIER = 0.35

const COYOTE_TIME = 0.20
const WALL_COYOTE_TIME = 0.35
const JUMP_BUFFER_TIME = 0.12
const JUMP_CUT_MULTIPLIER = 0.5

const FAST_FALL_MULTIPLIER = 1.5
const GLIDE_GRAVITY_MULTIPLIER = 0.5
const FAST_FALL_DURATION = 0.85

const APEX_THRESHOLD = 40.0
const APEX_ACCEL_MULTIPLIER = 2.2
const APEX_GRAVITY_MULTIPLIER = 0.6

# ======================================================
# --- ENUMS & STATES ---
# ======================================================
enum PlayerState { IDLE, RUN, JUMP, FALL, GLIDE, CROUCH, SWING, WALL_CLING }
var state = PlayerState.IDLE

# ======================================================
# --- VARIABLES ---
# ======================================================
var coyote_timer = 0.0
var jump_buffer_timer = 0.0
var fall_timer = 0.0
var was_on_floor = false
var facing_right: bool = true
var camera_normal_position := Vector2.ZERO
var camera_swing_offset := Vector2(8, -5)
var visuals_normal_position: Vector2
var wall_coyote_timer = 0.0
var last_wall_dir = 0
var just_jumped = false
var jump_cooldown = 0.0
var last_fall_speed := 0.0

# Crouch / Fall-through
var crouch_timer := 0.0
var fall_through_timer := 0.0
var CROUCH_DISABLE_TIME := 0.35
var FALL_THROUGH_DURATION := 0.1

# Wall cling
var is_wall_clinging: bool = false
var wall_dir: int = 0
var wall_cling_grace_timer: float = 0.0
var was_wall_clinging = false

# ======================================================
# --- EXPORT VARIABLES ---
# ======================================================
@export var wall_cling_slide_speed: float = 80.0
@export var wall_cling_left_offset: Vector2 = Vector2(7, 0)
@export var wall_cling_right_offset: Vector2 = Vector2(-11, 0)
@export var wall_cling_grace_time: float = 0.13
@export var wall_jump_horizontal_speed: float = 340.0
@export var wall_jump_vertical_speed: float = -340.0

# ======================================================
# --- NODE REFERENCES ---
# ======================================================
@onready var visuals: Node2D = $Visuals
@onready var animated_sprite_2d: AnimatedSprite2D = $Visuals/AnimatedSprite2D
@onready var jump_sound: AudioStreamPlayer2D = $JumpSound
@onready var land_sound: AudioStreamPlayer2D = $LandSound
@onready var run_sound: AudioStreamPlayer2D = $RunSound
@onready var run_sound_timer: Timer = $RunSoundTimer
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var collision_shape = $CollisionShape2D.shape
@onready var swing: Node = $SwingComponent
@onready var grab_point: Marker2D = $Visuals/GrabPoint
@onready var camera: Camera2D = $Camera2D

# ======================================================
# --- READY FUNCTION ---
# ======================================================
func _ready():
	swing.grab_point = grab_point
	camera_normal_position = camera.position
	visuals_normal_position = visuals.position

# ======================================================
# --- ANIMATION HELPERS ---
# ======================================================
func play_anim(anim_name):
	if animated_sprite_2d.animation != anim_name:
		animated_sprite_2d.play(anim_name)

func change_state(new_state):
	if state == new_state:
		return
	state = new_state
	match state:
		PlayerState.IDLE: play_anim("idle")
		PlayerState.RUN: play_anim("run")
		PlayerState.JUMP: play_anim("jump")
		PlayerState.FALL: play_anim("fall")
		PlayerState.GLIDE: play_anim("glide")
		PlayerState.CROUCH: play_anim("crouch")
		PlayerState.SWING: play_anim("swing")
		PlayerState.WALL_CLING: play_anim("wall_cling")

# ======================================================
# --- WALL CLING CHECK ---
# ======================================================
func check_wall_cling(input_dir: float, delta: float) -> void:
	var detected_wall_dir = 0
	var can_cling = false

	if not is_on_floor() and not swing.is_swinging and velocity.y >= 0 and is_on_wall():
		var wall_normal = get_wall_normal()
		if wall_normal.x > 0:
			detected_wall_dir = -1
		elif wall_normal.x < 0:
			detected_wall_dir = 1

		if detected_wall_dir != 0 and input_dir == detected_wall_dir:
			can_cling = true

	is_wall_clinging = can_cling
	wall_dir = detected_wall_dir if can_cling else 0

	if can_cling:
		wall_coyote_timer = WALL_COYOTE_TIME
		last_wall_dir = wall_dir
	else:
		wall_coyote_timer = max(wall_coyote_timer - delta, 0.0)

# ======================================================
# --- PLAYER JUMP FUNCTION ---
# ======================================================
func player_jump():
	jump_cooldown = 0.25
	just_jumped = true

	if swing.is_swinging:
		# Swing jump
		swing.release_swing()
		var launch_speed = 500
		var launch_direction = Vector2(-sin(swing.swing_angle), cos(swing.swing_angle))
		launch_direction.y = JUMP_VELOCITY / launch_speed
		launch_direction = launch_direction.normalized()
		velocity = launch_direction * launch_speed
		jump_sound.pitch_scale = randf_range(1, 1.5)
		jump_sound.play()

	elif wall_coyote_timer > 0.0:
		# Wall jump
		var jump_dir = last_wall_dir
		velocity.x = -jump_dir * wall_jump_horizontal_speed
		velocity.y = wall_jump_vertical_speed
		wall_coyote_timer = 0.0
		is_wall_clinging = false
		wall_dir = 0
		jump_sound.pitch_scale = randf_range(1, 1.5)
		jump_sound.play()

	elif is_on_floor() or coyote_timer > 0.0:
		var platform_vel := Vector2.ZERO
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			var collider = collision.get_collider()
			if collider and collider.is_in_group("moving_platform"):
				platform_vel = collider.platform_velocity
				break
		velocity.y = JUMP_VELOCITY
		if platform_vel.y > 0:
			velocity.y -= platform_vel.y * 0.5
		coyote_timer = 0
		jump_sound.pitch_scale = randf_range(1, 1.5)
		jump_sound.play()

# ======================================================
# --- GRAB/SNAP FUNCTION ---
# ======================================================
func snap_to_grab(pivot_position: Vector2):
	var offset = grab_point.global_position - global_position
	global_position = pivot_position - offset

# ======================================================
# --- PHYSICS PROCESS ---
# ======================================================
# --- Main Physics Loop ---
func _physics_process(delta: float) -> void:
	# --- Get Horizontal Input ---
	var direction := Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var is_crouching := false
	
	jump_cooldown = max(jump_cooldown - delta, 0.0)
	
	if velocity.y > last_fall_speed:
		last_fall_speed = velocity.y

	if is_on_floor():
		last_fall_speed = 0.0
	
	# --- Facing ---
	if not swing.is_swinging:
		if direction > 0:
			facing_right = true
		elif direction < 0:
			facing_right = false

	# --- Swing Camera Position ---
	var target_camera_pos = camera_normal_position
	if swing.is_swinging:
		var swing_x = camera_swing_offset.x if facing_right else -camera_swing_offset.x
		target_camera_pos = Vector2(swing_x, camera_swing_offset.y)
	camera.position = camera.position.lerp(target_camera_pos, 10.0 * delta)

	# --- Swing Release ---
	if swing.is_swinging and Input.is_action_just_pressed("move_down"):
		swing.release_swing()
	
	# --- Swing Jump ---
	if swing.is_swinging and Input.is_action_just_pressed("jump"):
		player_jump()
	
	# --- If swinging, skip normal movement ---
	if swing.is_swinging:
		visuals.rotation_degrees = 0
		visuals.position = visuals_normal_position
		visuals.scale.y = 1
		visuals.scale.x = 1 if facing_right else -1
		change_state(PlayerState.SWING)
		return

	var on_floor = is_on_floor()

	# --- Landing Sound ---
	var just_landed = on_floor and not was_on_floor
	if just_landed and fall_timer > 0.25:
		land_sound.pitch_scale = randf_range(1, 1.5)
		land_sound.play()

	# --- Gravity ---
	if not on_floor:
		if velocity.y < 0:
			velocity += get_gravity() * delta
			fall_timer = 0
		else:
			fall_timer += delta
			if Input.is_action_pressed("jump") and velocity.y > 100:
				velocity += get_gravity() * GLIDE_GRAVITY_MULTIPLIER * delta
				velocity.y = min(velocity.y, 120)
			else:
				velocity += get_gravity() * FAST_FALL_MULTIPLIER * delta
	else:
		fall_timer = 0

	# --- Jump Buffer ---
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER_TIME

	# --- Variable Jump Height ---
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= JUMP_CUT_MULTIPLIER

	# --- Jump Check (Ground + Wall) ---
	if not swing.is_swinging and jump_buffer_timer > 0 and jump_cooldown <= 0.0:
		if coyote_timer > 0 or wall_coyote_timer > 0:
			player_jump()
			coyote_timer = 0
			wall_coyote_timer = 0
			jump_buffer_timer = 0
			jump_cooldown = 0.25

	# --- Timers ---
	jump_buffer_timer -= delta
	coyote_timer = COYOTE_TIME if on_floor else max(coyote_timer - delta, 0.0)
	wall_coyote_timer = max(wall_coyote_timer - delta, 0)
	
	# --- Apex jump slowing ---
	var apex_factor = 0.0
	if velocity.y < 0 and abs(velocity.y) < APEX_THRESHOLD:
		apex_factor = 1.0 - (abs(velocity.y) / APEX_THRESHOLD)
		velocity += get_gravity() * APEX_GRAVITY_MULTIPLIER * delta

	var accel = GROUND_ACCEL if on_floor else AIR_ACCEL
	if not on_floor:
		accel += AIR_ACCEL * APEX_ACCEL_MULTIPLIER * apex_factor
	if direction != 0 and sign(direction) != sign(velocity.x):
		accel = TURN_ACCEL
		
	# --- Wall cling + jump logic ---
	check_wall_cling(direction, delta)
	
	# Detect leaving wall cling
	if was_wall_clinging and not is_wall_clinging:
		visuals.rotation_degrees = 0
		visuals.position = visuals_normal_position
		visuals.scale = Vector2(1, 1)
	was_wall_clinging = is_wall_clinging

	# Horizontal movement while clinging
	if is_wall_clinging:
		change_state(PlayerState.WALL_CLING)
		velocity.x = wall_dir * 1.0
		if Input.is_action_pressed("move_down"):
			velocity.y = min(velocity.y, wall_cling_slide_speed)
		else:
			velocity.y = min(velocity.y, 0.0)

	# --- CROUCH + FALL-THROUGH ---
	if on_floor and Input.is_action_pressed("move_down"):
		is_crouching = true
		crouch_timer += delta

		if crouch_timer >= CROUCH_DISABLE_TIME and fall_through_timer <= 0.0:
			fall_through_timer = FALL_THROUGH_DURATION
			set_collision_mask_value(5, false)

		velocity.x = move_toward(
			velocity.x,
			direction * SPEED * CROUCH_SPEED_MULTIPLIER,
			GROUND_ACCEL * delta
		)
		change_state(PlayerState.CROUCH)
	else:
		crouch_timer = 0.0

	if fall_through_timer > 0.0:
		fall_through_timer -= delta
		if fall_through_timer <= 0.0:
			set_collision_mask_value(5, true)

	# --- STATE MACHINE (skip if crouching or wall-clinging handled above) ---
	if not is_crouching and not is_wall_clinging:
		var grounded = (on_floor or coyote_timer > 0.2) and not just_jumped
		if grounded:
			if abs(velocity.x) < 5:
				change_state(PlayerState.IDLE)
			else:
				change_state(PlayerState.RUN)
		else:
			if velocity.y < 0:
				change_state(PlayerState.JUMP)
			elif velocity.y > 100 and Input.is_action_pressed("jump"):
				change_state(PlayerState.GLIDE)
			elif velocity.y > 0:
				change_state(PlayerState.FALL)

		if direction != 0:
			velocity.x = move_toward(velocity.x, direction * SPEED, accel * delta)
		else:
			velocity.x = move_toward(velocity.x, 0, FRICTION * delta)

	# --- Flip Sprite / Wall Cling Rotation ---
	if is_wall_clinging:
		if wall_dir == -1:
			visuals.rotation_degrees = -90
			visuals.position = visuals_normal_position + wall_cling_left_offset
			visuals.scale = Vector2(1, 1)
		elif wall_dir == 1:
			visuals.rotation_degrees = 90
			visuals.position = visuals_normal_position + wall_cling_right_offset
			visuals.scale = Vector2(-1, 1)
	else:
		visuals.rotation_degrees = 0
		visuals.position = visuals_normal_position
		visuals.scale.y = 1
		visuals.scale.x = 1.0 if direction > 0 else -1.0 if direction < 0 else visuals.scale.x

	# --- Landing/Running Sounds ---
	was_on_floor = on_floor
	if on_floor and abs(velocity.x) > 0 and not Input.is_action_pressed("move_down"):
		if run_sound_timer.is_stopped():
			run_sound_timer.start()
	else:
		run_sound_timer.stop()

	# --- Apply Movement ---
	move_and_slide()
	just_jumped = false

	# --- Bounce Check ---
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider and collider.is_in_group("bouncy"):
			var normal = collision.get_normal()
			if normal.y < -0.7 and last_fall_speed > 125:
				var strength = clamp(last_fall_speed / 500.0, 0.8, 1.2)
				velocity.y = collider.bounce_force * strength
				if velocity.y > 0:
					velocity.y = 0
				var bounce_input_dir = direction
				velocity.x += bounce_input_dir * collider.directional_boost
				if collider.has_method("play_squash"):
					collider.play_squash()
				break

# ======================================================
# --- RUN SOUND TIMER CALLBACK ---
# ======================================================
func _on_run_sound_timer_timeout() -> void:
	run_sound.pitch_scale = randf_range(1, 1.5)
	run_sound.play()
