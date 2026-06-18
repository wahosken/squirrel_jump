extends Area2D

@export var target_scene := "res://scenes/game.tscn"

var player_in_range := false

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(_delta):

	if player_in_range and Input.is_action_just_pressed("interact"):

		ResumeManager.clear_resume()

		print("DOOR CLEARED RESUME:",
			ResumeManager.should_resume)

		get_tree().change_scene_to_file(target_scene)

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
