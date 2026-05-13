extends CanvasLayer

signal menu_closed

@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var nuts_label: Label = $Panel/VBoxContainer/NutsLabel
@onready var acorn_cap_button: Button = $Panel/VBoxContainer/ItemButton
@onready var super_squirrel_button: Button = $Panel/VBoxContainer/SuperSquirrelButton
@onready var close_button: Button = $Panel/VBoxContainer/CloseButton

var is_closing := false

var shop_items := {
	"acorn_cap": {
		"name": "Acorn Cap",
		"price": 10,
		"button": null
	},
	"super_squirrel": {
		"name": "Super Squirrel",
		"price": 25,
		"button": null
	}
}


func _ready() -> void:
	shop_items["acorn_cap"]["button"] = acorn_cap_button
	shop_items["super_squirrel"]["button"] = super_squirrel_button

	acorn_cap_button.pressed.connect(func(): _on_shop_item_pressed("acorn_cap"))
	super_squirrel_button.pressed.connect(func(): _on_shop_item_pressed("super_squirrel"))
	close_button.pressed.connect(close_menu)

	GameState.nuts_changed.connect(_on_nuts_changed)
	GameState.inventory_changed.connect(update_shop_display)

	update_shop_display()
	grab_best_focus()


func setup(npc_name: String) -> void:
	title_label.text = npc_name


func _unhandled_input(event: InputEvent) -> void:
	if is_closing:
		return

	if event.is_action_pressed("ui_cancel"):
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


func _on_shop_item_pressed(item_id: String) -> void:
	if GameState.owns_cosmetic(item_id):
		return

	var item: Dictionary = shop_items[item_id]
	var item_name: String = str(item["name"])
	var item_price: int = int(item["price"])
	var button: Button = item["button"]

	var bought := GameState.buy_cosmetic(item_id, item_price)

	if bought:
		button.text = "Item Purchased"
		button.disabled = true
		close_button.grab_focus()
	else:
		button.text = "Not Enough Nuts"

	await get_tree().create_timer(0.8).timeout

	if not is_closing:
		update_shop_display()
		grab_best_focus()


func _on_nuts_changed(_new_amount: int) -> void:
	update_shop_display()


func update_shop_display() -> void:
	nuts_label.text = "Nuts: %d" % GameState.nuts

	for item_id in shop_items.keys():
		var item: Dictionary = shop_items[item_id]
		var item_name: String = str(item["name"])
		var item_price: int = int(item["price"])
		var button: Button = item["button"]

		if GameState.owns_cosmetic(item_id):
			button.text = "%s Owned" % item_name
			button.disabled = true
		else:
			button.text = "Buy %s - %d Nuts" % [item_name, item_price]
			button.disabled = GameState.nuts < item_price


func grab_best_focus() -> void:
	for item_id in shop_items.keys():
		var button: Button = shop_items[item_id]["button"]

		if not button.disabled:
			button.grab_focus()
			return

	close_button.grab_focus()


func close_menu() -> void:
	if is_closing:
		return

	is_closing = true
	menu_closed.emit()
	queue_free()
