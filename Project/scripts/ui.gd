extends Control

@export var fullscreen_button: TouchScreenButton

func _ready() -> void:
	hide()
	# Ensure the button has a texture
	if fullscreen_button:
		fullscreen_button.texture_normal = preload("uid://b62nx1nn1u1t2")

# Connect the button's pressed signal to this function
func _on_fullscreen_button_pressed() -> void:
	if not fullscreen_button:
		return

	# Toggle fullscreen
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _input(event):
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		show()

	if event is InputEventKey:
		hide()
		

func press_action(action_name: String) -> void:
	var event := InputEventAction.new()
	event.action = action_name
	event.pressed = true
	Input.parse_input_event(event)


func release_action(action_name: String) -> void:
	var event := InputEventAction.new()
	event.action = action_name
	event.pressed = false
	Input.parse_input_event(event)


func _on_left_pressed() -> void:
	press_action("move_left")
	press_action("ui_left")


func _on_left_released() -> void:
	release_action("move_left")
	release_action("ui_left")


func _on_right_pressed() -> void:
	press_action("move_right")
	press_action("ui_right")


func _on_right_released() -> void:
	release_action("move_right")
	release_action("ui_right")


func _on_up_pressed() -> void:
	press_action("jump")
	press_action("ui_up")


func _on_up_released() -> void:
	release_action("jump")
	release_action("ui_up")


func _on_down_pressed() -> void:
	press_action("move_down")
	press_action("ui_down")


func _on_down_released() -> void:
	release_action("move_down")
	release_action("ui_down")


func _on_interact_pressed() -> void:
	press_action("interact")
	press_action("ui_accept")

func _on_interact_released() -> void:
	release_action("interact")
	release_action("ui_accept")
