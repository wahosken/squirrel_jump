extends CanvasLayer

func _ready():
	if OS.has_feature("web") and DisplayServer.is_touchscreen_available():
		show()
	else:
		hide()
