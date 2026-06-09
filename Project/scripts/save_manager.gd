extends Node

const SAVE_PATH := "user://savegame.json"
const DEFAULT_SPAWN := Vector2(-432, -1728)

const SAVE_TIMER = 0.25

var save_data: Dictionary = {}
var save_dirty := false

var autosave_timer := 0.0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_game()


func _process(delta):
	autosave_timer += delta

	if autosave_timer >= SAVE_TIMER:
		autosave_timer = 0.0

		if save_dirty:
			save_game()
			save_dirty = false


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_player(player) -> void:
	save_data.player_position = player.global_position
	save_data.player_velocity = player.velocity
	save_data.player_grounded = player.is_on_floor()

	save_game()


func save_current_player() -> void:
	var player = get_tree().get_first_node_in_group("player")

	if player == null:
		return

	save_data.player_position = player.global_position
	save_data.player_velocity = player.velocity
	save_data.player_grounded = player.is_on_floor()

	save_game()


func save_game() -> void:
	GameState.save_to_save()

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)

	if file == null:
		push_error("Failed to save game.")
		return

	save_data["last_played"] = Time.get_unix_time_from_system()

	file.store_var(save_data)
	file.close()

	print("GAME SAVED")


func load_game() -> void:
	if not has_save():
		save_data = get_default_save()
		save_game()
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)

	if file == null:
		push_error("Failed to load save.")
		save_data = get_default_save()
		return

	save_data = file.get_var()
	file.close()

	GameState.load_from_save()


func reset_save() -> void:
	save_data = get_default_save()
	save_game()


func get_default_save() -> Dictionary:
	return {
		"version": 1,

		"created_at": Time.get_unix_time_from_system(),
		"last_played": Time.get_unix_time_from_system(),

		# Current climb state
		"player_position": DEFAULT_SPAWN,
		"player_velocity": Vector2.ZERO,
		"player_grounded": true,

		# Progress
		"highest_height_reached": 0.0,
		"highest_fall_start_height": 0.0,

		# Currency
		"nuts": 0,

		# Cosmetics
		"owned_cosmetics": {},
		"equipped_cosmetic": "",
		"equipped_squirrel_color": "squirrel",

		# Collections
		"collectibles": [],
		"areas_discovered": [],

		# Lifetime statistics
		"total_height_climbed": 0.0,
		"total_distance_fallen": 0.0,

		"total_jumps": 0,
		"total_falls": 0,

		"longest_fall_distance": 0.0,
		"longest_fall_duration": 0.0,

		"playtime_seconds": 0.0,
		"time_standing_still": 0.0,

		"times_returned_to_ground": 0,
		"summit_reaches": 0,
		"major_comebacks": 0,

		"longest_session_seconds": 0.0,

		# Settings
		"difficulty": "normal"
	}


func mark_dirty() -> void:
	save_dirty = true


func has_collectible(id: String) -> bool:
	return id in save_data.collectibles


func collect_collectible(id: String) -> void:
	if id in save_data.collectibles:
		return

	save_data.collectibles.append(id)
	save_game()
