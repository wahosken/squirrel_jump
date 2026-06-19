extends CanvasLayer

@onready var color_rect: ColorRect = $CenterContainer/ColorRect
@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready():

	visible = false

	# Start transparent
	var color := color_rect.modulate
	color.a = 0.0
	color_rect.modulate = color

	if not ResumeManager.resume_started.is_connected(_on_resume_started):
		ResumeManager.resume_started.connect(_on_resume_started)

	if not ResumeManager.resume_finished.is_connected(_on_resume_finished):
		ResumeManager.resume_finished.connect(_on_resume_finished)


func _on_resume_started():

	visible = true

	animation_player.play("resume_fade")


func _on_resume_finished():

	visible = false


func _on_animation_player_animation_finished(anim_name):

	if anim_name == "resume_fade":

		if not ResumeManager.is_resuming:
			visible = false
