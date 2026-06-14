extends CanvasLayer

signal menu_closed

@onready var title_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TitleLabel
@onready var nuts_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/NutsLabel
@onready var shop_items_container: VBoxContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ShopItemsContainer
@onready var close_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/CloseButton

var button_message_active := {}
var is_closing := false

var purchased_this_session: Dictionary = {}

var shop_buttons: Dictionary = {}


func build_shop_buttons() -> void:
	shop_buttons.clear()

	for child in shop_items_container.get_children():
		child.queue_free()

	for item_id in ApparelDatabase.APPAREL.keys():

		if item_id == "default":
			continue

		var button := Button.new()

		button.add_theme_font_size_override("font_size", 12)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		button.pressed.connect(
			func():
				_on_shop_item_pressed(item_id)
		)

		shop_items_container.add_child(button)

		shop_buttons[item_id] = button


func _ready() -> void:

	build_shop_buttons()

	for item_id in shop_buttons.keys():
		button_message_active[item_id] = false

	close_button.pressed.connect(close_menu)

	GameState.nuts_changed.connect(_on_nuts_changed)
	GameState.inventory_changed.connect(_on_inventory_changed)

	update_shop_display()

	if shop_items_container.get_child_count() > 0:
		shop_items_container.get_child(0).grab_focus()


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
	if button_message_active.get(item_id, false):
		return

	var apparel: Dictionary = ApparelDatabase.APPAREL[item_id]
	var item_price: int = apparel["price"]

	var button: Button = shop_buttons[item_id]

	if GameState.owns_cosmetic(item_id):
		return

	if GameState.nuts < item_price:
		show_button_message(item_id, "Not Enough Nuts", 0.8)
		return

	var bought := GameState.buy_cosmetic(item_id, item_price)

	if bought:
		purchased_this_session[item_id] = true
		button.text = "Item Purchased"
		button.disabled = true


func show_button_message(item_id: String, message: String, duration: float = 0.8) -> void:
	var button: Button = shop_buttons[item_id]

	button_message_active[item_id] = true

	button.text = message
	button.disabled = true

	await get_tree().create_timer(duration).timeout

	button_message_active[item_id] = false

	if not is_closing:
		update_shop_display()


func _on_nuts_changed(_new_amount: int) -> void:
	update_shop_display()


func _on_inventory_changed() -> void:
	update_shop_display()


func update_shop_display() -> void:
	nuts_label.text = "Nuts: %d" % GameState.nuts

	for item_id in shop_buttons.keys():

		if button_message_active.get(item_id, false):
			continue

		var apparel: Dictionary = ApparelDatabase.APPAREL[item_id]

		var item_name: String = apparel["display_name"]
		var item_price: int = apparel["price"]

		var button: Button = shop_buttons[item_id]

		if purchased_this_session.has(item_id):
			button.text = "Item Purchased"
			button.disabled = true
		elif GameState.owns_cosmetic(item_id):
			button.text = "%s Owned" % item_name
			button.disabled = true
		else:
			button.text = "Buy %s - %d Nuts" % [item_name, item_price]
			button.disabled = false


func close_menu() -> void:
	if is_closing:
		return

	is_closing = true
	menu_closed.emit()
	queue_free()
