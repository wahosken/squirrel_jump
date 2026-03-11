extends CanvasLayer

func _ready():
	hide()

func _input(event):
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		show()
