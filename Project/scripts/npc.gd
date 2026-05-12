extends Area2D

@export var npc_name: String = "Merchant"
@export var menu_scene: PackedScene

@onready var prompt_label: Label = $PromptLabel

var player_in_range := false
var player_ref: Node = null
var menu_instance: Node = null
var is_active := true
var waiting_for_interact_release := false
var waiting_to_unlock_player := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	player_in_range = false
	player_ref = null
	menu_instance = null

	update_prompt_visibility()


func _process(_delta: float) -> void:
	if waiting_to_unlock_player:
		if menu_inputs_released():
			waiting_to_unlock_player = false
			set_player_input_enabled(true)
		return

	if not is_active:
		return

	if waiting_for_interact_release:
		if not Input.is_action_pressed("interact"):
			waiting_for_interact_release = false
		return

	if menu_instance != null:
		return

	if GameState.menu_open or GameState.menu_open_cooldown:
		return

	if player_in_range and Input.is_action_just_pressed("interact"):
		open_menu()


# ------------------------------------------------------
# Player detection
# ------------------------------------------------------

func _on_body_entered(body: Node) -> void:
	if not is_active:
		return

	if body.is_in_group("player"):
		player_in_range = true
		player_ref = body
		update_prompt_visibility()


func _on_body_exited(body: Node) -> void:
	if body == player_ref:
		player_in_range = false
		player_ref = null
		update_prompt_visibility()


# ------------------------------------------------------
# Prompt
# ------------------------------------------------------

func update_prompt_visibility() -> void:
	if is_active and player_in_range and menu_instance == null:
		prompt_label.show()
	else:
		prompt_label.hide()


# ------------------------------------------------------
# Menu
# ------------------------------------------------------

func open_menu() -> void:
	if menu_instance != null:
		return

	if not GameState.request_menu_open("merchant"):
		return

	if menu_scene == null:
		GameState.close_menu_state("merchant")
		push_warning("%s has no menu_scene assigned." % name)
		return

	menu_instance = menu_scene.instantiate()
	get_tree().current_scene.add_child(menu_instance)

	if menu_instance.has_method("setup"):
		menu_instance.setup(npc_name)

	if menu_instance.has_signal("menu_closed"):
		menu_instance.menu_closed.connect(_on_menu_closed)
	else:
		GameState.close_menu_state("merchant")
		push_warning("Menu scene has no menu_closed signal.")
		menu_instance.queue_free()
		menu_instance = null
		return

	set_player_input_enabled(false)
	update_prompt_visibility()


func _on_menu_closed() -> void:
	cleanup_menu()


func cleanup_menu() -> void:
	if menu_instance == null:
		return

	menu_instance = null

	GameState.close_menu_state("merchant")

	waiting_for_interact_release = true
	waiting_to_unlock_player = true

	update_prompt_visibility()


func set_player_input_enabled(enabled: bool) -> void:
	var target_player := player_ref

	if target_player == null or not is_instance_valid(target_player):
		if not is_inside_tree():
			return

		var tree := get_tree()
		if tree == null:
			return

		var players := tree.get_nodes_in_group("player")
		if players.size() > 0:
			target_player = players[0]

	if target_player != null and target_player.has_method("set_input_enabled"):
		target_player.set_input_enabled(enabled)
	else:
		push_warning("NPC could not find player to set input enabled.")


# ------------------------------------------------------
# Section activation support
# ------------------------------------------------------

func set_active(active: bool) -> void:
	is_active = active

	visible = active
	monitoring = active
	set_process(active)
	set_physics_process(active)

	if not active:
		player_in_range = false
		player_ref = null

		if menu_instance != null and is_instance_valid(menu_instance):
			menu_instance.queue_free()
			menu_instance = null

		set_player_input_enabled(true)

	update_prompt_visibility()

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
