extends CanvasLayer

signal menu_closed

@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var nuts_label: Label = $Panel/VBoxContainer/NutsLabel
@onready var item_button: Button = $Panel/VBoxContainer/ItemButton
@onready var close_button: Button = $Panel/VBoxContainer/CloseButton

var is_closing := false

var item_id := "acorn_cap"
var item_name := "Acorn Cap"
var item_price := 10


func _ready() -> void:
	item_button.pressed.connect(_on_item_button_pressed)
	close_button.pressed.connect(close_menu)

	GameState.nuts_changed.connect(_on_nuts_changed)
	GameState.inventory_changed.connect(update_shop_display)

	item_button.grab_focus()
	update_shop_display()


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


func _on_item_button_pressed() -> void:
	if GameState.owns_cosmetic(item_id):
		item_button.text = "%s Owned" % item_name
		return

	var bought := GameState.buy_cosmetic(item_id, item_price)

	if bought:
		item_button.text = "Item Purchased"
		item_button.disabled = true
		close_button.grab_focus()
	else:
		item_button.text = "Not Enough Nuts"

	await get_tree().create_timer(0.8).timeout

	if not is_closing:
		update_shop_display()


func _on_nuts_changed(_new_amount: int) -> void:
	update_shop_display()


func update_shop_display() -> void:
	nuts_label.text = "Nuts: %d" % GameState.nuts

	if GameState.owns_cosmetic(item_id):
		item_button.text = "%s Owned" % item_name
		item_button.disabled = true
		close_button.grab_focus()
	else:
		item_button.text = "Buy %s - %d Nuts" % [item_name, item_price]
		item_button.disabled = GameState.nuts < item_price

		if item_button.disabled:
			close_button.grab_focus()
		else:
			item_button.grab_focus()


func close_menu() -> void:
	if is_closing:
		return

	is_closing = true
	menu_closed.emit()
	queue_free()
