extends CharacterBody2D

@onready var visuals: Node2D = $Visuals

enum State {
	IDLE,
	SHAKING,
	FALLING,
	RESPAWNING
}

@export var shake_time: float = 0.8
@export var fall_time: float = 1.5
@export var gravity: float = 900.0
@export var shake_intensity: float = 2.0
@export var respawn_time: float = 1.5

var state: State = State.IDLE

var original_position: Vector2
var original_collision_layer := 0
var original_collision_mask := 0

func _ready():
	original_position = position
	original_collision_layer = collision_layer
	original_collision_mask = collision_mask


func _physics_process(delta):
	if state == State.FALLING:
		velocity.y += gravity * delta
		move_and_slide()


# ----------------------------------------------------
# TRIGGER
# ----------------------------------------------------

func _on_area_2d_body_entered(body):
	if state != State.IDLE:
		return

	if body.is_in_group("player") and body.velocity.y >= 0:
		start_sequence()


func start_sequence():
	if state != State.IDLE:
		return

	state = State.SHAKING
	run_sequence()


# ----------------------------------------------------
# MAIN GUARANTEED SEQUENCE
# ----------------------------------------------------

func run_sequence() -> void:
	await shake_phase()
	await fall_phase()
	await respawn_phase()

	state = State.IDLE


# ----------------------------------------------------
# SHAKE PHASE (GUARANTEED COMPLETE)
# ----------------------------------------------------

func shake_phase() -> void:
	var t = shake_time

	while t > 0:
		await get_tree().process_frame
		t -= get_process_delta_time()

		var offset = sin(Time.get_ticks_msec() * 0.05) * shake_intensity
		visuals.position.x = offset
		visuals.position.y = 0
		visuals.rotation_degrees = offset * 0.5

	# HARD RESET VISUALS
	visuals.position = Vector2.ZERO
	visuals.rotation_degrees = 0


# ----------------------------------------------------
# FALL PHASE (PHYSICS DRIVEN)
# ----------------------------------------------------

func fall_phase() -> void:
	state = State.FALLING

	# disable collision once
	collision_layer = 0
	collision_mask = 0

	var t = fall_time

	while t > 0:
		await get_tree().process_frame
		t -= get_process_delta_time()

	# ensure we exit cleanly
	velocity = Vector2.ZERO


# ----------------------------------------------------
# RESPAWN PHASE
# ----------------------------------------------------

func respawn_phase() -> void:
	state = State.RESPAWNING

	position = original_position

	visible = true
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.3)

	visuals.position = Vector2.ZERO
	visuals.rotation_degrees = 0

	await get_tree().process_frame

	collision_layer = original_collision_layer
	collision_mask = original_collision_mask

	# IMPORTANT: platform becomes active immediately
	state = State.IDLE
