extends Area2D

@export var npc_name: String = "Merchant"
@export var menu_scene: PackedScene

@onready var prompt_label: Label = $PromptLabel

var player_in_range := false
var player_ref: Node = null
var menu_instance: Node = null


func _ready() -> void:
	player_in_range = false
	player_ref = null
	menu_instance = null

	update_prompt_visibility()

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	if player_in_range and Input.is_action_just_pressed("interact"):
		open_menu()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		player_ref = body
		update_prompt_visibility()


func _on_body_exited(body: Node) -> void:
	if body == player_ref:
		player_in_range = false
		player_ref = null
		update_prompt_visibility()


func update_prompt_visibility() -> void:
	if player_in_range and menu_instance == null:
		prompt_label.show()
	else:
		prompt_label.hide()


func open_menu() -> void:
	if menu_instance != null:
		return

	if menu_scene == null:
		push_warning("NPC has no menu_scene assigned.")
		return

	menu_instance = menu_scene.instantiate()
	get_tree().current_scene.add_child(menu_instance)

	if menu_instance.has_method("setup"):
		menu_instance.setup(npc_name)

	if menu_instance.has_signal("menu_closed"):
		menu_instance.menu_closed.connect(_on_menu_closed)

	if player_ref != null and player_ref.has_method("set_input_enabled"):
		player_ref.set_input_enabled(false)

	update_prompt_visibility()


func _on_menu_closed() -> void:
	menu_instance = null

	if player_ref != null and player_ref.has_method("set_input_enabled"):
		player_ref.set_input_enabled(true)

	update_prompt_visibility()
	
	
func set_active(active: bool) -> void:
	visible = active
	set_process(active)
	set_physics_process(active)
	monitoring = active

	if not active:
		player_in_range = false
		player_ref = null

	update_prompt_visibility()
