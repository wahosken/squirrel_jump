extends CanvasLayer

signal menu_closed

@onready var nuts_label: Label = $Panel/VBoxContainer/NutsLabel
@onready var acorn_cap_button: Button = $Panel/VBoxContainer/AcornCapButton
@onready var resume_button: Button = $Panel/VBoxContainer/ResumeButton

var is_closing := false
var item_id := "acorn_cap"
var item_name := "Acorn Cap"


func _ready() -> void:
	acorn_cap_button.pressed.connect(_on_acorn_cap_pressed)
	resume_button.pressed.connect(close_menu)

	update_inventory_display()

	if acorn_cap_button.disabled:
		resume_button.grab_focus()
	else:
		acorn_cap_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if is_closing:
		return

	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		close_menu()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_accept"):
		activate_focused_button()
		get_viewport().set_input_as_handled()
		return


func activate_focused_button() -> void:
	var focused := get_viewport().gui_get_focus_owner()

	if focused is Button:
		focused.emit_signal("pressed")


func update_inventory_display() -> void:
	nuts_label.text = "Nuts: %d" % GameState.nuts

	if GameState.owns_cosmetic(item_id):
		if GameState.equipped_cosmetic == item_id:
			acorn_cap_button.text = "%s Equipped" % item_name
			acorn_cap_button.disabled = true
		else:
			acorn_cap_button.text = "Equip %s" % item_name
			acorn_cap_button.disabled = false
	else:
		acorn_cap_button.text = "%s Not Owned" % item_name
		acorn_cap_button.disabled = true


func _on_acorn_cap_pressed() -> void:
	if GameState.equip_cosmetic(item_id):
		update_inventory_display()


func close_menu() -> void:
	if is_closing:
		return

	is_closing = true
	menu_closed.emit()
	queue_free()

func set_player_input_enabled(enabled: bool) -> void:
	var players := get_tree().get_nodes_in_group("player")

	if players.size() == 0:
		push_warning("No player found in group 'player'.")
		return

	var target_player = players[0]

	if target_player.has_method("set_input_enabled"):
		target_player.set_input_enabled(enabled)
	else:
		push_warning("Player does not have set_input_enabled().")
		
