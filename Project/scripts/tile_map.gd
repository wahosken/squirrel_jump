@tool
extends TileMap

const TILESET_SOURCE_ID := 1
const MAX_PLATFORM_GAP := 5
const MIN_BRANCH_ROW := -55

@export var generate_branches := false:
	set(value):
		if value:
			run_branch_generation()
		generate_branches = false


func run_branch_generation() -> void:
	print("Generating branches...")

	var mid_layer = get_layer_index_by_name("Mid")
	var branch_layer = get_layer_index_by_name("Branches")
	var bkg_layer = get_layer_index_by_name("Bkg")

	clear_layer(branch_layer)

	var platforms = []

	platforms.append_array(
		get_platform_tiles(mid_layer)
	)

	platforms.append_array(
		get_falling_platforms()
	)

	platforms.append_array(
		get_bouncy_platforms()
	)

	platforms.append_array(
		get_swing_branches()
	)

	var trunks = get_trunk_edges(bkg_layer)
	var trunk_tiles = get_trunk_tiles(bkg_layer)

	var lookup = get_platform_lookup(platforms)

	var clusters = get_all_clusters(
		platforms,
		lookup,
		trunk_tiles
	)

	for cluster in clusters:

		draw_cluster_support(
			branch_layer,
			cluster,
			trunks
		)


func get_layer_index_by_name(layer_name: String) -> int:
	for i in range(get_layers_count()):
		if get_layer_name(i) == layer_name:
			return i
	return -1


func get_platform_tiles(mid_layer: int) -> Array:

	var platforms := []

	for cell in get_used_cells(mid_layer):

		if cell.y > MIN_BRANCH_ROW:
			continue

		var atlas = get_cell_atlas_coords(
			mid_layer,
			cell
		)

		if atlas == Vector2i(1, 6):
			platforms.append({
				"cell": cell,
				"is_leaf": false
			})

		elif atlas == Vector2i(3, 6):
			platforms.append({
				"cell": cell,
				"is_leaf": true
			})

	return platforms


func get_trunk_edges(bkg_layer: int) -> Dictionary:
	var rows := {}

	for cell in get_used_cells(bkg_layer):
		var atlas = get_cell_atlas_coords(bkg_layer, cell)

		var is_left_edge = atlas.x == 15 and atlas.y >= 0 and atlas.y <= 5
		var is_right_edge = atlas.x == 17 and atlas.y >= 0 and atlas.y <= 5

		if is_left_edge or is_right_edge:
			if not rows.has(cell.y):
				rows[cell.y] = []

			rows[cell.y].append(cell.x)

	return rows


func find_nearest_trunk(
	platform_x: int,
	row: int,
	trunks: Dictionary
):
	if not trunks.has(row):
		return null

	var nearest = null
	var nearest_distance = INF

	for trunk_x in trunks[row]:
		var distance = abs(trunk_x - platform_x)

		if distance < nearest_distance:
			nearest_distance = distance
			nearest = trunk_x

	return nearest



func get_trunk_tiles(bkg_layer: int) -> Dictionary:
	var rows := {}

	for cell in get_used_cells(bkg_layer):
		var atlas = get_cell_atlas_coords(bkg_layer, cell)

		var is_trunk = (
			atlas.x >= 15
			and atlas.x <= 17
			and atlas.y >= 0
			and atlas.y <= 5
		)

		if is_trunk:
			if not rows.has(cell.y):
				rows[cell.y] = []

			rows[cell.y].append(cell.x)

	return rows


func place_test_branches(
	branch_layer: int,
	platforms: Array,
	trunks: Dictionary,
	trunk_tiles: Dictionary
) -> void:



	for platform in platforms:
		var cell = platform["cell"]
		var is_leaf = platform["is_leaf"]

		if is_on_top_of_trunk(cell, trunk_tiles):
			continue

		var atlas: Vector2i

		if is_adjacent_to_trunk(cell, trunks):
			atlas = Vector2i(14, 7) if is_leaf else Vector2i(14, 8)
		else:
			atlas = get_random_branch_tile()

		set_cell(
			branch_layer,
			cell,
			TILESET_SOURCE_ID,
			atlas
		)


func get_random_branch_tile() -> Vector2i:
	return [
		Vector2i(15, 7),
		Vector2i(16, 7),
		Vector2i(17, 7),

		Vector2i(15, 8),
		Vector2i(16, 8),
		Vector2i(17, 8)
	].pick_random()


func is_adjacent_to_trunk(
	cell: Vector2i,
	trunks: Dictionary
) -> bool:

	if not trunks.has(cell.y):
		return false

	for trunk_x in trunks[cell.y]:
		if abs(trunk_x - cell.x) <= 1:
			return true

	return false


func is_on_top_of_trunk(
	cell: Vector2i,
	trunk_tiles: Dictionary
) -> bool:

	if not trunk_tiles.has(cell.y):
		return false

	return cell.x in trunk_tiles[cell.y]


func get_adjacent_trunk_direction(
	cell: Vector2i,
	trunks: Dictionary
) -> int:

	if not trunks.has(cell.y):
		return 0

	for trunk_x in trunks[cell.y]:

		if trunk_x == cell.x - 1:
			return -1

		if trunk_x == cell.x + 1:
			return 1

	return 0


func get_platform_lookup(platforms: Array) -> Dictionary:
	var lookup := {}

	for platform in platforms:
		lookup[platform["cell"]] = platform

	return lookup


func get_trunk_connected_platforms(
	platforms: Array,
	trunks: Dictionary,
	trunk_tiles: Dictionary
) -> Array:

	var result := []

	for platform in platforms:
		var cell = platform["cell"]

		if is_on_top_of_trunk(cell, trunk_tiles):
			continue

		if is_adjacent_to_trunk(cell, trunks):
			result.append(platform)

	return result


func find_platform_cluster(
	start_platform: Dictionary,
	lookup: Dictionary,
	trunk_tiles: Dictionary
) -> Array:

	var cluster := []
	var open := [start_platform]
	var visited := {}

	var trunks = get_trunk_edges(
		get_layer_index_by_name("Bkg")
	)

	while open.size() > 0:

		var current = open.pop_back()
		var cell = current["cell"]

		if visited.has(cell):
			continue

		visited[cell] = true

		if is_on_top_of_trunk(
			cell,
			trunk_tiles
		):
			continue

		cluster.append(current)

		for offset in range(
			-MAX_PLATFORM_GAP,
			MAX_PLATFORM_GAP + 1
		):

			if offset == 0:
				continue

			var neighbor_pos = Vector2i(
				cell.x + offset,
				cell.y
			)

			if not lookup.has(neighbor_pos):
				continue

			if is_on_top_of_trunk(
				neighbor_pos,
				trunk_tiles
			):
				continue

			if trunk_between(
				cell.x,
				neighbor_pos.x,
				cell.y,
				trunks
			):
				continue

			var gap_distance = abs(
				neighbor_pos.x - cell.x
			)

			var nearest_trunk_current = find_nearest_trunk(
				cell.x,
				cell.y,
				trunks
			)

			var nearest_trunk_neighbor = find_nearest_trunk(
				neighbor_pos.x,
				neighbor_pos.y,
				trunks
			)

			var current_trunk_distance = INF
			var neighbor_trunk_distance = INF


			var trunk_between_platforms = false

			if trunks.has(cell.y):

				for trunk_x in trunks[cell.y]:

					if trunk_x > min(cell.x, neighbor_pos.x) \
					and trunk_x < max(cell.x, neighbor_pos.x):

						trunk_between_platforms = true
						break

			if trunk_between_platforms:
				continue

			open.append(
				lookup[neighbor_pos]
			)

	return cluster


func get_cluster_bounds(cluster: Array) -> Dictionary:
	var left = 999999
	var right = -999999

	for platform in cluster:
		var cell = platform["cell"]

		left = min(left, cell.x)
		right = max(right, cell.x)

	return {
		"left": left,
		"right": right
	}


func draw_cluster_support(
	branch_layer: int,
	cluster: Array,
	trunks: Dictionary
) -> void:

	var row_y = cluster[0]["cell"].y

	if row_y > MIN_BRANCH_ROW:
		return

	var positions := []

	for platform in cluster:
		positions.append(platform["cell"].x)

	positions.sort()

	var trunk_x = find_best_trunk_for_cluster(
		cluster,
		trunks
	)

	var connector = [
		Vector2i(14, 7),
		Vector2i(14, 8)
	].pick_random()

	var end_cap = [
		Vector2i(18, 7),
		Vector2i(18, 8)
	].pick_random()

	var left_platform = positions[0]
	var right_platform = positions[positions.size() - 1]

	var has_trunk = trunk_x != null

	var support_tiles := {}

	#
	# Build support span
	#
	if has_trunk:

		if left_platform > trunk_x:

			for x in range(
				trunk_x + 1,
				right_platform + 1
			):
				support_tiles[x] = true

		else:

			for x in range(
				left_platform,
				trunk_x
			):
				support_tiles[x] = true

	#
	# Add platforms
	#
	for pos in positions:
		support_tiles[pos] = true

	#
	# Fill gaps inside cluster
	#
	for i in range(positions.size() - 1):

		var current = positions[i]
		var next = positions[i + 1]

		if next - current <= MAX_PLATFORM_GAP:

			for fill_x in range(
				current,
				next + 1
			):
				support_tiles[fill_x] = true

	var support_positions = support_tiles.keys()
	support_positions.sort()

	var left_x = support_positions[0]
	var right_x = support_positions[
		support_positions.size() - 1
	]

	var platform_positions := {}

	for platform in cluster:
		platform_positions[
			platform["cell"].x
		] = true

	var connector_x = null

	if has_trunk:
		if left_platform > trunk_x:
			connector_x = trunk_x + 1
		else:
			connector_x = trunk_x - 1

	var cluster_is_right_of_trunk = true

	if has_trunk:
		cluster_is_right_of_trunk = (
			left_platform > trunk_x
		)

	if cluster_is_right_of_trunk:

		for x in support_positions:

			var atlas : Vector2i

			if has_trunk and x == connector_x:

				if platform_positions.has(x):
					atlas = connector
				else:
					atlas = get_gap_branch_tile()

			elif platform_positions.has(x):
				atlas = get_random_branch_tile()

			else:
				atlas = get_gap_branch_tile()

			set_cell(
				branch_layer,
				Vector2i(x, row_y),
				TILESET_SOURCE_ID,
				atlas
			)

		set_cell(
			branch_layer,
			Vector2i(right_x + 1, row_y),
			TILESET_SOURCE_ID,
			end_cap
		)

	else:

		for x in support_positions:

			var atlas : Vector2i

			if has_trunk and x == connector_x:

				if platform_positions.has(x):
					atlas = connector
				else:
					atlas = get_gap_connector_tile()

			elif platform_positions.has(x):
				atlas = get_random_branch_tile()

			else:
				atlas = get_gap_branch_tile()

			set_cell(
				branch_layer,
				Vector2i(x, row_y),
				TILESET_SOURCE_ID,
				atlas,
				TileSetAtlasSource.TRANSFORM_FLIP_H
			)

		set_cell(
			branch_layer,
			Vector2i(left_x - 1, row_y),
			TILESET_SOURCE_ID,
			end_cap,
			TileSetAtlasSource.TRANSFORM_FLIP_H
			)

func get_gap_connector_tile() -> Vector2i:
	return Vector2i(14, 9)


func get_cluster_id(cluster: Array) -> String:

	var positions := []

	for platform in cluster:
		positions.append(platform["cell"].x)

	positions.sort()

	return str(
		cluster[0]["cell"].y,
		":",
		positions
	)


func trunk_between(
	x1: int,
	x2: int,
	y: int,
	trunks: Dictionary
) -> bool:

	if not trunks.has(y):
		return false

	var min_x = min(x1, x2)
	var max_x = max(x1, x2)

	for trunk_x in trunks[y]:
		if trunk_x > min_x and trunk_x < max_x:
			return true

	return false


func get_gap_branch_tile() -> Vector2i:
	return [
		Vector2i(15, 9),
		Vector2i(16, 9),
		Vector2i(17, 9)
	].pick_random()


func get_all_clusters(
	platforms: Array,
	lookup: Dictionary,
	trunk_tiles: Dictionary
) -> Array:

	var clusters := []
	var visited := {}

	for platform in platforms:

		var cell = platform["cell"]

		if visited.has(cell):
			continue

		var cluster = find_platform_cluster(
			platform,
			lookup,
			trunk_tiles
		)

		if cluster.is_empty():
			continue

		for member in cluster:
			visited[member["cell"]] = true

		clusters.append(cluster)

	return clusters


func cluster_has_trunk_connection(
	cluster: Array,
	trunks: Dictionary
) -> bool:

	for platform in cluster:

		if is_adjacent_to_trunk(
			platform["cell"],
			trunks
		):
			return true

	return false


func get_falling_platforms() -> Array:

	var result := []

	var level = get_parent().get_parent()

	if level == null:
		return result

	for child in level.get_children():

		if child.name != "DynamicObjects":
			continue

		for node in child.get_children():

			if (
				node.name.begins_with("falling_platform")
				or node.name.begins_with("falling_platform_leaf")
			):

				var tile_pos = local_to_map(
					to_local(node.global_position)
				)

				if tile_pos.y > MIN_BRANCH_ROW:
					continue

				result.append({
					"cell": tile_pos,
					"is_leaf": node.name.contains("leaf"),
					"is_falling": true,
					"node": node
				})


	return result


func get_bouncy_platforms() -> Array:

	var result := []

	var level = get_parent().get_parent()

	if level == null:
		return result

	for node in level.get_tree().get_nodes_in_group("bouncy"):

		var tile_pos = local_to_map(
			to_local(node.global_position)
		)

		if tile_pos.y > MIN_BRANCH_ROW:
			continue

		result.append({
			"cell": tile_pos,
			"is_leaf": true,
			"is_bouncy": true,
			"node": node
		})

	return result


func find_best_trunk_for_cluster(
	cluster: Array,
	trunks: Dictionary
):

	var row_y = cluster[0]["cell"].y

	if not trunks.has(row_y):
		return null

	var best_trunk = null
	var best_distance = INF

	for platform in cluster:

		var x = platform["cell"].x

		for trunk_x in trunks[row_y]:

			var distance = abs(x - trunk_x)

			if distance < best_distance:
				best_distance = distance
				best_trunk = trunk_x

	return best_trunk


func get_swing_branches() -> Array:

	var result := []

	var level = get_parent().get_parent()

	if level == null:
		return result

	for node in level.get_tree().get_nodes_in_group("swing_branch"):

		var tile_pos = local_to_map(
			to_local(node.global_position)
		)

		tile_pos += Vector2i(0, -1)

		if tile_pos.y > MIN_BRANCH_ROW:
			continue

		result.append({
			"cell": tile_pos,
			"is_leaf": true,
			"is_swing_branch": true,
			"node": node
		})

	return result
