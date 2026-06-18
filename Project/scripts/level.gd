extends Node2D

# ======================================================
# --- WORLD WRAP CONFIG ---
# ======================================================
@export var world_left_x := -2272.0
@export var world_width := 5120.0

# ======================================================
# --- CAMERA WRAP GUARD CONFIG ---
# ======================================================
@export var camera_guard_outer_distance := 192.0
@export var camera_guard_inner_distance := 1.0
@export var camera_guard_max_smoothing_speed := 40.0

# ======================================================
# --- ENTITY ACTIVATION CONFIG ---
# ======================================================
@export var entity_check_interval := 0.25
@export var entity_vertical_activation_distance := 1800.0
@export var entity_vertical_deactivation_distance := 2200.0

# ======================================================
# --- DEBUG CONFIG ---
# ======================================================
@export var debug_enabled := true
@export var debug_print_interval := 6.0

# ======================================================
# --- NODES ---
# ======================================================
@onready var player: CharacterBody2D = $"../player"
@onready var camera: Camera2D = $"../player/Camera2D"

# ======================================================
# --- STATE ---
# ======================================================
var entity_check_timer := 0.0
var debug_timer := 0.0
var managed_entities: Array[Node] = []

var camera_smoothing_was_enabled := false
var camera_original_smoothing_enabled := true
var camera_original_smoothing_speed := 5.0
var camera_in_soft_guard := false


# ======================================================
# --- READY ---
# ======================================================
func _ready() -> void:
	_connect_nuts()
	_cache_managed_entities()

	if camera != null:
		camera_original_smoothing_enabled = camera.position_smoothing_enabled
		camera_original_smoothing_speed = camera.position_smoothing_speed

	update_entity_activation()


# ======================================================
# --- PROCESS ---
# ======================================================
func _process(delta: float) -> void:
	_update_soft_camera_wrap_guard()

	entity_check_timer += delta
	if entity_check_timer >= entity_check_interval:
		entity_check_timer = 0.0
		update_entity_activation()

	if debug_enabled:
		debug_timer += delta
		if debug_timer >= debug_print_interval:
			debug_timer = 0.0
			print_debug_info()


# ======================================================
# --- NUT CONNECTION ---
# ======================================================
func _connect_nuts() -> void:
	for nut in get_tree().get_nodes_in_group("nuts"):
		if not nut.is_connected("collected", Callable(self, "_on_nut_collected")):
			nut.connect("collected", Callable(self, "_on_nut_collected"))


func _on_nut_collected(nut) -> void:
	GameState.add_nuts(nut.nut_value)


# ======================================================
# --- HORIZONTAL WORLD WRAP ---
# ======================================================
func update_horizontal_player_wrap() -> void:
	var world_right_x: float = get_world_right_x()
	var old_x: float = player.global_position.x
	var new_x: float = old_x

	if old_x >= world_right_x:
		new_x = old_x - world_width

	elif old_x < world_left_x:
		new_x = old_x + world_width

	if is_equal_approx(new_x, old_x):
		return

	_prepare_camera_for_wrap()

	player.global_position.x = new_x

	var wrap_delta := new_x - old_x

	for layer in get_tree().get_nodes_in_group("parallax_layers"):
		layer.scroll_offset.x += wrap_delta * layer.scroll_scale.x

	_reset_wrap_interpolation()

	_finish_camera_after_wrap()
	
	print("World Wrap")


func get_world_right_x() -> float:
	return world_left_x + world_width


# ======================================================
# --- SOFT CAMERA WRAP GUARD ---
# ======================================================
func _update_soft_camera_wrap_guard() -> void:
	if camera == null or player == null:
		return

	var world_right_x: float = get_world_right_x()
	var player_x: float = player.global_position.x

	var distance_to_left: float = abs(player_x - world_left_x)
	var distance_to_right: float = abs(world_right_x - player_x)
	var distance_to_nearest_edge: float = min(distance_to_left, distance_to_right)

	if distance_to_nearest_edge > camera_guard_outer_distance:
		if camera_in_soft_guard:
			_restore_normal_camera_smoothing()

		return

	camera_in_soft_guard = true

	if distance_to_nearest_edge <= camera_guard_inner_distance:
		camera.position_smoothing_enabled = false
		camera.reset_smoothing()
		camera.force_update_scroll()
		return

	camera.position_smoothing_enabled = true

	var t: float = inverse_lerp(
		camera_guard_outer_distance,
		camera_guard_inner_distance,
		distance_to_nearest_edge
	)

	t = clampf(t, 0.0, 1.0)
	t = smoothstep(0.0, 1.0, t)

	camera.position_smoothing_speed = lerpf(
		camera_original_smoothing_speed,
		camera_guard_max_smoothing_speed,
		t
	)


func _restore_normal_camera_smoothing() -> void:
	if camera == null:
		return

	camera.position_smoothing_enabled = camera_original_smoothing_enabled
	camera.position_smoothing_speed = camera_original_smoothing_speed

	camera_in_soft_guard = false


func _prepare_camera_for_wrap() -> void:
	if camera == null:
		return

	camera_smoothing_was_enabled = camera.position_smoothing_enabled
	camera.position_smoothing_enabled = false
	camera.reset_smoothing()
	camera.force_update_scroll()


func _finish_camera_after_wrap() -> void:
	if camera == null:
		return

	camera.position_smoothing_enabled = false
	camera.reset_smoothing()
	camera.force_update_scroll()

	camera_in_soft_guard = true


func _reset_wrap_interpolation() -> void:
	_reset_physics_interpolation_recursive(player)

	if camera != null:
		camera.reset_physics_interpolation()
		camera.reset_smoothing()
		camera.force_update_scroll()


func _reset_physics_interpolation_recursive(node: Node) -> void:
	if node == null:
		return

	node.reset_physics_interpolation()

	for child in node.get_children():
		_reset_physics_interpolation_recursive(child)


# ======================================================
# --- ENTITY ACTIVATION ---
# ======================================================
func _cache_managed_entities() -> void:
	managed_entities.clear()

	for entity in get_tree().get_nodes_in_group("managed_entities"):
		if not entity is Node2D:
			continue

		if _is_inside_edge_projection(entity):
			if debug_enabled:
				print("Skipping projected managed entity:", entity.name)
			continue

		managed_entities.append(entity)


func _is_inside_edge_projection(node: Node) -> bool:
	var current := node

	while current != null:
		if current.name == "EdgeProjectionManager":
			return true
		if current.name == "LeftProjection":
			return true
		if current.name == "RightProjection":
			return true
		if current.name == "LiveEdgeMirrorManager":
			return true
		if current.name == "LeftLiveMirrors":
			return true
		if current.name == "RightLiveMirrors":
			return true

		current = current.get_parent()

	return false


func update_entity_activation() -> void:
	for entity in managed_entities:
		if not is_instance_valid(entity):
			continue

		var active := _should_entity_be_active(entity)
		_set_entity_active(entity, active)


func _should_entity_be_active(entity: Node) -> bool:
	if not entity is Node2D:
		return true

	var entity_2d := entity as Node2D
	var dy: float = abs(entity_2d.global_position.y - player.global_position.y)

	var currently_active := entity.process_mode != Node.PROCESS_MODE_DISABLED

	if currently_active:
		return dy <= entity_vertical_deactivation_distance
	else:
		return dy <= entity_vertical_activation_distance


func _set_entity_active(node: Node, active: bool) -> void:
	if node.has_method("set_active"):
		node.set_active(active)
		return

	# Avoid directly disabling animation systems.
	if node is AnimationPlayer:
		return

	if node is AnimationTree:
		return

	node.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	node.set_process(active)
	node.set_physics_process(active)

	if node is CanvasItem:
		node.visible = active

	if node is CollisionObject2D:
		node.set_process_input(active)
		node.set_process_unhandled_input(active)

	if node is CollisionShape2D:
		node.disabled = not active

	for child in node.get_children():
		_set_entity_active(child, active)


# ======================================================
# --- DEBUG ---
# ======================================================
func print_debug_info() -> void:
	print("--------")
	print("Player position: ", player.global_position)
	print("Timestamp ", Time.get_time_string_from_system())

	if camera != null:
		print("")
		print("Camera smoothing enabled: ", camera.position_smoothing_enabled)
		print("Camera smoothing speed: ", camera.position_smoothing_speed)
	else:
		print("")
		print("Camera smoothing enabled: No camera")
		print("Camera smoothing speed: No camera")

	print("Camera in soft guard: ", camera_in_soft_guard)
	print("")
	print("Managed entities: ", managed_entities.size())
	print("Active entities: ", get_active_entity_count())
	print("Active nuts: ", get_active_nuts_count())
	print("Active platforms: ", get_active_platforms_count())


func get_active_entity_count() -> int:
	var count := 0

	for entity in managed_entities:
		if not is_instance_valid(entity):
			continue

		if entity.process_mode != Node.PROCESS_MODE_DISABLED:
			count += 1

	return count


func get_active_nuts_count() -> int:
	var count := 0

	for nut in get_tree().get_nodes_in_group("nuts"):
		if nut.visible and nut.process_mode != Node.PROCESS_MODE_DISABLED:
			count += 1

	return count


func get_active_platforms_count() -> int:
	var count := 0

	for platform in get_tree().get_nodes_in_group("platforms"):
		if platform.visible and platform.process_mode != Node.PROCESS_MODE_DISABLED:
			count += 1

	return count
