extends Node
class_name SquirrelAnimator

@export var sprite: Sprite2D
@export var apparel_sprite: Sprite2D

const FRAME_SIZE := Vector2i(64, 48)
const SPRITE_OFFSET := Vector2(-11, -8)

const SOURCE_PALETTE := {
	"body": Color("bd967e"),
	"shade": Color("9a605b"),
	"belly": Color("fcf1d7"),
	"nose": Color("2e2931"),
	"shadow": Color("533d3f"),
	"eye": Color("fef9e8")
}

const PALETTE_KEYS := [
	"body",
	"shade",
	"belly",
	"nose",
	"shadow",
	"eye"
]

var current_animation := "idle"
var current_frame_index := 0
var frame_timer := 0.0

var appearances: Dictionary = AppearanceDatabase.APPEARANCES

var skin_offsets := {
	"squirrel": 0,
	"squirrel_skeleton": 9
}

var skin_offset := 0

var animations := {
	"idle": {
		"row": 0,
		"frames": [0, 0, 0, 1, 2, 1],
		"fps": 10.0
	},

	"run": {
		"row": 1,
		"frames": [0, 1, 2],
		"fps": 10.0
	},

	"jump": {
		"row": 2,
		"frames": [0],
		"fps": 1.0
	},

	"fall": {
		"row": 3,
		"frames": [0],
		"fps": 1.0
	},

	"glide": {
		"row": 4,
		"frames": [0],
		"fps": 1.0
	},

	"glide_low": {
		"row": 5,
		"frames": [0],
		"fps": 1.0
	},

	"crouch": {
		"row": 6,
		"frames": [0, 0, 0, 1, 2],
		"fps": 10.0
	},

	"swing": {
		"row": 7,
		"frames": [0],
		"fps": 1.0
	},

	"wall_cling": {
		"row": 8,
		"frames": [0],
		"fps": 1.0
	}
}


func _ready() -> void:

	setup_visual_layers()
	setup_shader()
	apply_appearance("squirrel")


func _process(delta: float) -> void:
	var anim = animations[current_animation]

	frame_timer += delta

	var frame_duration = 1.0 / anim.fps

	while frame_timer >= frame_duration:
		frame_timer -= frame_duration

		current_frame_index += 1

		if current_frame_index >= anim.frames.size():
			current_frame_index = 0

	if sprite:
		sprite.region_rect = get_region_rect()

	if apparel_sprite and apparel_sprite.visible:
		apparel_sprite.region_rect = get_apparel_region_rect()


func setup_visual_layers() -> void:
	if sprite:
		sprite.position = SPRITE_OFFSET

	if apparel_sprite:
		apparel_sprite.position = SPRITE_OFFSET


func setup_shader() -> void:
	if sprite == null:
		return

	var material := sprite.material as ShaderMaterial

	if material == null:
		return

	for key in PALETTE_KEYS:
		material.set_shader_parameter(
			"source_" + key,
			SOURCE_PALETTE[key]
		)


func play(anim_name: String) -> void:
	if current_animation == anim_name:
		return

	current_animation = anim_name
	current_frame_index = 0
	frame_timer = 0.0


func get_current_frame() -> int:
	var anim = animations[current_animation]
	return anim.frames[current_frame_index]


func get_current_row() -> int:
	var anim = animations[current_animation]
	return anim.row + skin_offset


func get_region_rect() -> Rect2:
	var frame = get_current_frame()
	var row = get_current_row()

	return Rect2(
		frame * FRAME_SIZE.x,
		row * FRAME_SIZE.y,
		FRAME_SIZE.x,
		FRAME_SIZE.y
	)


func get_apparel_region_rect() -> Rect2:
	var frame = get_current_frame()
	var row = animations[current_animation].row

	return Rect2(
		frame * FRAME_SIZE.x,
		row * FRAME_SIZE.y,
		FRAME_SIZE.x,
		FRAME_SIZE.y
	)


func set_skin(skin_id: String) -> void:
	if skin_offsets.has(skin_id):
		skin_offset = skin_offsets[skin_id]
	else:
		skin_offset = 0


func apply_appearance(appearance_id: String) -> void:
	if not appearances.has(appearance_id):
		appearance_id = "squirrel"

	var appearance: Dictionary = appearances[appearance_id]

	set_skin(appearance["skin"])
	apply_palette(appearance)


func apply_palette(appearance: Dictionary) -> void:
	if sprite == null:
		return

	var material := sprite.material as ShaderMaterial

	if material == null:
		return

	for key in PALETTE_KEYS:
		material.set_shader_parameter(
			"target_" + key,
			appearance[key]
		)


func get_appearance_ids() -> Array:
	return appearances.keys()


func get_appearance_display_name(id: String) -> String:
	if not appearances.has(id):
		return id

	return appearances[id].get("display_name", id)
