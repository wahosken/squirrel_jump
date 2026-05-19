extends Node2D

@export var world_width := 5120.0

@onready var level: Node2D = get_parent()
@onready var left_projection: Node2D = $LeftProjection
@onready var right_projection: Node2D = $RightProjection


func _ready() -> void:
	rebuild_projections()


func rebuild_projections() -> void:
	_clear_children(left_projection)
	_clear_children(right_projection)

	for source in level.get_children():
		if not _should_project(source):
			continue

		var left_clone := source.duplicate()
		var right_clone := source.duplicate()

		left_clone.position.x -= world_width
		right_clone.position.x += world_width

		_make_visual_only(left_clone)
		_make_visual_only(right_clone)

		left_projection.add_child(left_clone)
		right_projection.add_child(right_clone)


func _should_project(source: Node) -> bool:
	if source == self:
		return false

	if source == left_projection:
		return false

	if source == right_projection:
		return false

	if source.name == "EdgeProjectionManager":
		return false

	if source.name == "LeftProjection":
		return false

	if source.name == "RightProjection":
		return false

	if not source is Node2D:
		return false

	return true


func _clear_children(parent: Node) -> void:
	for child in parent.get_children():
		child.queue_free()


func _make_visual_only(node: Node) -> void:
	for group_name in node.get_groups():
		node.remove_from_group(group_name)

	node.set_process(false)
	node.set_physics_process(false)
	node.set_process_input(false)
	node.set_process_unhandled_input(false)

	node.process_mode = Node.PROCESS_MODE_DISABLED

	if node is CollisionObject2D:
		node.collision_layer = 0
		node.collision_mask = 0

	if node is CollisionShape2D:
		node.disabled = true

	if node is CanvasItem:
		node.visible = true

	for child in node.get_children():
		_make_visual_only(child)
