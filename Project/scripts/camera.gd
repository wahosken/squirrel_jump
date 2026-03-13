extends Camera2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	adjust_zoom()

func adjust_zoom():
	var screen = get_viewport().get_visible_rect().size
	
	if screen.y > screen.x:
		zoom = Vector2(2.75, 2.75)
	else:
		zoom = Vector2(2.0, 2.0)

func _notification(what):
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		adjust_zoom()
