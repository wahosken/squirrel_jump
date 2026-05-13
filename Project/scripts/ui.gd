extends Control

var touch_controls_visible := true
var input_mode_change_locked := false

const INPUT_MODE_CHANGE_DELAY := 0.15

func _ready() -> void:
	show()

func _input(event: InputEvent) -> void:
	if input_mode_change_locked:
		return

	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		_switch_to_touch_controls()

	elif event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion:
		_switch_to_controller_controls()

func _switch_to_touch_controls() -> void:
	if touch_controls_visible:
		return

	touch_controls_visible = true
	show()

	_lock_input_mode_change()


func _switch_to_controller_controls() -> void:
	if !touch_controls_visible:
		return

	touch_controls_visible = false
	hide()

	_lock_input_mode_change()


func _lock_input_mode_change() -> void:
	input_mode_change_locked = true
	await get_tree().create_timer(INPUT_MODE_CHANGE_DELAY).timeout
	input_mode_change_locked = false

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
