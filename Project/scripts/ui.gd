extends Control

func _ready():
	hide()

func _input(event):
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		show()

	if event is InputEventKey:
		hide()


func _on_left_button_down() -> void:
	Input.action_press("move_left")


func _on_left_button_up() -> void:
	Input.action_release("move_left")


func _on_right_button_down() -> void:
	Input.action_press("move_right")


func _on_right_button_up() -> void:
	Input.action_release("move_right")


func _on_up_button_down() -> void:
	Input.action_press("jump")


func _on_up_button_up() -> void:
	Input.action_release("jump")


func _on_down_button_down() -> void:
	Input.action_press("move_down")


func _on_down_button_up() -> void:
	Input.action_release("move_down")
