extends Area2D

@export var npc_name: String = "Merchant"
@export var menu_scene: PackedScene

@onready var prompt_label: Label = $PromptLabel

var player_in_range := false
var player_ref: Node = null
var menu_instance: Node = null
var is_active := true
var waiting_for_interact_release := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	player_in_range = false
	player_ref = null
	menu_instance = null

	update_prompt_visibility()


func _process(_delta: float) -> void:
	if not is_active:
		return

	if waiting_for_interact_release:
		if not Input.is_action_pressed("interact"):
			waiting_for_interact_release = false
		return

	if menu_instance != null:
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
	if menu_scene == null:
		push_warning("%s has no menu_scene assigned." % name)
		return

	menu_instance = menu_scene.instantiate()
	get_tree().current_scene.add_child(menu_instance)

	if menu_instance.has_method("setup"):
		menu_instance.setup(npc_name)

	if menu_instance.has_signal("menu_closed"):
		menu_instance.menu_closed.connect(_on_menu_closed)

	# Backup cleanup in case the menu gets freed without emitting menu_closed.
	menu_instance.tree_exited.connect(_on_menu_removed)

	set_player_input_enabled(false)
	update_prompt_visibility()


func _on_menu_closed() -> void:
	cleanup_menu()


func _on_menu_removed() -> void:
	cleanup_menu()


func cleanup_menu() -> void:
	menu_instance = null
	set_player_input_enabled(true)

	waiting_for_interact_release = true

	update_prompt_visibility()


func set_player_input_enabled(enabled: bool) -> void:
	if player_ref != null and player_ref.has_method("set_input_enabled"):
		player_ref.set_input_enabled(enabled)


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
