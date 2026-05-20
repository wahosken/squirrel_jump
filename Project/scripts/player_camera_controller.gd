extends Node

const CAMERA_NORMAL_FOLLOW_SPEED := 10.0
const CAMERA_FAST_FOLLOW_SPEED := 18.0

@export var camera: Camera2D
@export var player: CharacterBody2D
@export var swing: Node

@export var zoom_lerp_speed := 6.0
@export var min_zoom_mult := 0.6
@export var max_zoom_mult := 1.0
@export var zoom_start_speed := 600.0
@export var fall_speed_for_max_zoom := 1800.0
@export var zoom_curve_power := 1.6

@export var camera_swing_offset := Vector2(8, -5)

var base_zoom := 1.0
var normal_position := Vector2.ZERO
var zoom_target := Vector2.ONE

var camera_snap_next_frame := false
var smoothing_restore_next_frame := false
var smoothing_was_enabled := false

var manual_zoom_toggled := false


func _ready() -> void:
	if camera == null:
		camera = get_parent().get_node_or_null("Camera2D")

	if player == null:
		player = get_parent() as CharacterBody2D

	if swing == null and player:
		swing = player.get_node_or_null("SwingComponent")

	if camera:
		normal_position = camera.position
		base_zoom = camera.zoom.x


func update_camera(delta: float, is_gliding: bool, facing_right: bool, is_on_floor: bool) -> void:
	if camera == null or player == null:
		return

	if smoothing_restore_next_frame:
		camera.position_smoothing_enabled = smoothing_was_enabled
		smoothing_restore_next_frame = false

	_update_zoom(delta, is_gliding, is_on_floor)
	_update_position(delta, facing_right)


func _update_zoom(delta: float, is_gliding: bool, is_on_floor: bool) -> void:
	var cam_fall_speed := player.velocity.y

	if is_gliding:
		cam_fall_speed = min(cam_fall_speed, 120.0)

	zoom_target = Vector2(base_zoom, base_zoom)

	if not is_on_floor:
		var t: float = clampf(
			(cam_fall_speed - zoom_start_speed) /
			(fall_speed_for_max_zoom - zoom_start_speed),
			0.0,
			1.0
		)

		t = pow(t, zoom_curve_power)

		var zoom_mult: float = lerpf(max_zoom_mult, min_zoom_mult, t)
		zoom_target *= zoom_mult

	var manual_zoom_active := _get_manual_zoom_active()

	if manual_zoom_active:
		zoom_target = Vector2(base_zoom * min_zoom_mult, base_zoom * min_zoom_mult)

	if camera_snap_next_frame:
		camera.zoom = zoom_target
	else:
		camera.zoom = camera.zoom.lerp(zoom_target, zoom_lerp_speed * delta)


func _update_position(delta: float, facing_right: bool) -> void:
	var target_camera_pos := normal_position

	if swing and swing.is_swinging:
		var swing_x: float = camera_swing_offset.x if facing_right else -camera_swing_offset.x
		target_camera_pos = Vector2(swing_x, camera_swing_offset.y)

	var fall_factor := clampf((player.velocity.y - 600.0) / 1000.0, 0.0, 1.0)
	var cam_speed := lerpf(CAMERA_NORMAL_FOLLOW_SPEED, CAMERA_FAST_FOLLOW_SPEED, fall_factor)

	if camera_snap_next_frame:
		camera.position = target_camera_pos
		camera.reset_smoothing()
		camera.force_update_scroll()
		camera_snap_next_frame = false
	else:
		camera.position = camera.position.lerp(target_camera_pos, cam_speed * delta)


func _get_manual_zoom_active() -> bool:
	# Default behavior:
	# camera is zoomed out normally, zooms in while held.
	if not GameState.toggle_camera_zoom:
		var held := Input.is_action_pressed("camera_zoom")
		return not held if GameState.invert_camera_zoom else held

	# Toggle behavior:
	if Input.is_action_just_pressed("camera_zoom"):
		manual_zoom_toggled = !manual_zoom_toggled

	return not manual_zoom_toggled if GameState.invert_camera_zoom else manual_zoom_toggled


func snap_after_world_wrap() -> void:
	if camera == null:
		return

	camera_snap_next_frame = true

	smoothing_was_enabled = camera.position_smoothing_enabled
	camera.position_smoothing_enabled = false

	camera.position = normal_position
	camera.reset_smoothing()
	camera.force_update_scroll()

	smoothing_restore_next_frame = true
