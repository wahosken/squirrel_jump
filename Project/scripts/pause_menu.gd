extends CanvasLayer

signal menu_closed

@onready var nuts_label: Label = $Panel/VBoxContainer/NutsLabel
@onready var default_button: Button = $Panel/VBoxContainer/HBoxContainer/Default
@onready var acorn_cap_button: Button = $Panel/VBoxContainer/HBoxContainer/AcornCapButton
@onready var resume_button: Button = $Panel/VBoxContainer/ResumeButton

var is_closing := false

const DEFAULT_ID := ""
const ACORN_CAP_ID := "acorn_cap"


func _ready() -> void:
	default_button.pressed.connect(_on_default_pressed)
	acorn_cap_button.pressed.connect(_on_acorn_cap_pressed)
	resume_button.pressed.connect(close_menu)

	update_inventory_display()
	grab_best_focus()


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

	# Default skin is always available.
	if GameState.equipped_cosmetic == DEFAULT_ID:
		default_button.text = "Default\nEquipped"
		default_button.disabled = true
	else:
		default_button.text = "Equip\nDefault"
		default_button.disabled = false

	# Acorn Cap must be owned before it can be equipped.
	if GameState.owns_cosmetic(ACORN_CAP_ID):
		if GameState.equipped_cosmetic == ACORN_CAP_ID:
			acorn_cap_button.text = "Acorn Cap\nEquipped"
			acorn_cap_button.disabled = true
		else:
			acorn_cap_button.text = "Equip\nAcorn Cap"
			acorn_cap_button.disabled = false
	else:
		acorn_cap_button.text = "Acorn Cap\nNot Owned"
		acorn_cap_button.disabled = true


func grab_best_focus() -> void:
	if not default_button.disabled:
		default_button.grab_focus()
	elif not acorn_cap_button.disabled:
		acorn_cap_button.grab_focus()
	else:
		resume_button.grab_focus()


func _on_default_pressed() -> void:
	GameState.equipped_cosmetic = DEFAULT_ID
	GameState.cosmetic_equipped.emit(DEFAULT_ID)
	update_inventory_display()
	grab_best_focus()


func _on_acorn_cap_pressed() -> void:
	if GameState.equip_cosmetic(ACORN_CAP_ID):
		update_inventory_display()
		grab_best_focus()


func close_menu() -> void:
	if is_closing:
		return

	is_closing = true
	menu_closed.emit()
	queue_free()
