extends Node

@export var pause_menu_scene: PackedScene

var pause_menu_instance: Node = null
var waiting_for_pause_release := false
var waiting_to_unlock_player := false


func _process(_delta: float) -> void:
	if waiting_to_unlock_player:
		if menu_inputs_released():
			waiting_to_unlock_player = false
			set_player_input_enabled(true)
		return

	if waiting_for_pause_release:
		if not Input.is_action_pressed("pause") and not Input.is_action_pressed("ui_cancel"):
			waiting_for_pause_release = false
		return

	if pause_menu_instance != null:
		return

	if GameState.menu_open or GameState.menu_open_cooldown:
		return

	if Input.is_action_just_pressed("pause"):
		open_pause_menu()


func open_pause_menu() -> void:
	if pause_menu_instance != null:
		return

	if not GameState.request_menu_open("pause"):
		return

	if pause_menu_scene == null:
		GameState.close_menu_state("pause")
		push_warning("No pause menu scene assigned.")
		return

	pause_menu_instance = pause_menu_scene.instantiate()
	get_tree().current_scene.add_child(pause_menu_instance)

	if pause_menu_instance.has_signal("menu_closed"):
		pause_menu_instance.menu_closed.connect(_on_pause_menu_closed)
	else:
		GameState.close_menu_state("pause")
		push_warning("Pause menu has no menu_closed signal.")
		pause_menu_instance.queue_free()
		pause_menu_instance = null
		return

	set_player_input_enabled(false)


func _on_pause_menu_closed() -> void:
	cleanup_pause_menu()


func _on_pause_menu_removed() -> void:
	cleanup_pause_menu()


func cleanup_pause_menu() -> void:
	if pause_menu_instance == null:
		return

	pause_menu_instance = null

	GameState.close_menu_state("pause")
	waiting_for_pause_release = true
	
	waiting_to_unlock_player = true


func set_player_input_enabled(enabled: bool) -> void:
	var player = get_tree().get_first_node_in_group("player")

	if player != null and player.has_method("set_input_enabled"):
		player.set_input_enabled(enabled)


func reset_pause_state() -> void:
	pause_menu_instance = null
	waiting_for_pause_release = false
	waiting_to_unlock_player = false

	GameState.close_menu_state("pause")


func menu_inputs_released() -> bool:
	var actions := [
		"jump",
		"interact",
		"ui_accept",
		"ui_cancel",
		"pause"
	]

	for action in actions:
		if InputMap.has_action(action) and Input.is_action_pressed(action):
			return false

	return true
