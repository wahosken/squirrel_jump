extends Node2D
class_name Game

signal game_state_changed(new_state)

enum GameState {
	RESUMING,
	PLAYING
}

var current_state := GameState.RESUMING

var resume_progress := 0.0


func _ready():
	ResumeManager.resume_started.connect(_on_resume_started)
	ResumeManager.resume_finished.connect(_on_resume_finished)

	ResumeManager.start_resume_sequence()


func _on_resume_started():
	current_state = GameState.RESUMING

	game_state_changed.emit(current_state)

	print("Game entering resume state")


func _on_resume_finished():
	current_state = GameState.PLAYING

	game_state_changed.emit(current_state)

	print("Game entering gameplay state")

func is_playing() -> bool:
	return current_state == GameState.PLAYING
