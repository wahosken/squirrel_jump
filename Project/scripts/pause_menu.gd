extends CanvasLayer

signal menu_closed

@onready var nuts_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/NutsLabel

@onready var cosmetic_dropdown_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/CosmeticDropdownButton
@onready var cosmetic_options_container: VBoxContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/CosmeticOptionsContainer

@onready var default_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/CosmeticOptionsContainer/DefaultButton
@onready var acorn_cap_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/CosmeticOptionsContainer/AcornCapButton
@onready var super_squirrel_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/CosmeticOptionsContainer/SuperSquirrelButton

@onready var resume_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ResumeButton

var is_closing := false
var dropdown_open := false

const DEFAULT_ID := ""
const ACORN_CAP_ID := "acorn_cap"
const SUPER_SQUIRREL_ID := "super_squirrel"


func _ready() -> void:
	cosmetic_dropdown_button.pressed.connect(toggle_cosmetic_dropdown)

	default_button.pressed.connect(func(): select_cosmetic(DEFAULT_ID))
	acorn_cap_button.pressed.connect(func(): select_cosmetic(ACORN_CAP_ID))
	super_squirrel_button.pressed.connect(func(): select_cosmetic(SUPER_SQUIRREL_ID))

	resume_button.pressed.connect(close_menu)

	cosmetic_options_container.hide()

	update_inventory_display()
	cosmetic_dropdown_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if is_closing:
		return

	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		if dropdown_open:
			close_cosmetic_dropdown()
		else:
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


func toggle_cosmetic_dropdown() -> void:
	if dropdown_open:
		close_cosmetic_dropdown()
	else:
		open_cosmetic_dropdown()


func open_cosmetic_dropdown() -> void:
	dropdown_open = true
	cosmetic_options_container.show()
	update_inventory_display()

	match GameState.equipped_cosmetic:
		ACORN_CAP_ID:
			acorn_cap_button.grab_focus()
		SUPER_SQUIRREL_ID:
			super_squirrel_button.grab_focus()
		_:
			default_button.grab_focus()


func close_cosmetic_dropdown() -> void:
	dropdown_open = false
	cosmetic_options_container.hide()
	cosmetic_dropdown_button.grab_focus()


func select_cosmetic(item_id: String) -> void:
	if item_id != "" and not GameState.owns_cosmetic(item_id):
		return

	if item_id == DEFAULT_ID:
		GameState.equipped_cosmetic = DEFAULT_ID
		GameState.cosmetic_equipped.emit(DEFAULT_ID)
	else:
		GameState.equip_cosmetic(item_id)

	update_inventory_display()
	close_cosmetic_dropdown()


func update_inventory_display() -> void:
	nuts_label.text = "Nuts: %d" % GameState.nuts

	match GameState.equipped_cosmetic:
		ACORN_CAP_ID:
			cosmetic_dropdown_button.text = "Cosmetic: Acorn Cap"
		SUPER_SQUIRREL_ID:
			cosmetic_dropdown_button.text = "Cosmetic: Super Squirrel"
		_:
			cosmetic_dropdown_button.text = "Cosmetic: Default"

	default_button.text = "Default"
	default_button.disabled = false

	if GameState.owns_cosmetic(ACORN_CAP_ID):
		acorn_cap_button.text = "Acorn Cap"
		acorn_cap_button.disabled = false
	else:
		acorn_cap_button.text = "Acorn Cap (Locked)"
		acorn_cap_button.disabled = true

	if GameState.owns_cosmetic(SUPER_SQUIRREL_ID):
		super_squirrel_button.text = "Super Squirrel"
		super_squirrel_button.disabled = false
	else:
		super_squirrel_button.text = "Super Squirrel (Locked)"
		super_squirrel_button.disabled = true


func close_menu() -> void:
	if is_closing:
		return

	is_closing = true
	menu_closed.emit()
	queue_free()
