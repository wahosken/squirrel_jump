extends Node2D

@export var world_width := 5120.0
@export var dynamic_objects_path: NodePath = "../DynamicObjects"

@onready var left_live_mirrors: Node2D = $LeftLiveMirrors
@onready var right_live_mirrors: Node2D = $RightLiveMirrors

var dynamic_objects: Node2D
var mirror_pairs: Array[Dictionary] = []


func _ready() -> void:
	dynamic_objects = get_node_or_null(dynamic_objects_path)

	if dynamic_objects == null:
		push_error("LiveEdgeMirrorManager could not find DynamicObjects.")
		return

	rebuild_live_mirrors()


func _process(_delta: float) -> void:
	update_live_mirrors()


func rebuild_live_mirrors() -> void:
	mirror_pairs.clear()

	_clear_children(left_live_mirrors)
	_clear_children(right_live_mirrors)

	for source in dynamic_objects.get_children():
		if not source is Node2D:
			continue

		_create_mirror_pair(source as Node2D, left_live_mirrors, Vector2(-world_width, 0.0))
		_create_mirror_pair(source as Node2D, right_live_mirrors, Vector2(world_width, 0.0))

func _get_dynamic_node2d_children(root: Node) -> Array[Node2D]:
	var results: Array[Node2D] = []

	for child in root.get_children():
		if child is Node2D:
			results.append(child as Node2D)
		else:
			results.append_array(_get_dynamic_node2d_children(child))

	return results


func _create_mirror_pair(source: Node2D, parent: Node2D, offset: Vector2) -> void:
	var clone := source.duplicate()
	parent.add_child(clone)

	if clone is Node2D:
		clone.top_level = true

	_make_visual_only(clone)

	mirror_pairs.append({
		"source": source,
		"clone": clone,
		"offset": offset
	})


func update_live_mirrors() -> void:
	var valid_pairs: Array[Dictionary] = []

	for pair in mirror_pairs:
		var source = pair.get("source", null)
		var clone = pair.get("clone", null)
		var offset: Vector2 = pair.get("offset", Vector2.ZERO)

		if not is_instance_valid(source):
			if is_instance_valid(clone):
				clone.queue_free()
			continue

		if not is_instance_valid(clone):
			continue

		if not source is Node2D:
			continue

		if not clone is Node2D:
			continue

		_sync_visual_state(source, clone, offset)
		valid_pairs.append(pair)

	mirror_pairs = valid_pairs


func _sync_visual_state(source: Node, clone: Node, offset: Vector2) -> void:
	if source is CanvasItem and clone is CanvasItem:
		clone.visible = source.visible
		clone.modulate = source.modulate
		clone.self_modulate = source.self_modulate

	if source is Node2D and clone is Node2D:
		clone.global_transform = source.global_transform
		clone.global_position += offset

	if source is AnimatedSprite2D and clone is AnimatedSprite2D:
		clone.animation = source.animation
		clone.frame = source.frame
		clone.frame_progress = source.frame_progress
		clone.flip_h = source.flip_h
		clone.flip_v = source.flip_v

	if source is Sprite2D and clone is Sprite2D:
		clone.flip_h = source.flip_h
		clone.flip_v = source.flip_v
		clone.frame = source.frame
		clone.region_enabled = source.region_enabled
		clone.region_rect = source.region_rect

	var source_children := source.get_children()
	var clone_children := clone.get_children()

	var child_count: int = min(source_children.size(), clone_children.size())

	for i in range(child_count):
		_sync_visual_state(source_children[i], clone_children[i], offset)


func _make_visual_only(node: Node) -> void:
	for group_name in node.get_groups():
		node.remove_from_group(group_name)

	node.set_process(false)
	node.set_physics_process(false)
	node.set_process_input(false)
	node.set_process_unhandled_input(false)

	if node is CollisionObject2D:
		node.collision_layer = 0
		node.collision_mask = 0

	if node is CollisionShape2D:
		node.disabled = true

	if node is Area2D:
		node.monitoring = false
		node.monitorable = false

	if node is AnimationPlayer:
		node.stop()

	if node is AnimationTree:
		node.active = false

	if node is CanvasItem:
		node.visible = true

	for child in node.get_children():
		_make_visual_only(child)


func _clear_children(parent: Node) -> void:
	for child in parent.get_children():
		child.queue_free()
