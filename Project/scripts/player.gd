extends CharacterBody2D
class_name Player

# ======================================================
# --- CONSTANTS ---
# ======================================================
const SPEED = 200.0
const JUMP_VELOCITY = -380.0
const GROUND_ACCEL = 2000.0
const AIR_ACCEL = 600.0
const TURN_ACCEL = 2600.0
const FRICTION = 4000.0
const CROUCH_SPEED_MULTIPLIER = 0.35

const COYOTE_TIME = 0.20
const WALL_COYOTE_TIME = 0.35
const JUMP_BUFFER_TIME = 0.12
const JUMP_CUT_MULTIPLIER = 0.5

const FAST_FALL_MULTIPLIER = 1.25
const GLIDE_GRAVITY_MULTIPLIER = 0.5
const FAST_FALL_DURATION = 0.85

const APEX_THRESHOLD = 40.0
const APEX_ACCEL_MULTIPLIER = 2.2
const APEX_GRAVITY_MULTIPLIER = 0.6

const BIG_FALL = 1800
const MEDIUM_FALL = 1200
const SHORT_FALL = 800

const LEAF_LAYER = 5

const LEAF_SHAKE_SPEED = 1000.0
const LEAF_BREAK_SPEED = 1600.0
const FAST_FALL_THROUGH_DURATION := 0.2

# ======================================================
# --- ENUMS & STATES ---
# ======================================================
enum PlayerState { IDLE, RUN, JUMP, FALL, GLIDE, GLIDE_LOW, CROUCH, SWING, WALL_CLING }
var state = PlayerState.IDLE

# ======================================================
# --- VARIABLES ---
# ======================================================
var coyote_timer = 0.0
var jump_buffer_timer = 0.0
var fall_timer = 0.0
var was_on_floor = false
var facing_right: bool = true
var visuals_normal_position: Vector2
var wall_coyote_timer = 0.0
var last_wall_dir = 0
var just_jumped = false
var jump_cooldown = 0.0
var last_fall_speed := 0.0

var fall_save_triggered := false
var physics_locked := false
var resumed_in_air: bool = false

# Crouch / Fall-through
var crouch_timer := 0.0
var fall_through_timer := 0.0
var CROUCH_DISABLE_TIME := 0.5
var FALL_THROUGH_DURATION := 0.2

# Wall cling
var is_wall_clinging: bool = false
var wall_dir: int = 0
var wall_cling_grace_timer: float = 0.0
var was_wall_clinging = false


# Glide / Stamina
var glide_timer: float = 0.0
var max_glide_time: float = 4   # max seconds of glide
var can_glide: bool = true
var is_gliding: bool = false

# Fall Through High Speed Fall
var fall_state = "none"  # "none", "shake", "break"
var fast_fall_through_timer := 0.0

# Menu Interact
var input_enabled := true
var movement_locked := false

# ======================================================
# --- EXPORT VARIABLES ---
# ======================================================
@export var wall_cling_slide_speed: float = 80.0
@export var wall_cling_left_offset: Vector2 = Vector2(14, -7)
@export var wall_cling_right_offset: Vector2 = Vector2(-13, -7)
@export var wall_cling_grace_time: float = 0.13
@export var wall_jump_horizontal_speed: float = 340.0
@export var wall_jump_vertical_speed: float = -340.0


# ======================================================
# --- NODE REFERENCES ---
# ======================================================
@onready var visuals: Node2D = $Visuals
@onready var squirrel_sprite: Sprite2D = $Visuals/SquirrelSprite
@onready var apparel_sprite: Sprite2D = $Visuals/ApparelSprite
@onready var jump_sound: AudioStreamPlayer2D = $JumpSound
@onready var land_sound: AudioStreamPlayer2D = $LandSound
@onready var run_sound: AudioStreamPlayer2D = $RunSound
@onready var run_sound_timer: Timer = $RunSoundTimer
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var collision_shape = $CollisionShape2D.shape
@onready var swing: Node = $SwingComponent
@onready var grab_point: Marker2D = $Visuals/GrabPoint
@onready var camera_controller: Node = $PlayerCameraController

# ======================================================
# --- COSMETICS / APPEARANCE ---
# ======================================================
@onready var animator: SquirrelAnimator = $Visuals/SquirrelAnimator

@export var acorn_cap_texture: Texture2D
@export var super_squirrel_texture: Texture2D
@export var baseball_cap_texture: Texture2D

# ======================================================
# --- READY FUNCTION ---
# ======================================================
func _ready():
	add_to_group("player")

	var spawned_from_override := SaveManager.use_scene_spawn

	if SaveManager.use_scene_spawn:
		global_position = SaveManager.scene_spawn_override
		SaveManager.use_scene_spawn = false

	else:

		if SaveManager.save_data.exit_spawn_id != "":

			var spawn = find_exit_spawn(
				SaveManager.save_data.exit_spawn_id
			)

			if spawn:

				global_position = spawn.global_position

				SaveManager.clear_exit_spawn()

			else:
				global_position = SaveManager.dict_to_vector2(
					SaveManager.save_data.player_position
				)

		else:

			global_position = SaveManager.dict_to_vector2(
				SaveManager.save_data.player_position
			)

	resumed_in_air = !SaveManager.save_data.player_grounded

	if spawned_from_override:

		physics_locked = false
		set_input_enabled(true)

	else:

		physics_locked = true
		set_input_enabled(false)

		if not ResumeManager.resume_finished.is_connected(_on_resume_finished):
			ResumeManager.resume_finished.connect(_on_resume_finished)
	
	swing.grab_point = grab_point
	visuals_normal_position = visuals.position

	if not GameState.cosmetic_equipped.is_connected(_on_cosmetic_equipped):
		GameState.cosmetic_equipped.connect(_on_cosmetic_equipped)

	if not GameState.squirrel_color_equipped.is_connected(_on_squirrel_color_equipped):
		GameState.squirrel_color_equipped.connect(_on_squirrel_color_equipped)

	_apply_equipped_appearance()


func _on_resume_finished():
	physics_locked = false
	set_input_enabled(true)


func _on_cosmetic_equipped(_item_id: String) -> void:
	_apply_equipped_appearance()

func _on_squirrel_color_equipped(_color_id: String) -> void:
	_apply_equipped_appearance()


func set_apparel(apparel_id: String) -> void:

	if apparel_id == "" or apparel_id == "none":
		apparel_sprite.visible = false
		apparel_sprite.texture = null
		return

	if not ApparelDatabase.APPAREL.has(apparel_id):
		apparel_sprite.visible = false
		apparel_sprite.texture = null
		return

	var apparel: Dictionary = ApparelDatabase.APPAREL[apparel_id]

	apparel_sprite.visible = true
	apparel_sprite.texture = load(apparel["texture_path"])


func _apply_equipped_appearance() -> void:
	animator.apply_appearance(GameState.equipped_squirrel_color)

	match GameState.equipped_cosmetic:
		"acorn_cap":
			set_apparel("acorn_cap")

		"super_squirrel":
			set_apparel("super_squirrel")

		"baseball_cap":
			set_apparel("baseball_cap")

		_:
			set_apparel("none")

# ======================================================
# --- ANIMATION HELPERS ---
# ======================================================
func change_state(new_state):
	if state == new_state:
		return

	state = new_state

	match state:
		PlayerState.IDLE:
			animator.play("idle")

		PlayerState.RUN:
			animator.play("run")

		PlayerState.JUMP:
			animator.play("jump")

		PlayerState.FALL:
			animator.play("fall")

		PlayerState.GLIDE:
			animator.play("glide")

		PlayerState.GLIDE_LOW:
			animator.play("glide_low")

		PlayerState.CROUCH:
			animator.play("crouch")

		PlayerState.SWING:
			animator.play("swing")

		PlayerState.WALL_CLING:
			animator.play("wall_cling")

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

	StatsManager.record_jump()

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
		if not gameplay_action_pressed("jump"):
			velocity.y *= JUMP_CUT_MULTIPLIER
		coyote_timer = 0
		jump_sound.pitch_scale = randf_range(1, 1.5)
		jump_sound.play()

# ======================================================
# --- GRAB/SNAP FUNCTION ---
# ======================================================
func snap_to_grab(pivot_position: Vector2):
	var offset = grab_point.global_position - global_position
	global_position = pivot_position - offset
	

# --- Fast Fall Through ---
func update_leaf_collision():
	if fall_state == "break":
		set_collision_mask_value(LEAF_LAYER, false)
	else:
		set_collision_mask_value(LEAF_LAYER, true)
		
		
# --- Placeholder shake effect ---
func landing_feedback() -> void:
	if fall_state != "shake":
		return

	visuals.scale.y = 0.7
	visuals.scale.x = 1.2 if facing_right else -1.2

	squirrel_sprite.modulate = Color(1, 0.8, 0.6)
	apparel_sprite.modulate = Color(1, 0.8, 0.6)

	await get_tree().create_timer(0.1).timeout

	visuals.scale = Vector2(1 if facing_right else -1, 1)
	squirrel_sprite.modulate = Color(1, 1, 1)
	apparel_sprite.modulate = Color(1, 1, 1)


# ======================================================
# --- PHYSICS PROCESS ---
# ======================================================
# --- Main Physics Loop ---
func _physics_process(delta: float) -> void:
	if physics_locked:
		return

	StatsManager.record_playtime(delta)
	StatsManager.record_airborne(delta,is_on_floor())
	StatsManager.record_idle_time(delta,is_on_floor(),abs(velocity.x))
	StatsManager.record_height(global_position.y)

	var menu_input_locked := movement_locked
	
	# --- Get Horizontal Input ---
	var direction := 0.0

	if not menu_input_locked:
		direction = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var is_crouching := false
	
	jump_cooldown = max(jump_cooldown - delta, 0.0)
	
	if is_gliding:
		# do nothing, preserve previous fall speed
		pass
	elif velocity.y > last_fall_speed:
		last_fall_speed = velocity.y

	if is_on_floor():
		last_fall_speed = 0.0
	
	# --- Facing ---
	if not swing.is_swinging:
		if direction > 0:
			facing_right = true
		elif direction < 0:
			facing_right = false

	if camera_controller:
		camera_controller.update_camera(
			delta,
			is_gliding,
			facing_right,
			is_on_floor()
		)

	# --- Swing Release ---
	if swing.is_swinging and gameplay_action_just_pressed("move_down"):
		swing.release_swing()
	
	# --- Swing Jump ---
	if swing.is_swinging and gameplay_action_just_pressed("jump"):
		player_jump()
	
	# --- If swinging, skip normal movement ---
	if swing.is_swinging:
		velocity.y = 0                 # reset vertical momentum
		last_fall_speed = 0.0          # reset fall tracking
		visuals.rotation_degrees = 0
		visuals.position = visuals_normal_position
		visuals.scale.y = 1
		visuals.scale.x = 1 if facing_right else -1
		change_state(PlayerState.SWING)
		return

# ======================================================
# --- GLIDE / FALL / GRAVITY ---
# ======================================================
	var on_floor = is_on_floor()
	var just_landed = on_floor and not was_on_floor

	var just_left_ground = !on_floor and was_on_floor

	if just_left_ground and velocity.y > 0:
		StatsManager.start_fall(global_position.y)

	# --- Fall tracking ---
	if on_floor:
		last_fall_speed = 0.0
		fall_timer = 0
	else:
		fall_timer += delta

	# --- Landing reset ---
	if just_landed:
		glide_timer = 0.0
		can_glide = true
		is_gliding = false

		if fall_timer > 0.25:
			land_sound.pitch_scale = randf_range(1, 1.5)
			land_sound.play()
			
		landing_feedback()

	# --- Reset glide from systems ---
	if is_wall_clinging or swing.is_swinging:
		glide_timer = 0.0
		can_glide = true
		is_gliding = false

	# --- Gravity + Glide ---
	if not on_floor:
		if velocity.y < 0:
			# Rising
			velocity += get_gravity() * delta
			is_gliding = false
			glide_timer = 0.0
		else:
			# Falling
			if gameplay_action_pressed("jump") and velocity.y > 100 and can_glide:
				# --- GLIDE ---
				is_gliding = true
				glide_timer += delta


				velocity.y = min(velocity.y, 120)
				velocity += get_gravity() * GLIDE_GRAVITY_MULTIPLIER * delta

				# --- Animation ---
				if glide_timer > max_glide_time * 0.6:
					change_state(PlayerState.GLIDE_LOW)
				else:
					change_state(PlayerState.GLIDE)

				# --- Exhaustion ---
				if glide_timer >= max_glide_time:
					can_glide = false
					is_gliding = false
			else:
				# Normal fall
				if is_gliding:
					is_gliding = false
				velocity += get_gravity() * FAST_FALL_MULTIPLIER * delta
			
	# --- Jump Buffer ---
	if gameplay_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER_TIME

	# --- Variable Jump Height ---
	if gameplay_action_just_released("jump") and velocity.y < 0:
		velocity.y *= JUMP_CUT_MULTIPLIER

	# --- Jump Check (Ground + Wall) ---
	if not swing.is_swinging and jump_buffer_timer > 0 and jump_cooldown <= 0.0:
		if is_on_floor() or coyote_timer > 0.0 or wall_coyote_timer > 0.0:
			player_jump()
			coyote_timer = 0.0
			wall_coyote_timer = 0.0
			jump_buffer_timer = 0.0

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
		if gameplay_action_pressed("move_down"):
			velocity.y = min(velocity.y, wall_cling_slide_speed)
		else:
			velocity.y = min(velocity.y, 0.0)

	# --- CROUCH + FALL-THROUGH ---
	if on_floor and gameplay_action_pressed("move_down"):
		is_crouching = true

		if abs(direction) < 0.1:
			crouch_timer += delta
			
			if crouch_timer >= CROUCH_DISABLE_TIME and fall_through_timer <= 0.0:
				fall_through_timer = FALL_THROUGH_DURATION
				set_collision_mask_value(LEAF_LAYER, false)
				
		else:
			crouch_timer = 0.0

		velocity.x = move_toward(
			velocity.x,
			direction * SPEED * CROUCH_SPEED_MULTIPLIER,
			GROUND_ACCEL * delta
		)
		change_state(PlayerState.CROUCH)
	else:
		crouch_timer = 0.0
		

	# --- High Speed Fall Through ---
	if velocity.y > 0:
		if velocity.y > LEAF_BREAK_SPEED:
			fall_state = "break"
			fast_fall_through_timer = FAST_FALL_THROUGH_DURATION
		elif velocity.y > LEAF_SHAKE_SPEED:
			fall_state = "shake"
		else:
			fall_state = "none"
	else:
		fall_state = "none"
		
	# --- LEAF COLLISION HANDLING ---
	var leaf_disabled := false

	# --- Timers ---
	if fast_fall_through_timer > 0.0:
		fast_fall_through_timer -= delta
		leaf_disabled = true

	if fall_through_timer > 0.0:
		fall_through_timer -= delta
		leaf_disabled = true

	# --- Apply result ONCE ---
	set_collision_mask_value(LEAF_LAYER, not leaf_disabled)

	for p in get_tree().get_nodes_in_group("leaf"):
		if p.has_method("set_leaf_disabled"):
			p.set_leaf_disabled(leaf_disabled)
		

	# Only update collision once per frame
	set_collision_mask_value(LEAF_LAYER, not leaf_disabled)


# --- STATE MACHINE ---
	if not is_crouching and not is_wall_clinging:
		var grounded = (on_floor or coyote_timer > 0.2) and not just_jumped
		
		if grounded:
			if abs(velocity.x) < 5:
				change_state(PlayerState.IDLE)
			else:
				change_state(PlayerState.RUN)
		else:
			if is_gliding:
				pass  # glide owns animation
			elif velocity.y < 0:
				change_state(PlayerState.JUMP)
			else:
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
	if on_floor and abs(velocity.x) > 0 and not gameplay_action_pressed("move_down"):
		if run_sound_timer.is_stopped():
			run_sound_timer.start()
	else:
		run_sound_timer.stop()


	# --- Apply Movement ---
	move_and_slide()

	var landed_this_frame := is_on_floor() and !was_on_floor

	var level := get_parent().get_node_or_null("Level")
	if level and level.has_method("update_horizontal_player_wrap"):
		level.update_horizontal_player_wrap()

	just_jumped = false
	
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()

		if collider and collider.is_in_group("leaf"):
			if fall_state == "shake":
				if collider.has_method("shake"):
					collider.shake()
	

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

	if landed_this_frame:

		StatsManager.record_landing(global_position.y)

		SaveManager.save_data.player_position = (SaveManager.vector2_to_dict(global_position))

		SaveManager.save_data.player_velocity = (SaveManager.vector2_to_dict(Vector2.ZERO))

		SaveManager.save_data.player_grounded = true

		SaveManager.mark_dirty()

		was_on_floor = is_on_floor()

	if velocity.y > 1000 and !fall_save_triggered:
		SaveManager.save_data.player_position = (SaveManager.vector2_to_dict(global_position))
		SaveManager.save_data.player_velocity = (SaveManager.vector2_to_dict(velocity))
		SaveManager.save_data.player_grounded = false

		SaveManager.mark_dirty()

		fall_save_triggered = true

	if is_on_floor():
		fall_save_triggered = false

# ======================================================
# --- RUN SOUND TIMER CALLBACK ---
# ======================================================
func _on_run_sound_timer_timeout() -> void:
	run_sound.pitch_scale = randf_range(1, 1.5)
	run_sound.play()
	
	
# ======================================================
# --- MENU / INPUT LOCK ---
# ======================================================
func set_input_enabled(enabled: bool) -> void:
	input_enabled = enabled
	movement_locked = not enabled

	if movement_locked:
		stop_player_control()


func stop_player_control() -> void:
	velocity.x = 0.0

	is_gliding = false
	is_wall_clinging = false
	wall_dir = 0
	crouch_timer = 0.0
	jump_buffer_timer = 0.0

	run_sound.stop()
	run_sound_timer.stop()

	var actions := [
		"move_left",
		"move_right",
		"move_down",
		"jump",
		"glide",
		"fast_fall",
		"interact"
	]

	for action in actions:
		if InputMap.has_action(action):
			Input.action_release(action)

func gameplay_action_pressed(action_name: String) -> bool:
	if movement_locked:
		return false
	return Input.is_action_pressed(action_name)


func gameplay_action_just_pressed(action_name: String) -> bool:
	if movement_locked:
		return false
	return Input.is_action_just_pressed(action_name)


func gameplay_action_just_released(action_name: String) -> bool:
	if movement_locked:
		return false
	return Input.is_action_just_released(action_name)


func snap_camera_after_world_wrap() -> void:
	if camera_controller:
		camera_controller.snap_after_world_wrap()


func _unhandled_input(event: InputEvent) -> void:
	if movement_locked:
		return

	if event is InputEventKey and event.echo:
		return

	if event.is_action_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER_TIME

	if event.is_action_pressed("debug_random_squirrel"):

		var random_id: String = AppearanceDatabase.get_random_appearance_id_except(
			GameState.equipped_squirrel_color
		)

		GameState.equip_squirrel_color(random_id)


func find_exit_spawn(spawn_id: String) -> Node:

	for node in get_tree().get_nodes_in_group("spawn_points"):

		if node.has_meta("spawn_id"):

			if node.get_meta("spawn_id") == spawn_id:
				return node

	return null
