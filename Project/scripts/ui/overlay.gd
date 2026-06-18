extends CanvasLayer

@onready var nut_counter_label := $NutCounterLabel


func _ready():

	GameState.nuts_changed.connect(
		_on_nuts_changed
	)

	_on_nuts_changed(
		GameState.nuts
	)


func _on_nuts_changed(
	new_amount: int
) -> void:

	nut_counter_label.text = (
		"Nuts: %d" % new_amount
	)
