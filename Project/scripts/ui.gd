extends Control

@onready var left: TextureButton = $HBoxContainer/Left
@onready var right: TextureButton = $HBoxContainer/Right
@onready var down: TextureButton = $HBoxContainer2/Down
@onready var up: TextureButton = $HBoxContainer2/Up

func _ready():
	hide()

func _input(event):

	if event is InputEventScreenTouch:
		
		show()

		var pos = event.position

		_update_button(left, pos, "move_left", event.pressed)
		_update_button(right, pos, "move_right", event.pressed)
		_update_button(up, pos, "jump", event.pressed)
		_update_button(down, pos, "move_down", event.pressed)
		
func _update_button(button, pos, action, pressed):

	if button.get_global_rect().has_point(pos):

		if pressed:
			Input.action_press(action)
		else:
			Input.action_release(action)


#func _on_left_button_down() -> void:
#	Input.action_press("move_left")


#func _on_left_button_up() -> void:
#	Input.action_release("move_left")


#func _on_right_button_down() -> void:
#	Input.action_press("move_right")


#func _on_right_button_up() -> void:
#	Input.action_release("move_right")


#func _on_up_button_down() -> void:
#	Input.action_press("jump")


#func _on_up_button_up() -> void:
#	Input.action_release("jump")


#func _on_down_button_down() -> void:
#	Input.action_press("move_down")


#func _on_down_button_up() -> void:
#	Input.action_release("move_down")
