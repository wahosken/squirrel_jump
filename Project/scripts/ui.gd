extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	adjust_ui_scale()


func adjust_ui_scale():
	var screen = get_viewport().get_visible_rect().size
	
	if screen.y > screen.x:
		# portrait
		scale = Vector2(1.4, 1.4)
	else:
		# landscape
		scale = Vector2(1.0, 1.0)

func _notification(what):
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		adjust_ui_scale()
