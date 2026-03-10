extends Node2D

@onready var ambient_sound: AudioStreamPlayer = $AmbientSound

func _ready():
	ambient_sound.volume_db = -40
	ambient_sound.play()
	var tween = create_tween()
	tween.tween_property(ambient_sound, "volume_db", -18, 3.0)
