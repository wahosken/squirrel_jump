extends Node

signal resume_started
signal resume_finished
signal world_frozen_changed(frozen: bool)

var is_resuming := false
var should_resume := false

var world_frozen := false

var resume_duration := 1.5

const RESUME_TIME_SCALE := 0.15
const FREEZE_TIME := 0.25


func start_resume_sequence() -> void:

	print("SHOULD RESUME:", should_resume)

	if !should_resume:
		print("RESUME CANCELLED")
		return

	print("RESUME STARTING")

	if is_resuming:
		return

	is_resuming = true

	# Completely freeze world
	world_frozen = true
	world_frozen_changed.emit(true)

	Engine.time_scale = 0.0

	print("Resume Started")

	resume_started.emit()

	# Brief frozen moment
	await get_tree().create_timer(
		FREEZE_TIME,
		true,
		false,
		true
	).timeout

	# World wakes up in slow motion
	world_frozen = false
	world_frozen_changed.emit(false)

	Engine.time_scale = RESUME_TIME_SCALE

	# Ramp to normal speed

	var ramp_duration := resume_duration - FREEZE_TIME
	var steps := 30

	for i in range(steps):

		var t := float(i + 1) / float(steps)

		Engine.time_scale = lerp(
			RESUME_TIME_SCALE,
			1.0,
			t
		)

		await get_tree().create_timer(
			ramp_duration / steps,
			true,
			false,
			true
		).timeout

	Engine.time_scale = 1.0

	is_resuming = false

	should_resume = false

	print("Resume Finished")

	resume_finished.emit()


func can_play() -> bool:
	return !is_resuming


func is_world_frozen() -> bool:
	return world_frozen


func clear_resume() -> void:
	should_resume = false
