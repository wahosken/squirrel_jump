extends CanvasLayer

signal menu_closed

@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var item_button: Button = $Panel/VBoxContainer/ItemButton
@onready var close_button: Button = $Panel/VBoxContainer/CloseButton

var is_closing := false


func _ready() -> void:
	item_button.pressed.connect(_on_item_button_pressed)
	close_button.pressed.connect(close_menu)

	item_button.grab_focus()


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
	print("Placeholder item purchased or selected.")


func close_menu() -> void:
	if is_closing:
		return

	is_closing = true
	menu_closed.emit()
	queue_free()
