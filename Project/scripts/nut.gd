extends Area2D


@onready var nut_sound: AudioStreamPlayer2D = $NutSound

signal collected(nut)

func _on_body_entered(_body: Node2D) -> void:
	
	print("+! nut!")
	
	nut_sound.pitch_scale = randf_range(1, 1.5)
	nut_sound.play()
	
	hide()
	emit_signal("collected", self)
	
	await nut_sound.finished
	queue_free()
	
