extends CanvasLayer

signal popup_closed
signal reset_confirmed

@onready var cancel_button: Button = $Panel/MarginContainer/VBoxContainer/HBoxContainer/CancelButton


func _ready() -> void:
	call_deferred("grab_default_focus")


func grab_default_focus() -> void:
	if is_instance_valid(cancel_button):
		cancel_button.grab_focus()


func _on_cancel_button_pressed() -> void:
	popup_closed.emit()
	queue_free()


func _on_reset_button_pressed() -> void:
	popup_closed.emit()
	reset_confirmed.emit()

	queue_free()
