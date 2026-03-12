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
var debug_timer := 0.0

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
func _process(delta):
	update_vertical_sections()
	update_horizontal_loop()
	
	debug_timer += delta

	if debug_timer > 6.0:
		print_active_sections()
		print_active_nuts()
		debug_timer = 0
	

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
		var column_active = abs(c - middle_index) <= 1

		for r in range(rows.size()):
			var section = columns[c][r]

			var row_active = (r == current_row) or (r == current_row - 1)  # show current + previous row
			var active = column_active and row_active

			# Update section state
			set_section_active(section, active)
			section.visible = active

# --- VERTICAL ROW ACTIVATION ---
func set_section_active(section: Node, active: bool):

	section.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	section.set_physics_process(active)

	for child in section.get_children():
		if child.is_in_group("nuts"):
			child.visible = active
			child.set_physics_process(active)
			for c in child.get_children():
				if c is CollisionShape2D:
					c.disabled = not active
		# Any other collision objects
		elif child is CollisionObject2D:
			child.disabled = not active
	

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
	var layout := ""

	for c in range(columns.size()):
		var name = columns[c][0].name
		var letter = name.substr(name.length() - 1, 1)
		layout += "[" + letter + "]"

	print(layout)
	
func print_active_sections():
	var active_sections := 0

	for r in rows:
		for section in r:
			if section.process_mode != Node.PROCESS_MODE_DISABLED:
				active_sections += 1

	print("Active sections:", active_sections)
	
func print_active_nuts():
	var active_nuts := 0

	for nut in get_tree().get_nodes_in_group("nuts"):
		# nut must be visible
		if not nut.visible:
			continue

		# nut must be processing
		if nut.process_mode == Node.PROCESS_MODE_DISABLED:
			continue

		# nut must have at least one enabled CollisionShape2D
		var has_enabled_collision := false
		for child in nut.get_children():
			if child is CollisionShape2D and not child.disabled:
				has_enabled_collision = true
				break

		if has_enabled_collision:
			active_nuts += 1

	print("Active nuts:", active_nuts)
