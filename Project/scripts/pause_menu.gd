extends CanvasLayer

signal menu_closed

@onready var nuts_label: Label = $Panel/VBoxContainer/NutsLabel
@onready var cosmetic_option_button: OptionButton = $Panel/VBoxContainer/CosmeticOptionButton
@onready var resume_button: Button = $Panel/VBoxContainer/ResumeButton

var is_closing := false
var is_rebuilding_dropdown := false

var cosmetic_options := [
	{
		"id": "",
		"name": "Default",
		"owned": true
	},
	{
		"id": "acorn_cap",
		"name": "Acorn Cap",
		"owned": false
	},
	{
		"id": "super_squirrel",
		"name": "Super Squirrel",
		"owned": false
	}
]


func _ready() -> void:
	cosmetic_option_button.item_selected.connect(_on_cosmetic_selected)
	resume_button.pressed.connect(close_menu)

	update_inventory_display()
	cosmetic_option_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if is_closing:
		return

	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		close_menu()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_accept"):
		activate_focused_control()
		get_viewport().set_input_as_handled()
		return


func activate_focused_control() -> void:
	var focused := get_viewport().gui_get_focus_owner()

	if focused is Button:
		focused.emit_signal("pressed")
	elif focused is OptionButton:
		focused.show_popup()


func update_inventory_display() -> void:
	nuts_label.text = "Nuts: %d" % GameState.nuts
	rebuild_cosmetic_dropdown()


func rebuild_cosmetic_dropdown() -> void:
	is_rebuilding_dropdown = true

	cosmetic_option_button.clear()

	for option in cosmetic_options:
		var item_id: String = str(option["id"])
		var item_name: String = str(option["name"])

		var owned: bool = option.get("owned", false) as bool

		if GameState.owns_cosmetic(item_id):
			owned = true

		var display_name := item_name

		if not owned:
			display_name += " (Locked)"

		cosmetic_option_button.add_item(display_name)
		cosmetic_option_button.set_item_metadata(cosmetic_option_button.item_count - 1, item_id)

	select_equipped_cosmetic()

	is_rebuilding_dropdown = false


func select_equipped_cosmetic() -> void:
	for i in range(cosmetic_option_button.item_count):
		var item_id := str(cosmetic_option_button.get_item_metadata(i))

		if item_id == GameState.equipped_cosmetic:
			cosmetic_option_button.select(i)
			return

	cosmetic_option_button.select(0)


func _on_cosmetic_selected(index: int) -> void:
	if is_rebuilding_dropdown:
		return

	var selected_id := str(cosmetic_option_button.get_item_metadata(index))

	if selected_id != "" and not GameState.owns_cosmetic(selected_id):
		select_equipped_cosmetic()
		return

	if selected_id == "":
		GameState.equipped_cosmetic = ""
		GameState.cosmetic_equipped.emit("")
	else:
		GameState.equip_cosmetic(selected_id)

	update_inventory_display()


func close_menu() -> void:
	if is_closing:
		return

	is_closing = true
	menu_closed.emit()
	queue_free()
