extends Area2D

@export var target_scene: String = "res://scenes/shop.tscn"

# Unique identifier for this building entrance
@export var exit_spawn_id := ""

# Interior spawn location
@export var spawn_position: Vector2

var player_in_range := false

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(_delta):

	if player_in_range and Input.is_action_just_pressed("interact"):

		print("SETTING EXIT SPAWN:")
		print(exit_spawn_id)

		SaveManager.set_exit_spawn(exit_spawn_id)

		SaveManager.scene_spawn_override = spawn_position
		SaveManager.use_scene_spawn = true

		get_tree().change_scene_to_file(target_scene)

func _on_body_entered(body):

	if body.is_in_group("player"):
		player_in_range = true

func _on_body_exited(body):

	if body.is_in_group("player"):
		player_in_range = false
