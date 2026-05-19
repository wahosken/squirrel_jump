extends Area2D

signal collected(nut)

@onready var nut_sound: AudioStreamPlayer2D = $NutSound

var is_collected := false


func set_active(active: bool) -> void:
	if is_collected:
		visible = false
		set_physics_process(false)

		for c in get_children():
			if c is CollisionShape2D:
				c.disabled = true

		return

	visible = active
	set_physics_process(active)

	for c in get_children():
		if c is CollisionShape2D:
			c.disabled = not active


func _on_body_entered(_body: Node2D) -> void:
	if is_collected:
		return

	is_collected = true

	print("+! nut!")

	# Disable collision immediately so it cannot be collected twice
	for c in get_children():
		if c is CollisionShape2D:
			c.set_deferred("disabled", true)

	set_physics_process(false)
	hide()

	emit_signal("collected", self)

	nut_sound.pitch_scale = randf_range(1.0, 1.5)
	nut_sound.play()

	await nut_sound.finished
	queue_free()
