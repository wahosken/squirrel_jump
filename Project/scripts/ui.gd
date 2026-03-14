extends Control

@onready var fullscreen_button: TouchScreenButton = $HBoxContainer3/FullscreenButton
@export var windowed_texture: Texture2D
@export var fullscreen_texture: Texture2D

func _ready():
	hide()
	
	update_fullscreen_button_texture()
	
func _on_fullscreen_button_pressed() -> void:
	print("fullscreen button pressed")

	if is_currently_fullscreen():
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

	update_fullscreen_button_texture()
	update_fullscreen_button_texture()

func is_currently_fullscreen() -> bool:
	var mode := DisplayServer.window_get_mode()
	return mode == DisplayServer.WINDOW_MODE_FULLSCREEN \
		or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN

func update_fullscreen_button_texture() -> void:
	if fullscreen_button == null:
		return

	if is_currently_fullscreen():
		fullscreen_button.texture_normal = fullscreen_texture
	else:
		fullscreen_button.texture_normal = windowed_texture

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
