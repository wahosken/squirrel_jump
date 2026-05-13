extends CanvasLayer

signal menu_closed

@onready var nuts_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/NutsLabel

@onready var cosmetic_dropdown_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/CosmeticDropdownButton
@onready var cosmetic_options_container: VBoxContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/CosmeticOptionsContainer

@onready var default_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/CosmeticOptionsContainer/DefaultButton
@onready var acorn_cap_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/CosmeticOptionsContainer/AcornCapButton
@onready var super_squirrel_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/CosmeticOptionsContainer/SuperSquirrelButton


@onready var fullscreen_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/FullscreenButton
@onready var mute_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/MuteButton
@onready var volume_container: HBoxContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/VolumeContainer
@onready var volume_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/VolumeContainer/VolumeLabel
@onready var volume_slider: HSlider = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/VolumeContainer/VolumeSlider

@onready var resume_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ResumeButton

var is_closing := false
var dropdown_open := false

var master_bus_index: int
var previous_volume := 100.0
var mute_toggle_locked := false

const DEFAULT_ID := ""
const ACORN_CAP_ID := "acorn_cap"
const SUPER_SQUIRREL_ID := "super_squirrel"


func _ready() -> void:
	cosmetic_dropdown_button.pressed.connect(toggle_cosmetic_dropdown)
	master_bus_index = AudioServer.get_bus_index("Master")

	default_button.pressed.connect(func(): select_cosmetic(DEFAULT_ID))
	acorn_cap_button.pressed.connect(func(): select_cosmetic(ACORN_CAP_ID))
	super_squirrel_button.pressed.connect(func(): select_cosmetic(SUPER_SQUIRREL_ID))
	
	fullscreen_button.pressed.connect(_on_fullscreen_button_pressed)
	mute_button.pressed.connect(_on_mute_button_pressed)
	volume_slider.value_changed.connect(_on_volume_slider_value_changed)

	resume_button.pressed.connect(close_menu)

	cosmetic_options_container.hide()

	volume_slider.value = 100
	_update_volume_ui()
	_update_fullscreen_button_text()
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


func toggle_cosmetic_dropdown() -> void:
	if dropdown_open:
		close_cosmetic_dropdown()
	else:
		open_cosmetic_dropdown()


func open_cosmetic_dropdown() -> void:
	dropdown_open = true

	cosmetic_dropdown_button.hide()
	cosmetic_options_container.show()

	update_inventory_display()

	match GameState.equipped_cosmetic:
		ACORN_CAP_ID:
			if not acorn_cap_button.disabled:
				acorn_cap_button.grab_focus()
			else:
				default_button.grab_focus()
		SUPER_SQUIRREL_ID:
			if not super_squirrel_button.disabled:
				super_squirrel_button.grab_focus()
			else:
				default_button.grab_focus()
		_:
			default_button.grab_focus()


func close_cosmetic_dropdown() -> void:
	dropdown_open = false

	cosmetic_options_container.hide()
	cosmetic_dropdown_button.show()
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
			cosmetic_dropdown_button.text = "Skin: Acorn Cap"
		SUPER_SQUIRREL_ID:
			cosmetic_dropdown_button.text = "Skin: Super Squirrel"
		_:
			cosmetic_dropdown_button.text = "Skin: Default"

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

func _on_fullscreen_button_pressed() -> void:
	var current_mode = DisplayServer.window_get_mode()

	if current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

	_update_fullscreen_button_text()


func _update_fullscreen_button_text() -> void:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		fullscreen_button.text = "Windowed"
	else:
		fullscreen_button.text = "Fullscreen"

func _on_mute_button_pressed() -> void:
	if mute_toggle_locked:
		return

	mute_toggle_locked = true

	var is_muted := AudioServer.is_bus_mute(master_bus_index)
	AudioServer.set_bus_mute(master_bus_index, !is_muted)

	if !is_muted:
		previous_volume = volume_slider.value
		volume_slider.value = 0
	else:
		volume_slider.value = previous_volume if previous_volume > 0.0 else 100.0

	_update_volume_ui()

	await get_tree().create_timer(0.15).timeout
	mute_toggle_locked = false

func _on_volume_slider_value_changed(value: float) -> void:
	if value <= 0:
		AudioServer.set_bus_volume_db(master_bus_index, linear_to_db(0.001))
	else:
		AudioServer.set_bus_mute(master_bus_index, false)
		AudioServer.set_bus_volume_db(master_bus_index, linear_to_db(value / 100.0))
		previous_volume = value

	_update_volume_ui()

func _update_volume_ui() -> void:
	var is_muted = AudioServer.is_bus_mute(master_bus_index)

	if is_muted:
		mute_button.text = "Unmute"
		volume_label.text = "Volume: 0%"
	else:
		mute_button.text = "Mute"
		volume_label.text = "Volume: " + str(roundi(volume_slider.value)) + "%"

func close_menu() -> void:
	if is_closing:
		return

	is_closing = true
	menu_closed.emit()
	queue_free()
