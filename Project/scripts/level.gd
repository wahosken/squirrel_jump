extends Node2D

# --- CONFIG ---
const SECTION_WIDTH = 1024
const SECTION_HEIGHT = 2016
const LOOP_BUFFER = 200

# --- NODES ---
@onready var player: CharacterBody2D = $"../player"
@onready var nut_counter_label: Label = $"../UI/NutCounterLabel"

# --- DATA ---
var rows: Array = []          # Rows of sections
var columns: Array = []       # Columns of sections
var current_row: int = -1
var nuts_collected: int = 0

# --- READY ---
func _ready():
	_setup_rows_and_columns()
	_initialize_column_positions()
	update_section_visibility()
	_connect_nuts()

# --- NUTS ---
func _connect_nuts():
	for nut in get_tree().get_nodes_in_group("nuts"):
		var callback = Callable(self, "_on_nut_collected")
		if not nut.is_connected("collected", callback):
			nut.connect("collected", callback)

func _on_nut_collected(_nut):
	nuts_collected += 1
	nut_counter_label.text = "Nuts: %d" % nuts_collected

# --- PROCESS ---
func _process(_delta):
	update_vertical_sections()
	update_horizontal_loop()
	

# --- SETUP ROWS & COLUMNS ---
func _setup_rows_and_columns():
	# Build rows
	for row_node in get_children():
		rows.append(row_node.get_children())

	# Build columns
	var col_count = rows[0].size()
	for i in range(col_count):
		var column = []
		for r in rows:
			column.append(r[i])
		columns.append(column)

func _initialize_column_positions():
	for i in range(columns.size()):
		for section in columns[i]:
			section.global_position.x = i * SECTION_WIDTH

# --- HORIZONTAL LOOP ---
func rotate_right():
	if columns.size() < 2:
		return

	var first = columns.pop_front()
	columns.append(first)

	var rightmost = columns[columns.size() - 2]
	for i in range(first.size()):
		first[i].global_position.x = rightmost[i].global_position.x + SECTION_WIDTH

	call_deferred("update_section_visibility")

func rotate_left():
	if columns.size() < 2:
		return

	var last = columns.pop_back()
	columns.insert(0, last)

	var leftmost = columns[1]
	for i in range(last.size()):
		last[i].global_position.x = leftmost[i].global_position.x - SECTION_WIDTH

	call_deferred("update_section_visibility")

# --- VISIBILITY ---
func update_section_visibility():
	if columns.size() == 0:
		return

	var middle_index = int(columns.size() / 2)

	for c in range(columns.size()):
		var column_visible = abs(c - middle_index) <= 1

		for r in range(rows.size()):
			var section = columns[c][r]

			var row_visible = (r == current_row or r == current_row - 1)

			section.visible = column_visible and row_visible

# --- VERTICAL ROW ACTIVATION ---
func set_section_active(section: Node2D, active: bool):
	section.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED

func get_player_row() -> int:
	return int((-player.global_position.y + SECTION_HEIGHT / 2) / SECTION_HEIGHT)

func update_vertical_sections():
	var player_row = clamp(get_player_row(), 0, rows.size() - 1)

	if player_row == current_row:
		return

	current_row = player_row

	for i in range(rows.size()):
		var active = (i == player_row)
		for section in rows[i]:
			set_section_active(section, active)

	update_section_visibility()


# --- HORIZONTAL LOOP CHECK ---
func update_horizontal_loop():
	if columns.size() < 2:
		return

	var safe_row = clamp(current_row, 0, rows.size() - 1)
	var middle_index = int(columns.size() / 2)
	var middle = columns[middle_index][safe_row]

	if player.global_position.x > middle.global_position.x + SECTION_WIDTH + LOOP_BUFFER:
		rotate_right()
		print("rotate right")
		print_column_layout()
	elif player.global_position.x < middle.global_position.x - LOOP_BUFFER:
		rotate_left()
		print("rotate left")
		print_column_layout()

# --- DEBUG LAYOUT ---
func print_column_layout():
	print("---- COLUMN LAYOUT ----")
	for r in range(rows.size()):
		var row_names = []
		for c in range(columns.size()):
			row_names.append(columns[c][r].name)
		print(row_names)
	print("-----------------------")
