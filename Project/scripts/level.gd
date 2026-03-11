extends Node2D


const SECTION_WIDTH = 1024

@onready var player: CharacterBody2D = $"../player"
@onready var section_1a: Node2D = $section_1a
@onready var section_1b: Node2D = $section_1b
@onready var section_1c: Node2D = $section_1c
@onready var section_1d: Node2D = $section_1d
@onready var section_1e: Node2D = $section_1e
@onready var nut_counter_label: Label = $"../UI/NutCounterLabel"


var sections = []
var rotation_cooldown = false
var nuts_collected: int = 0

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
	
func _on_nut_collected(_nut):
	nuts_collected += 1
	nut_counter_label.text = "Nuts: %d" % nuts_collected

func _process(_delta):
	
	var middle = sections[2]
	
	if not rotation_cooldown and player.global_position.x > middle.global_position.x + SECTION_WIDTH:
		rotation_cooldown = true
		rotate_right()

	elif not rotation_cooldown and player.global_position.x < middle.global_position.x:
		rotation_cooldown = true
		rotate_left()
		
	if player.global_position.x > middle.global_position.x and player.global_position.x < middle.global_position.x + SECTION_WIDTH:
		rotation_cooldown = false
	
		
func print_sections():
	var names = []
	for s in sections:
		names.append(s.name)
	print(names)
	
func update_section_visibility():

	for i in range(sections.size()):
		
		# hide first and last sections
		if i == 0 or i == sections.size() - 1:
			sections[i].visible = false
		else:
			sections[i].visible = true
		
func rotate_right():

	var first = sections.pop_front()
	sections.append(first)

	var last = sections[-2]
	first.global_position.x = last.global_position.x + SECTION_WIDTH

	update_section_visibility()

	print_sections()


func rotate_left():

	var last = sections.pop_back()
	sections.insert(0, last)

	var first = sections[1]
	last.global_position.x = first.global_position.x - SECTION_WIDTH

	update_section_visibility()

	print_sections()
