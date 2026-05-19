extends Node2D

@export var world_width := 5120.0
@export var static_visuals_path: NodePath = "../StaticVisuals"

@onready var left_projection: Node2D = $LeftProjection
@onready var right_projection: Node2D = $RightProjection

var static_visuals: Node2D


func _ready() -> void:
	static_visuals = get_node_or_null(static_visuals_path)

	if static_visuals == null:
		push_error("EdgeProjectionManager could not find StaticVisuals.")
		return

	rebuild_projections()


func rebuild_projections() -> void:
	_clear_children(left_projection)
	_clear_children(right_projection)

	var left_clone := static_visuals.duplicate()
	var right_clone := static_visuals.duplicate()

	left_clone.position.x -= world_width
	right_clone.position.x += world_width

	_make_visual_only(left_clone)
	_make_visual_only(right_clone)

	left_projection.add_child(left_clone)
	right_projection.add_child(right_clone)


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
