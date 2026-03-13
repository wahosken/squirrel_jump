extends Camera2D

@export var normal_zoom := 2
@export var mobile_zoom := 3   # smaller = more zoomed in

func _ready():
	update_zoom()

func update_zoom():
	var size = get_viewport_rect().size

	if size.y > size.x:
		zoom = Vector2(mobile_zoom, mobile_zoom)
	else:
		zoom = Vector2(normal_zoom, normal_zoom)
