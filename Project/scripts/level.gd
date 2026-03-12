extends Node2D


const SECTION_WIDTH = 1024
const SECTION_HEIGHT = 2016
const ACTIVE_ROW_RANGE = 1

@onready var player: CharacterBody2D = $"../player"
@onready var section_1a: Node2D = $section_1a
@onready var section_1b: Node2D = $section_1b
@onready var section_1c: Node2D = $section_1c
@onready var section_1d: Node2D = $section_1d
@onready var section_1e: Node2D = $section_1e
@onready var section_2a: Node2D = $section_2a
@onready var section_2b: Node2D = $section_2b
@onready var section_2c: Node2D = $section_2c
@onready var section_2d: Node2D = $section_2d
@onready var section_2e: Node2D = $section_2e
@onready var nut_counter_label: Label = $"../UI/NutCounterLabel"


var sections = []
var rotation_cooldown = false
var nuts_collected: int = 0
var rows = []
var current_row := -1

func _ready():
	
	for nut in get_tree().get_nodes_in_group("nuts"):
		var callback = Callable(self, "_on_nut_collected")
		if not nut.is_connected("collected", callback):
			nut.connect("collected", callback)
	
	sections = [
		section_1d,
		section_1e,
		section_1a,
		section_1b,
		section_1c
	]
	
	rows = [
		[section_1d,
		section_1e,
		section_1a,
		section_1b,
		section_1c],
		[section_2d,
		section_2e, 
		section_2a, 
		section_2b,
		section_2c]
	]
	
	update_horizontal_visibility()
	
func _on_nut_collected(_nut):
	nuts_collected += 1
	nut_counter_label.text = "Nuts: %d" % nuts_collected

func _process(_delta):
	
	update_vertical_sections()
	update_horizontal_loop()
	
		
func print_sections():
	var names = []
	for s in sections:
		names.append(s.name)
	print(names)
	
		
func rotate_right():

	var first = sections.pop_front()
	sections.append(first)

	var last = sections[-2]
	first.global_position.x = last.global_position.x + SECTION_WIDTH
	
	update_horizontal_visibility()

	print_sections()


func rotate_left():

	var last = sections.pop_back()
	sections.insert(0, last)

	var first = sections[1]
	last.global_position.x = first.global_position.x - SECTION_WIDTH
	
	update_horizontal_visibility()

	print_sections()
	
func update_horizontal_visibility():

	var middle_index = 1

	for i in range(sections.size()):

		if abs(i - middle_index) <= 1:
			sections[i].visible = true
		else:
			sections[i].visible = false
	
func set_section_active(section: Node2D, active: bool):
	
	if active:
		section.process_mode = Node.PROCESS_MODE_INHERIT
	else:
		section.process_mode = Node.PROCESS_MODE_DISABLED
		
func get_player_row():
	
	return int(player.global_position.y / SECTION_HEIGHT)
	
func update_vertical_sections():

	var player_row = clamp(get_player_row(), 0, rows.size() - 1)

	if player_row != current_row:
		current_row = player_row
		sections = rows[current_row]

	for i in range(rows.size()):

		var active = abs(i - player_row) <= ACTIVE_ROW_RANGE

		for section in rows[i]:
			set_section_active(section, active)

			
func update_horizontal_loop():

	var middle = sections[1]

	if player.global_position.x > middle.global_position.x + SECTION_WIDTH:
		rotate_right()

	elif player.global_position.x < middle.global_position.x:
		rotate_left()
