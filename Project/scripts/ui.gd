extends Control


func _ready():
	hide()
	

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
