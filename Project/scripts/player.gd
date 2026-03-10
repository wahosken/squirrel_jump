extends CharacterBody2D

# --- Constants ---
const SPEED = 200.0
const JUMP_VELOCITY = -380.0
const GROUND_ACCEL = 2000.0
const AIR_ACCEL = 700.0
const TURN_ACCEL = 2600.0
const FRICTION = 4000.0
const CROUCH_SPEED_MULTIPLIER = 0.35

const COYOTE_TIME = 0.12
const JUMP_BUFFER_TIME = 0.12
const JUMP_CUT_MULTIPLIER = 0.5

const FAST_FALL_MULTIPLIER = 1.5
const GLIDE_GRAVITY_MULTIPLIER = 0.3
const FAST_FALL_DURATION = 0.85

# --- Variables ---
var coyote_timer = 0.0
var jump_buffer_timer = 0.0
var fall_timer = 0.0
var was_on_floor = false

enum PlayerState {
	IDLE,
	RUN,
	JUMP,
	FALL,
	GLIDE,
	CROUCH
}
var state = PlayerState.IDLE

# --- Nodes ---
@onready var visuals: Node2D = $Visuals
@onready var animated_sprite_2d: AnimatedSprite2D = $Visuals/AnimatedSprite2D
@onready var jump_sound: AudioStreamPlayer2D = $JumpSound
@onready var land_sound: AudioStreamPlayer2D = $LandSound
@onready var run_sound: AudioStreamPlayer2D = $RunSound
@onready var run_sound_timer: Timer = $RunSoundTimer

# --- Animation Helpers ---
func play_anim(anim_name):
	if animated_sprite_2d.animation != anim_name:
		animated_sprite_2d.play(anim_name)

func change_state(new_state):
	if state == new_state:
		return
	state = new_state
	match state:
		PlayerState.IDLE:  play_anim("idle")
		PlayerState.RUN:   play_anim("run")
		PlayerState.JUMP:  play_anim("jump")
		PlayerState.FALL:  play_anim("fall")
		PlayerState.GLIDE: play_anim("glide")
		PlayerState.CROUCH: play_anim("crouch")

# --- Main Physics Loop ---
func _physics_process(delta: float) -> void:

	# --- Landing Sound ---
	var just_landed = is_on_floor() and not was_on_floor
	if just_landed and fall_timer > 0.25:
		land_sound.pitch_scale = randf_range(1, 1.5)
		land_sound.play()

	# --- Gravity ---
	if not is_on_floor():
		if velocity.y < 0:
			velocity += get_gravity() * delta
			fall_timer = 0
		else:
			fall_timer += delta
			if Input.is_action_pressed("jump"):
				velocity += get_gravity() * GLIDE_GRAVITY_MULTIPLIER * delta
			else:
				velocity += get_gravity() * FAST_FALL_MULTIPLIER * delta
	else:
		fall_timer = 0

	# --- Coyote Timer ---
	coyote_timer = COYOTE_TIME if is_on_floor() else coyote_timer - delta

	# --- Jump Buffer ---
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER_TIME
	jump_buffer_timer -= delta

	# --- Variable Jump Height ---
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= JUMP_CUT_MULTIPLIER

	# --- Handle Jump ---
	if jump_buffer_timer > 0 and coyote_timer > 0:
		velocity.y = JUMP_VELOCITY
		coyote_timer = 0
		jump_buffer_timer = 0
		jump_sound.pitch_scale = randf_range(1, 1.5)
		jump_sound.play()

	# --- Get Horizontal Input ---
	var direction := Input.get_axis("move_left", "move_right")
	var accel = GROUND_ACCEL if is_on_floor() else AIR_ACCEL
	if direction != 0 and sign(direction) != sign(velocity.x):
		accel = TURN_ACCEL

	# --- Crouch (Priority over movement) ---
	if is_on_floor() and Input.is_action_pressed("move_down"):
		change_state(PlayerState.CROUCH)
		velocity.x = move_toward(
			velocity.x,
			direction * SPEED * CROUCH_SPEED_MULTIPLIER,
			GROUND_ACCEL * delta
		)
	else:
		# --- State Machine ---
		if is_on_floor():
			if direction == 0:
				change_state(PlayerState.IDLE)
			else:
				change_state(PlayerState.RUN)
		else:
			if velocity.y < 0:
				change_state(PlayerState.JUMP)
			elif Input.is_action_pressed("jump"):
				change_state(PlayerState.GLIDE)
			elif velocity.y > 0:
				change_state(PlayerState.FALL)
				
		# Horizontal Movement
		if direction != 0:
			velocity.x = move_toward(velocity.x, direction * SPEED, accel * delta)
		else:
			velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
			
				
	# --- Flip Sprite ---
	if direction > 0:
		visuals.scale.x = 1
	elif direction < 0:
		visuals.scale.x = -1

	# --- Landing/Running Sounds ---
	was_on_floor = is_on_floor()
	if is_on_floor() and abs(velocity.x) > 180:
		if run_sound_timer.is_stopped():
			run_sound_timer.start()
	else:
		run_sound_timer.stop()

	# --- Apply Movement ---
	move_and_slide()

# --- Run Sound Timer Callback ---
func _on_run_sound_timer_timeout() -> void:
	run_sound.pitch_scale = randf_range(1, 1.5)
	run_sound.play()
