extends CanvasLayer

signal menu_closed

@onready var nuts_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/NutsLabel

@onready var color_dropdown_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ColorDropdownButton
@onready var color_options_container: GridContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ColorOptionsContainer


@onready var cosmetic_dropdown_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/CosmeticDropdownButton
@onready var cosmetic_options_menu: VBoxContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/CosmeticOptionsContainer

@onready var default_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/CosmeticOptionsContainer/DefaultButton
@onready var acorn_cap_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/CosmeticOptionsContainer/AcornCapButton
@onready var baseball_cap_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/CosmeticOptionsContainer/BaseballCapButton
@onready var super_squirrel_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/CosmeticOptionsContainer/SuperSquirrelButton

@onready var fullscreen_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/FullscreenButton
@onready var mute_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/MuteButton
@onready var volume_container: HBoxContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/VolumeContainer
@onready var volume_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/VolumeContainer/VolumeLabel
@onready var volume_slider: HSlider = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/VolumeContainer/VolumeSlider


@onready var invert_camera_zoom_button: CheckButton = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/InvertCameraZoomCheckButton
@onready var toggle_camera_zoom_button: CheckButton = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/ToggleCameraZoomCheckButton

@onready var resume_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ResumeButton

var is_closing := false
var color_dropdown_open := false
var cosmetic_dropdown_open := false

var master_bus_index: int
var previous_volume := 100.0
var mute_toggle_locked := false
var is_initializing_ui := false

const SQUIRREL_ID := "squirrel"
const SQUIRREL_WHITE_ID := "squirrel_white"
const SQUIRREL_GOLD_ID := "squirrel_gold"
const SQUIRREL_SKELETON_ID := "squirrel_skeleton"

const NO_APPAREL_ID := ""
const ACORN_CAP_ID := "acorn_cap"
const BASEBALL_CAP_ID := "baseball_cap"
const SUPER_SQUIRREL_ID := "super_squirrel"

var color_buttons: Dictionary = {}


func build_color_buttons() -> void:

	color_buttons.clear()

	for child in color_options_container.get_children():
		child.queue_free()

	for appearance_id in AppearanceDatabase.APPEARANCES.keys():

		var appearance: Dictionary = AppearanceDatabase.APPEARANCES[appearance_id]

		var button := Button.new()

		button.text = appearance["display_name"]

		button.add_theme_font_size_override(
			"font_size",
			12
		)

		var id: String = appearance_id

		button.pressed.connect(
			func():
				select_squirrel_color(id)
		)

		color_options_container.add_child(button)

		color_buttons[id] = button


func _ready() -> void:
	
	invert_camera_zoom_button.button_pressed = GameState.invert_camera_zoom
	toggle_camera_zoom_button.button_pressed = GameState.toggle_camera_zoom

	invert_camera_zoom_button.toggled.connect(_on_invert_camera_zoom_toggled)
	toggle_camera_zoom_button.toggled.connect(_on_toggle_camera_zoom_toggled)
	
	is_initializing_ui = true

	build_color_buttons()

	color_dropdown_button.pressed.connect(toggle_color_dropdown)
	cosmetic_dropdown_button.pressed.connect(toggle_cosmetic_dropdown)

	master_bus_index = AudioServer.get_bus_index("Master")

	default_button.pressed.connect(func(): select_cosmetic(NO_APPAREL_ID))
	acorn_cap_button.pressed.connect(func(): select_cosmetic(ACORN_CAP_ID))
	baseball_cap_button.pressed.connect(func(): select_cosmetic(BASEBALL_CAP_ID))
	super_squirrel_button.pressed.connect(func(): select_cosmetic(SUPER_SQUIRREL_ID))

	mute_button.pressed.connect(_on_mute_pressed)

	if not GameState.mute_changed.is_connected(_on_mute_changed):
		GameState.mute_changed.connect(_on_mute_changed)

	fullscreen_button.pressed.connect(_on_fullscreen_button_pressed)
	volume_slider.value_changed.connect(_on_volume_slider_value_changed)

	resume_button.pressed.connect(close_menu)

	color_options_container.hide()
	cosmetic_options_menu.hide()

	volume_slider.value = db_to_linear(AudioServer.get_bus_volume_db(master_bus_index)) * 100.0

	_update_volume_ui()
	_update_fullscreen_button_text()
	update_inventory_display()

	cosmetic_dropdown_button.grab_focus()

	is_initializing_ui = false


func _on_mute_pressed() -> void:
	if GameState.is_muted:
		GameState.set_muted(false)

		var restore_volume: float = GameState.previous_volume
		if restore_volume <= 0.0:
			restore_volume = 100.0

		volume_slider.value = restore_volume
	else:
		GameState.previous_volume = volume_slider.value
		GameState.set_muted(true)
		volume_slider.value = 0.0

	_update_volume_ui()


func _on_mute_changed(is_muted: bool) -> void:
	if is_muted:
		volume_slider.value = 0.0
	else:
		var restore_volume: float = GameState.previous_volume
		if restore_volume <= 0.0:
			restore_volume = 100.0

		volume_slider.value = restore_volume

	_update_volume_ui()


func update_mute_button() -> void:
	_update_volume_ui()


func _on_volume_slider_value_changed(value: float) -> void:
	if is_initializing_ui:
		return

	if value <= 0.0:
		AudioServer.set_bus_volume_db(master_bus_index, linear_to_db(0.001))
		GameState.set_muted(true)
	else:
		AudioServer.set_bus_volume_db(master_bus_index, linear_to_db(value / 100.0))
		GameState.previous_volume = value

		if GameState.is_muted:
			GameState.set_muted(false)

	_update_volume_ui()


func _update_volume_ui() -> void:
	if GameState.is_muted:
		mute_button.text = "Unmute"
		volume_label.text = "Volume: 0%"
	else:
		mute_button.text = "Mute"
		volume_label.text = "Volume: " + str(roundi(volume_slider.value)) + "%"


func _unhandled_input(event: InputEvent) -> void:
	if is_closing:
		return

	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		if color_dropdown_open or cosmetic_dropdown_open:
			close_all_dropdowns()
		else:
			close_menu()

		get_viewport().set_input_as_handled()
		return


func toggle_color_dropdown() -> void:
	if color_dropdown_open:
		close_color_dropdown()
	else:
		open_color_dropdown()


func open_color_dropdown() -> void:
	color_dropdown_open = true
	cosmetic_dropdown_open = false

	color_dropdown_button.hide()
	color_options_container.show()

	cosmetic_options_menu.hide()
	cosmetic_dropdown_button.show()

	update_inventory_display()

	await get_tree().process_frame

	if color_buttons.has(GameState.equipped_squirrel_color):
		color_buttons[GameState.equipped_squirrel_color].grab_focus()
	elif color_options_container.get_child_count() > 0:
		color_options_container.get_child(0).grab_focus()


func close_color_dropdown() -> void:
	color_dropdown_open = false

	color_options_container.hide()
	color_dropdown_button.show()
	color_dropdown_button.grab_focus()


func toggle_cosmetic_dropdown() -> void:
	if cosmetic_dropdown_open:
		close_cosmetic_dropdown()
	else:
		open_cosmetic_dropdown()


func open_cosmetic_dropdown() -> void:
	cosmetic_dropdown_open = true
	color_dropdown_open = false

	cosmetic_dropdown_button.hide()
	cosmetic_options_menu.show()

	color_options_container.hide()
	color_dropdown_button.show()

	update_inventory_display()

	match GameState.equipped_cosmetic:
		ACORN_CAP_ID, "acorn_cap":
			if not acorn_cap_button.disabled:
				acorn_cap_button.grab_focus()
			else:
				default_button.grab_focus()

		BASEBALL_CAP_ID, "baseball_cap":
			if not baseball_cap_button.disabled:
				baseball_cap_button.grab_focus()
			else:
				default_button.grab_focus()

		SUPER_SQUIRREL_ID, "super_squirrel":
			if not super_squirrel_button.disabled:
				super_squirrel_button.grab_focus()
			else:
				default_button.grab_focus()

		_:
			default_button.grab_focus()


func close_cosmetic_dropdown() -> void:
	cosmetic_dropdown_open = false

	cosmetic_options_menu.hide()
	cosmetic_dropdown_button.show()
	cosmetic_dropdown_button.grab_focus()


func close_all_dropdowns() -> void:
	if color_dropdown_open:
		close_color_dropdown()

	if cosmetic_dropdown_open:
		close_cosmetic_dropdown()


func select_squirrel_color(color_id: String) -> void:
	GameState.equip_squirrel_color(color_id)

	update_inventory_display()
	close_color_dropdown()


func select_cosmetic(item_id: String) -> void:
	if item_id != "" and not GameState.owns_cosmetic(item_id):
		return

	if item_id == NO_APPAREL_ID:
		GameState.equipped_cosmetic = NO_APPAREL_ID
		GameState.cosmetic_equipped.emit(NO_APPAREL_ID)
	else:
		GameState.equip_cosmetic(item_id)

	update_inventory_display()
	close_cosmetic_dropdown()


func update_inventory_display() -> void:
	nuts_label.text = "Nuts: %d" % GameState.nuts

	var appearance: Dictionary = AppearanceDatabase.APPEARANCES.get(
		GameState.equipped_squirrel_color
	)

	if appearance:
		color_dropdown_button.text = (
			"Squirrel: " + appearance["display_name"]
		)
	else:
		color_dropdown_button.text = "Squirrel: Brown"


	match GameState.equipped_cosmetic:
		ACORN_CAP_ID:
			cosmetic_dropdown_button.text = "Apparel: Acorn Cap"

		BASEBALL_CAP_ID:
			cosmetic_dropdown_button.text = "Apparel: Baseball Cap"

		SUPER_SQUIRREL_ID:
			cosmetic_dropdown_button.text = "Apparel: Super Squirrel"

		_:
			cosmetic_dropdown_button.text = "Apparel: None"

	default_button.text = "None"
	default_button.disabled = false

	if GameState.owns_cosmetic(ACORN_CAP_ID):
		acorn_cap_button.text = "Acorn Cap"
		acorn_cap_button.disabled = false
	else:
		acorn_cap_button.text = "Acorn Cap (Locked)"
		acorn_cap_button.disabled = true

	if GameState.owns_cosmetic(BASEBALL_CAP_ID):
		baseball_cap_button.text = "Baseball Cap"
		baseball_cap_button.disabled = false
	else:
		baseball_cap_button.text = "Baseball Cap (Locked)"
		baseball_cap_button.disabled = true

	if GameState.owns_cosmetic(SUPER_SQUIRREL_ID):
		super_squirrel_button.text = "Super Squirrel"
		super_squirrel_button.disabled = false
	else:
		super_squirrel_button.text = "Super Squirrel (Locked)"
		super_squirrel_button.disabled = true

func _on_fullscreen_button_pressed() -> void:
	var current_mode = DisplayServer.window_get_mode()

	if current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

	_update_fullscreen_button_text()


func _update_fullscreen_button_text() -> void:
	fullscreen_button.text = "Toggle Fullscreen"


func close_menu() -> void:
	if is_closing:
		return

	is_closing = true
	menu_closed.emit()
	queue_free()


func _on_invert_camera_zoom_toggled(value: bool) -> void:
	GameState.set_invert_camera_zoom(value)


func _on_toggle_camera_zoom_toggled(value: bool) -> void:
	GameState.set_toggle_camera_zoom(value)


func _on_return_to_title_button_pressed() -> void:
	SaveManager.save_current_player()

	menu_closed.emit()

	get_tree().change_scene_to_file("res://scenes/ui/title_screen.tscn")
