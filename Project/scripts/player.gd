extends CharacterBody2D


const SPEED = 200.0
const JUMP_VELOCITY = -350.0
var minimum_fall_duration: float = 0.85
var current_fall_time: float = 0.0

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		current_fall_time += delta
		if current_fall_time >= minimum_fall_duration and animated_sprite_2d.animation != "fall":
			animated_sprite_2d.play("fall")
			
	else:
		current_fall_time = 0.0

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Gets input direction: -1, 0, 1
	var direction := Input.get_axis("move_left", "move_right")
	
	# Flip the Sprite
	if direction > 0:
		animated_sprite_2d.flip_h = false
	elif direction < 0:
		animated_sprite_2d.flip_h = true
		
	# Play animations
	if is_on_floor():
		if direction == 0:
			animated_sprite_2d.play("default")
		else:
			animated_sprite_2d.play("run")
	else:
		if velocity.y < 0:
			animated_sprite_2d.play("jump")
		else:
			if current_fall_time >= minimum_fall_duration:
				animated_sprite_2d.play("fall")
	
	# Apply movement
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
