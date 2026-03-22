extends AnimatableBody2D

func set_active(active: bool):
	set_physics_process(active)

	for c in get_children():
		if c is CollisionShape2D:
			c.disabled = not active


@onready var visuals: Node2D = $Visuals

@export var shake_time: float = 0.8
@export var fall_time: float = 1.5
@export var gravity: float = 900.0
@export var shake_intensity: float = 2.0
@export var respawn_time: float = 1.5

var respawn_timer := 0.0
var respawning := false
var activated := false
var shaking := false
var falling := false

var velocity := Vector2.ZERO
var original_position: Vector2
var shake_timer := 0.0
var fall_timer := 0.0

func _ready():
	original_position = position

func _physics_process(delta):
	if shaking:
		shake_timer -= delta

		var shake_offset = sin(Time.get_ticks_msec() * 0.05) * shake_intensity
		visuals.position.x = shake_offset
		visuals.position.y = 0

		visuals.rotation_degrees = shake_offset * 0.5

		if shake_timer <= 0:
			shaking = false
			falling = true
			visuals.position = Vector2.ZERO
			visuals.rotation_degrees = 0

	elif falling:
		fall_timer -= delta

		velocity.y += gravity * delta
		position += velocity * delta

		if fall_timer <= 0:
			start_respawn()
			
	if respawning:
		respawn_timer -= delta

		if respawn_timer <= 0:
			respawn()
		return

func _on_area_2d_body_entered(body):	
	if activated:
		return

	if body.is_in_group("player") and body.velocity.y >= 0:
		start_fall_sequence()

func start_fall_sequence():
	activated = true
	shaking = true
	shake_timer = shake_time
	fall_timer = fall_time
	
func start_respawn():
	respawning = true
	respawn_timer = respawn_time

	# Hide platform
	visible = false

	# Disable collisions
	for c in get_children():
		if c is CollisionShape2D:
			c.disabled = true

	# Reset physics state
	falling = false
	shaking = false
	activated = false
	velocity = Vector2.ZERO
	
func respawn():
	respawning = false

	# Reset position
	position = original_position

	# Show platform again
	visible = true
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.3)

	# Re-enable collision
	for c in get_children():
		if c is CollisionShape2D:
			c.disabled = false
			
	visuals.position = Vector2.ZERO
	visuals.rotation_degrees = 0
