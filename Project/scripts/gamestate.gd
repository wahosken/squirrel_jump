extends Node

signal nuts_changed(new_amount: int)
signal inventory_changed
signal cosmetic_equipped(item_id: String)
signal menu_state_changed(is_open: bool)

var nuts: int = 35

var menu_open := false
var active_menu_id := ""
var menu_open_cooldown := false

var owned_cosmetics: Dictionary = {}
var equipped_cosmetic: String = ""


func add_nuts(amount: int) -> void:
	nuts += amount
	nuts_changed.emit(nuts)


func spend_nuts(amount: int) -> bool:
	if nuts < amount:
		return false

	nuts -= amount
	nuts_changed.emit(nuts)
	return true


func owns_cosmetic(item_id: String) -> bool:
	return owned_cosmetics.has(item_id)


func buy_cosmetic(item_id: String, price: int) -> bool:
	if owns_cosmetic(item_id):
		return false

	if not spend_nuts(price):
		return false

	owned_cosmetics[item_id] = true
	inventory_changed.emit()
	return true


func equip_cosmetic(item_id: String) -> bool:
	if not owns_cosmetic(item_id):
		return false

	equipped_cosmetic = item_id
	cosmetic_equipped.emit(item_id)
	return true

func request_menu_open(menu_id: String) -> bool:
	if menu_open:
		return false

	if menu_open_cooldown:
		return false

	menu_open = true
	active_menu_id = menu_id
	menu_state_changed.emit(true)
	return true


func close_menu_state(menu_id: String = "") -> void:
	if menu_id != "" and active_menu_id != "" and menu_id != active_menu_id:
		return

	menu_open = false
	active_menu_id = ""

	menu_open_cooldown = true

	menu_state_changed.emit(false)

func _process(_delta: float) -> void:
	if not menu_open_cooldown:
		return

	# Wait until all menu-opening/selecting buttons are released.
	var any_menu_button_held := false

	var actions := [
		"pause",
		"ui_cancel",
		"interact",
		"ui_accept"
	]

	for action in actions:
		if InputMap.has_action(action) and Input.is_action_pressed(action):
			any_menu_button_held = true
			break

	if not any_menu_button_held:
		menu_open_cooldown = false
