extends Node

signal resume_started
signal resume_finished

var is_resuming := false
var resume_duration := 1.5


func start_resume_sequence() -> void:
	if is_resuming:
		return

	is_resuming = true

	print("Resume Started")

	resume_started.emit()

	await get_tree().create_timer(resume_duration).timeout

	is_resuming = false

	print("Resume Finished")

	resume_finished.emit()


func can_play() -> bool:
	return !is_resuming
