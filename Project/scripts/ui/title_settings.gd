extends CanvasLayer

signal settings_closed

@export var reset_progress_popup_scene: PackedScene

@onready var audio_button: Button = $Panel/MarginContainer/VBoxContainer/AudioButton

func _ready() -> void:
	call_deferred("grab_default_focus")


func _on_visibility_changed() -> void:
	if visible:
		call_deferred("grab_default_focus")


func grab_default_focus() -> void:
	if is_instance_valid(audio_button):
		audio_button.grab_focus()



func _on_reset_progress_pressed() -> void:
	if reset_progress_popup_scene == null:
		return

	var popup = reset_progress_popup_scene.instantiate()

	get_tree().root.add_child(popup)

	popup.reset_confirmed.connect(_on_reset_confirmed)
	popup.popup_closed.connect(_on_popup_closed)


func _on_popup_closed() -> void:
	call_deferred("grab_default_focus")


func _on_close_button_pressed() -> void:
	settings_closed.emit()
	queue_free()


func _on_reset_confirmed() -> void:

	SaveManager.reset_save()
