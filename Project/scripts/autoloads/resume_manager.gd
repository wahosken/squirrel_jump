extends Node

signal resume_started
signal resume_finished
signal world_frozen_changed(frozen: bool)

var is_resuming := false
var should_resume := false

var world_frozen := false

var resume_duration := 1.5


func start_resume_sequence() -> void:

	print("SHOULD RESUME:", should_resume)

	if !should_resume:
		print("RESUME CANCELLED")
		return

	print("RESUME STARTING")

	if is_resuming:
		return

	is_resuming = true

	world_frozen = true
	world_frozen_changed.emit(true)

	print("Resume Started")

	resume_started.emit()

	await get_tree().create_timer(resume_duration).timeout

	is_resuming = false

	world_frozen = false
	world_frozen_changed.emit(false)

	should_resume = false

	print("Resume Finished")

	resume_finished.emit()


func can_play() -> bool:
	return !is_resuming


func is_world_frozen() -> bool:
	return world_frozen


func clear_resume() -> void:
	should_resume = false
