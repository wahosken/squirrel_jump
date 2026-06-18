extends Node

var playtime_accumulator := 0.0
var climb_accumulator := 0.0

var last_grounded_y := 0.0

var last_height_y := 0.0
var height_initialized := false

var left_ground_region := false

var comeback_peak_height := 0.0
var comeback_pending := false

var airborne_time := 0.0

var idle_accumulator := 0.0

var in_interior := false

const COMEBACK_FALL_DISTANCE := 2000.0

const GROUND_Y := -1740.0
const HIGH_ALTITUDE_Y := -2400.0

const RETURN_TO_GROUND_HEIGHT := 1000.0

const LOW_ALTITUDE_FALL_THRESHOLD := 500.0
const HIGH_ALTITUDE_FALL_THRESHOLD := 300.0


func record_playtime(delta: float) -> void:
	playtime_accumulator += delta

	if playtime_accumulator >= 5.0:

		SaveManager.save_data.playtime_seconds += int(playtime_accumulator)

		playtime_accumulator = 0.0

		SaveManager.mark_dirty()


func record_jump() -> void:
	SaveManager.save_data.total_jumps += 1

	SaveManager.mark_dirty()


func record_landing(position_y: float) -> void:

	record_highest_height_on_landing(position_y)

	# Returned to ground tracking
	if position_y >= GROUND_Y and left_ground_region:

		left_ground_region = false

		SaveManager.save_data.times_returned_to_ground += 1

		SaveManager.mark_dirty()

	# Don't track fall statistics below ground level
	if position_y > GROUND_Y:
		last_grounded_y = position_y
		return

	var landing_distance := position_y - last_grounded_y

	var previous_height := SaveManager.DEFAULT_SPAWN.y - last_grounded_y

	var required_distance := LOW_ALTITUDE_FALL_THRESHOLD

	if last_grounded_y <= HIGH_ALTITUDE_Y:
		required_distance = HIGH_ALTITUDE_FALL_THRESHOLD

	if landing_distance >= required_distance:

		SaveManager.save_data.total_falls += 1

		SaveManager.save_data.total_distance_fallen += int(landing_distance)

		if landing_distance > SaveManager.save_data.longest_fall_distance:
			SaveManager.save_data.longest_fall_distance = int(landing_distance)

		var fall_start_height := int(previous_height)

		if fall_start_height > SaveManager.save_data.highest_fall_start_height:

			SaveManager.save_data.highest_fall_start_height = fall_start_height

		if landing_distance >= COMEBACK_FALL_DISTANCE:

			comeback_peak_height = previous_height

			comeback_pending = true

		SaveManager.mark_dirty()

	last_grounded_y = position_y


func record_height(position_y: float) -> void:

	if not height_initialized:
		last_height_y = position_y
		height_initialized = true
		return

	if position_y <= GROUND_Y - RETURN_TO_GROUND_HEIGHT:
		left_ground_region = true

	var climb_amount := last_height_y - position_y

	if climb_amount > 0:

		climb_accumulator += climb_amount

		if climb_accumulator >= 100:

			SaveManager.save_data.total_height_climbed += int(climb_accumulator)

			climb_accumulator = 0.0

			SaveManager.mark_dirty()

	last_height_y = position_y

	var current_height := SaveManager.DEFAULT_SPAWN.y - position_y

	if comeback_pending:

		if current_height >= comeback_peak_height:

			comeback_pending = false

			SaveManager.save_data.major_comebacks += 1

			SaveManager.mark_dirty()


func record_summit_reached() -> void:
	SaveManager.save_data.summit_reaches += 1

	SaveManager.mark_dirty()


func record_highest_height_on_landing(position_y: float) -> void:

	var current_height := int(SaveManager.DEFAULT_SPAWN.y - position_y)

	if current_height > SaveManager.save_data.highest_height_reached:

		SaveManager.save_data.highest_height_reached = current_height

		SaveManager.mark_dirty()


func record_airborne(delta: float, on_floor: bool) -> void:

	if on_floor:

		if airborne_time > SaveManager.save_data.longest_fall_duration:

			SaveManager.save_data.longest_fall_duration = airborne_time

			SaveManager.mark_dirty()

		airborne_time = 0.0

	else:

		airborne_time += delta


func record_idle_time(delta: float,on_floor: bool,speed: float) -> void:

	if on_floor and speed < 5.0:

		idle_accumulator += delta

		if idle_accumulator >= 5.0:

			SaveManager.save_data.time_standing_still += int(idle_accumulator)

			idle_accumulator = 0.0

			SaveManager.mark_dirty()
