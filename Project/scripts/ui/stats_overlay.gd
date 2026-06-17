extends CanvasLayer

signal stats_closed

@onready var close_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/CloseButton

func _ready() -> void:
	call_deferred("grab_default_focus")

	$CenterContainer/PanelContainer/MarginContainer/VBoxContainer/PlaytimeLabel.text = \
		"Playtime: %s sec" % SaveManager.save_data.playtime_seconds

	$CenterContainer/PanelContainer/MarginContainer/VBoxContainer/JumpsLabel.text = \
		"Jumps: %s" % SaveManager.save_data.total_jumps

	$CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HighestHeightLabel.text = \
		"Highest Height: %s" % SaveManager.save_data.highest_height_reached

	$CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TotalHeightLabel.text = \
		"Height Climbed: %s" % SaveManager.save_data.total_height_climbed

	$CenterContainer/PanelContainer/MarginContainer/VBoxContainer/FallsLabel.text = \
		"Falls: %s" % SaveManager.save_data.total_falls

	$CenterContainer/PanelContainer/MarginContainer/VBoxContainer/FallDistanceLabel.text = \
		"Distance Fallen: %s" % SaveManager.save_data.total_distance_fallen

	$CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ComebacksLabel.text = \
		"Major Comebacks: %s" % SaveManager.save_data.major_comebacks

	$CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ReturnsLabel.text = \
		"Returned To Ground: %s" % SaveManager.save_data.times_returned_to_ground


func grab_default_focus() -> void:
	if is_instance_valid(close_button):
		close_button.grab_focus()


func _on_close_button_pressed() -> void:
	stats_closed.emit()
	queue_free()
