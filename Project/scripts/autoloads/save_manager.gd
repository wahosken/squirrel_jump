extends Node

const SAVE_PATH := "user://savegame.json"
const PREVIOUS_SAVE_PATH := "user://previous_save.json"

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
	save_data.player_position = vector2_to_dict(player.global_position)
	save_data.player_velocity = vector2_to_dict(player.velocity)
	save_data.player_grounded = player.is_on_floor()

	save_game()


func save_current_player() -> void:
	var player = get_tree().get_first_node_in_group("player")

	if player == null:
		return

	save_data.player_position = vector2_to_dict(player.global_position)
	save_data.player_velocity = vector2_to_dict(player.velocity)
	save_data.player_grounded = player.is_on_floor()

	save_game()


func save_game() -> void:
	GameState.save_to_save()

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)

	if file == null:
		push_error("Failed to save game.")
		return

	save_data["last_played"] = int(Time.get_unix_time_from_system())

	file.store_string(
		JSON.stringify(save_data, "\t")
	)

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

	var text := file.get_as_text()

	var parsed = JSON.parse_string(text)

	if parsed == null:
		push_error("Failed to parse save file.")
		save_data = get_default_save()
		return

	save_data = parsed
	file.close()

	GameState.load_from_save()


func reset_save() -> void:
	backup_current_save()

	save_data = get_default_save()

	GameState.load_from_save()

	save_game()

	print("Progress reset.")


func backup_current_save() -> void:
	if not has_save():
		return

	var source := FileAccess.open(SAVE_PATH, FileAccess.READ)

	if source == null:
		return

	var data := source.get_as_text()

	source.close()

	var backup := FileAccess.open(
		PREVIOUS_SAVE_PATH,
		FileAccess.WRITE
	)

	if backup == null:
		return

	backup.store_string(data)

	backup.close()


func get_default_save() -> Dictionary:
	return {
		"save_version": 1,
		"version": 0.3,

		"created_at": int(Time.get_unix_time_from_system()),
		"last_played": int(Time.get_unix_time_from_system()),

		# Current climb state
		"player_position": vector2_to_dict(DEFAULT_SPAWN),
		"player_velocity": vector2_to_dict(Vector2.ZERO),
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


func vector2_to_dict(v: Vector2) -> Dictionary:
	return {
		"x": roundi(v.x),
		"y": roundi(v.y)
	}


func dict_to_vector2(data: Dictionary) -> Vector2:
	return Vector2(
		data.get("x", 0),
		data.get("y", 0)
	)


func add_stat(stat_name: String, amount) -> void:
	if not save_data.has(stat_name):
		return

	save_data[stat_name] += amount
	mark_dirty()


func set_stat_if_higher(stat_name: String, value) -> void:
	if not save_data.has(stat_name):
		return

	if value > save_data[stat_name]:
		save_data[stat_name] = value
		mark_dirty()
