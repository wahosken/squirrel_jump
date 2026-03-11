extends Node2D


const SECTION_WIDTH = 1024

@onready var player: CharacterBody2D = $"../player"
@onready var section_1a: Node2D = $section_1a
@onready var section_1b: Node2D = $section_1b
@onready var section_1c: Node2D = $section_1c
@onready var section_1d: Node2D = $section_1d

var sections = []
var rotation_cooldown = false

func _ready():
	
	sections = [
		section_1d,
		section_1a,
		section_1b,
		section_1c
	]

func _physics_process(delta):
	
	var middle = sections[1]
	
	if not rotation_cooldown and player.global_position.x > middle.position.x + SECTION_WIDTH:
		rotation_cooldown = true
		rotate_right()
		
	elif not rotation_cooldown and player.global_position.x < middle.position.x:
		rotation_cooldown = true
		rotate_left()
		
	if player.global_position.x > middle.position.x and player.global_position.x < middle.position.x + SECTION_WIDTH:
		rotation_cooldown = false
	
		
func print_sections():
	var names = []
	for s in sections:
		names.append(s.name)
	print(names)
		
func rotate_right():
	
	var first = sections.pop_front()
	sections.append(first)
	
	var last = sections[-2]
	first.set_deferred("position:x", last.position.x + SECTION_WIDTH)
	
	print_sections()
	
func rotate_left():
	
	var last = sections.pop_back()
	sections.insert(0, last)
	
	var first = sections[1]
	last.set_deferred("position:x", first.position.x + SECTION_WIDTH)
	
	print_sections()
