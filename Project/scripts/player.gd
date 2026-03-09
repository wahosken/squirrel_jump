extends CharacterBody2D

const SPEED = 200.0
const JUMP_VELOCITY = -380.0
const GROUND_ACCEL = 2000.0
const AIR_ACCEL = 700.0
const TURN_ACCEL = 2200.0
const FRICTION = 4000.0

const COYOTE_TIME = 0.12
var coyote_timer = 0.0

const JUMP_BUFFER_TIME = 0.12
var jump_buffer_timer = 0.0

const JUMP_CUT_MULTIPLIER = 0.5

const FAST_FALL_MULTIPLIER = 1.5
const GLIDE_GRAVITY_MULTIPLIER = 0.3
const FAST_FALL_DURATION = 0.85
var fall_timer = 0.0



enum PlayerState {
	IDLE,
	RUN,
	JUMP,
	FALL,
	GLIDE
}

var state = PlayerState.IDLE

@onready var animated_sprite_2d: AnimatedSprite2D = $Visuals/AnimatedSprite2D

@onready var visuals: Node2D = $Visuals

func play_anim(anim_name):
	if animated_sprite_2d.animation != anim_name:
		animated_sprite_2d.play(anim_name)

func change_state(new_state):
	if state == new_state:
		return
		
	state = new_state
	
	match state:
		PlayerState.IDLE:
			play_anim("idle")
			
		PlayerState.RUN:
			play_anim("run")
			
		PlayerState.JUMP:
			play_anim("jump")
			
		PlayerState.FALL:
			play_anim("fall")
			
		PlayerState.GLIDE:
			play_anim("glide")

func _physics_process(delta: float) -> void:
	# Add the gravity.
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
		
	if is_on_floor():
		coyote_timer = COYOTE_TIME
	else:
		coyote_timer -= delta
		
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER_TIME
		
	jump_buffer_timer -= delta
	
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= JUMP_CUT_MULTIPLIER

	# Handle jump.
	if jump_buffer_timer > 0 and coyote_timer > 0:
		velocity.y = JUMP_VELOCITY
		coyote_timer = 0
		jump_buffer_timer = 0
		

	# Gets input direction: -1, 0, 1
	var direction := Input.get_axis("move_left", "move_right")
	
	var accel = GROUND_ACCEL if is_on_floor() else AIR_ACCEL

	# Detect direction change
	if direction != 0 and sign(direction) != sign(velocity.x):
		accel = TURN_ACCEL

	if direction != 0:
		velocity.x = move_toward(velocity.x, direction * SPEED, accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)

	# Flip the Sprite
	if direction > 0:
		visuals.scale.x = 1
	elif direction < 0:
		visuals.scale.x = -1
		
	# Play animations
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
		elif is_on_floor() and velocity.y > 0:
			change_state(PlayerState.FALL)

	move_and_slide()
