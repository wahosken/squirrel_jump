extends Node

signal nuts_changed(new_amount: int)
signal inventory_changed
signal cosmetic_equipped(item_id: String)
signal squirrel_color_equipped(color_id: String)
signal menu_state_changed(is_open: bool)
signal mute_changed(is_muted: bool)
signal camera_zoom_settings_changed

var nuts: int = 15

var is_muted := false
var previous_volume := 100.0

var menu_open := false
var active_menu_id := ""
var menu_open_cooldown := false

var owned_cosmetics: Dictionary = {}
var equipped_cosmetic: String = ""
var equipped_squirrel_color: String = "squirrel"

var invert_camera_zoom := false
var toggle_camera_zoom := false


func save_to_save() -> void:
	SaveManager.save_data["nuts"] = nuts

	SaveManager.save_data["owned_cosmetics"] = owned_cosmetics

	SaveManager.save_data["equipped_cosmetic"] = equipped_cosmetic

	SaveManager.save_data["equipped_squirrel_color"] = equipped_squirrel_color


func load_from_save() -> void:
	nuts = SaveManager.save_data.get("nuts", 0)

	owned_cosmetics = SaveManager.save_data.get(
		"owned_cosmetics",
		{}
	)

	equipped_cosmetic = SaveManager.save_data.get(
		"equipped_cosmetic",
		""
	)

	equipped_squirrel_color = SaveManager.save_data.get(
		"equipped_squirrel_color",
		"squirrel"
	)

	nuts_changed.emit(nuts)
	inventory_changed.emit()

	cosmetic_equipped.emit(equipped_cosmetic)
	squirrel_color_equipped.emit(equipped_squirrel_color)


func add_nuts(amount: int) -> void:
	nuts += amount

	SaveManager.save_game()

	nuts_changed.emit(nuts)


func spend_nuts(amount: int) -> bool:
	if nuts < amount:
		return false

	nuts -= amount

	SaveManager.save_game()

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
	SaveManager.save_game()
	inventory_changed.emit()
	return true


func equip_cosmetic(item_id: String) -> bool:
	if item_id == "":
		equipped_cosmetic = ""
		cosmetic_equipped.emit(item_id)
		return true

	if not owns_cosmetic(item_id):
		return false

	equipped_cosmetic = item_id
	cosmetic_equipped.emit(item_id)
	SaveManager.save_game()
	return true


func equip_squirrel_color(color_id: String) -> void:
	equipped_squirrel_color = color_id
	squirrel_color_equipped.emit(color_id)
	SaveManager.save_game()


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


func set_muted(value: bool) -> void:
	is_muted = value
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), is_muted)
	mute_changed.emit(is_muted)


func toggle_mute() -> void:
	set_muted(not is_muted)


func set_invert_camera_zoom(value: bool) -> void:
	invert_camera_zoom = value
	camera_zoom_settings_changed.emit()

func set_toggle_camera_zoom(value: bool) -> void:
	toggle_camera_zoom = value
	camera_zoom_settings_changed.emit()
