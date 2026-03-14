extends Control

@export var fullscreen_button: TextureRect
@export var windowed_texture: Texture2D
@export var fullscreen_texture: Texture2D

var last_window_mode: int

func _ready():
	hide()
	update_button_texture()
	
@export var _fullscreen_change_callback_name := "on_fullscreen_change"
	
func on_fullscreen_change() -> void:
	# Update the icon based on the actual display mode
	update_button_texture()

func _on_fullscreen_button_pressed() -> void:
	# Trigger fullscreen request
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func update_button_texture() -> void:
	if fullscreen_button == null:
		return

	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		fullscreen_button.texture = fullscreen_texture
	else:
		fullscreen_button.texture = windowed_texture

func _input(event):
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		show()

	if event is InputEventKey:
		hide()


func _on_left_pressed() -> void:
	Input.action_press("move_left")


func _on_left_released() -> void:
	Input.action_release("move_left")


func _on_right_pressed() -> void:
	Input.action_press("move_right")


func _on_right_released() -> void:
	Input.action_release("move_right")


func _on_up_pressed() -> void:
	Input.action_press("jump")


func _on_up_released() -> void:
	Input.action_release("jump")


func _on_down_pressed() -> void:
	Input.action_press("move_down")


func _on_down_released() -> void:
	Input.action_release("move_down")
