extends Area2D

@export var target_scene := "res://scenes/shop.tscn"
@export var spawn_position : Vector2
@export var exit_spawn_id := "shop_1_secret"


func _ready():
	body_entered.connect(_on_body_entered)


func _on_body_entered(body):

	if !body.is_in_group("player"):
		return

	var offset = abs(
		body.global_position.x - global_position.x
	)

	if offset > 16:
		return

	if body.velocity.y <= 0:
		return

	SaveManager.set_exit_spawn(exit_spawn_id)

	SaveManager.scene_spawn_override = spawn_position
	SaveManager.use_scene_spawn = true

	call_deferred("_enter_secret_scene")


func _enter_secret_scene():
	get_tree().change_scene_to_file(target_scene)
