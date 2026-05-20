extends AnimatableBody2D

@export var bounce_force: float = -550.0
@export var directional_boost: float = 120.0
@export var min_fall_speed: float = 50.0

@export var squash_amount: float = 0.2
@export var squash_time: float = 0.08

@onready var visuals: Sprite2D = $Sprite2D

var original_position: Vector2
var original_collision_layer := 0
var original_collision_mask := 0

var tween: Tween
var is_active := false


func _ready():
	original_position = position
	original_collision_layer = collision_layer
	original_collision_mask = collision_mask


func set_active(active: bool):
	if is_active == active:
		return

	is_active = active

	visible = active
	set_physics_process(active)

	if active:
		reset()
	else:
		_disable_collision()


func set_leaf_disabled(disabled: bool) -> void:
	for c in get_children():
		if c is CollisionPolygon2D or c is CollisionShape2D:
			c.set_deferred("disabled", disabled)


func play_squash():
	if tween:
		tween.kill()

	tween = create_tween()
	tween.tween_property(visuals, "scale", Vector2(1.2, 0.8), squash_time)
	tween.tween_property(visuals, "scale", Vector2.ONE, squash_time)


func reset():
	position = original_position
	visuals.scale = Vector2.ONE

	if tween:
		tween.kill()
		tween = null

	collision_layer = original_collision_layer
	collision_mask = original_collision_mask

	for c in get_children():
		if c is CollisionShape2D or c is CollisionPolygon2D:
			c.set_deferred("disabled", false)


func _disable_collision():
	collision_layer = 0
	collision_mask = 0

	for c in get_children():
		if c is CollisionShape2D or c is CollisionPolygon2D:
			c.set_deferred("disabled", true)
