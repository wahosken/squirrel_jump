extends Node2D


func get_swing_point():
	return $SwingPoint.global_position


func _on_grab_area_body_entered(body):

	if body.has_node("SwingComponent") and !body.swing.is_swinging:
		body.swing.start_swing(get_swing_point())
