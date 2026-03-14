extends TextureRect

@export var windowed_texture: Texture2D
@export var fullscreen_texture: Texture2D

func _ready() -> void:
	update_texture()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		toggle_fullscreen()

func toggle_fullscreen() -> void:
	if is_currently_fullscreen():
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	update_texture()

func is_currently_fullscreen() -> bool:
	var mode = DisplayServer.window_get_mode()
	return mode == DisplayServer.WINDOW_MODE_FULLSCREEN \
		or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN

func update_texture() -> void:
	if is_currently_fullscreen():
		texture = fullscreen_texture
	else:
		texture = windowed_texture
