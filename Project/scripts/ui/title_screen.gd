extends Control

@export var title_settings_scene: PackedScene

@onready var play_button: Button = $CanvasLayer/CenterContainer/VBoxContainer/PlayButton


func _ready() -> void:
	call_deferred("grab_default_focus")


func grab_default_focus() -> void:
	if is_instance_valid(play_button):
		play_button.grab_focus()



func _on_play_button_pressed() -> void:
	ResumeManager.should_resume = true

	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_settings_button_pressed() -> void:
	if title_settings_scene == null:
		return

	var settings = title_settings_scene.instantiate()

	get_tree().root.add_child(settings)

	settings.settings_closed.connect(_on_settings_closed)


func _on_settings_closed() -> void:
	call_deferred("grab_default_focus")
