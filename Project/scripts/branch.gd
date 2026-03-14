extends Node2D

@onready var branch_end: Sprite2D = $BranchEnd


func get_swing_point():
	return $SwingPoint.global_position


func _on_grab_area_body_entered(body):

	if body.has_node("SwingComponent") and !body.swing.is_swinging:
		branch_end.visible = true
		body.swing.start_swing(get_swing_point())
