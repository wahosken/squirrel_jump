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

	var platforms_layer = get_layer_index_by_name("Platforms")
	var branch_layer = get_layer_index_by_name("Branches")
	var trees_layer = get_layer_index_by_name("Trees")

	clear_layer(branch_layer)

	var platforms = []

	platforms.append_array(
		get_platform_tiles(platforms_layer)
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

	var trunks = get_trunk_edges(trees_layer)
	var trunk_tiles = get_trunk_tiles(trees_layer)

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


func get_platform_tiles(platforms_layer: int) -> Array:

	var platforms := []

	for cell in get_used_cells(platforms_layer):

		if cell.y > MIN_BRANCH_ROW:
			continue

		var atlas = get_cell_atlas_coords(
			platforms_layer,
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


func get_trunk_edges(trees_layer: int) -> Dictionary:
	var rows := {}

	for cell in get_used_cells(trees_layer):
		var atlas = get_cell_atlas_coords(trees_layer, cell)

		var is_left_edge = atlas.x == 15 and atlas.y >= 0 and atlas.y <= 5
		var is_right_edge = atlas.x == 17 and atlas.y >= 0 and atlas.y <= 5

		if is_left_edge or is_right_edge:
			if not rows.has(cell.y):
				rows[cell.y] = []

			rows[cell.y].append(cell.x)

	return rows



func get_trunk_tiles(trees_layer: int) -> Dictionary:
	var rows := {}

	for cell in get_used_cells(trees_layer):
		var atlas = get_cell_atlas_coords(trees_layer, cell)

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


func get_platform_lookup(platforms: Array) -> Dictionary:
	var lookup := {}

	for platform in platforms:
		lookup[platform["cell"]] = platform

	return lookup


func find_platform_cluster(
	start_platform: Dictionary,
	lookup: Dictionary,
	trunk_tiles: Dictionary
) -> Array:

	var cluster := []
	var open := [start_platform]
	var visited := {}

	var trunks = get_trunk_edges(
		get_layer_index_by_name("Trees")
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

			var platform_distance = abs(
				neighbor_pos.x - cell.x
			)

			#
			# Always merge directly adjacent
			# platform tiles.
			#
			if platform_distance <= 1:
				open.append(
					lookup[neighbor_pos]
				)
				continue

			var current_trunk_distance = INF
			var neighbor_trunk_distance = INF

			if trunks.has(cell.y):

				for trunk_x in trunks[cell.y]:

					current_trunk_distance = min(
						current_trunk_distance,
						abs(trunk_x - cell.x)
					)

					neighbor_trunk_distance = min(
						neighbor_trunk_distance,
						abs(trunk_x - neighbor_pos.x)
					)

			var trunk_distance = min(
				current_trunk_distance,
				neighbor_trunk_distance
			)

			#
			# Trunks win ties.
			#
			if trunk_distance <= platform_distance:
				continue

			open.append(
				lookup[neighbor_pos]
			)

	return cluster


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
		Vector2i(14, 8),
		Vector2i(14, 9)
	].pick_random()

	var end_cap = [
		Vector2i(18, 7),
		Vector2i(18, 8),
		Vector2i(18, 9)
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
				atlas = connector
			else:
				atlas = get_branch_tile()

			set_cell(
				branch_layer,
				Vector2i(x, row_y),
				TILESET_SOURCE_ID,
				atlas
			)

		var endcap_pos = Vector2i(
			right_x + 1,
			row_y
		)

		if get_cell_source_id(
			branch_layer,
			endcap_pos
		) == -1:

			set_cell(
				branch_layer,
				endcap_pos,
				TILESET_SOURCE_ID,
				end_cap
			)

	else:

		for x in support_positions:

			var atlas : Vector2i

			if has_trunk and x == connector_x:
				atlas = connector
			else:
				atlas = get_branch_tile()

			set_cell(
				branch_layer,
				Vector2i(x, row_y),
				TILESET_SOURCE_ID,
				atlas,
				TileSetAtlasSource.TRANSFORM_FLIP_H
			)

		var endcap_pos = Vector2i(
			left_x - 1,
			row_y
		)

		if get_cell_source_id(
			branch_layer,
			endcap_pos
		) == -1:

			set_cell(
				branch_layer,
				endcap_pos,
				TILESET_SOURCE_ID,
				end_cap,
				TileSetAtlasSource.TRANSFORM_FLIP_H
			)


func get_branch_tile() -> Vector2i:
	return [
		Vector2i(15, 7),
		Vector2i(16, 7),
		Vector2i(17, 7),

		Vector2i(15, 8),
		Vector2i(16, 8),
		Vector2i(17, 8),

		Vector2i(15, 9),
		Vector2i(16, 9),
		Vector2i(17, 9)
	].pick_random()


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


func get_falling_platforms() -> Array:

	var result := []

	var level = get_parent().get_parent()

	if level == null:
		return result

	for child in level.get_children():

		if child.name != "DynamicObjects":
			continue

		for node in get_dynamic_objects():

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

	for node in get_dynamic_objects():

		if not node.is_in_group("bouncy"):
			continue

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

	for node in get_dynamic_objects():

		if not node.is_in_group("swing_branch"):
			continue

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


func get_dynamic_objects() -> Array:

	var result := []

	var level = get_parent().get_parent()

	if level == null:
		return result

	var dynamic_objects = level.get_node_or_null(
		"DynamicObjects"
	)

	if dynamic_objects == null:
		return result

	var stack = [dynamic_objects]

	while stack.size() > 0:

		var current = stack.pop_back()

		for child in current.get_children():

			result.append(child)

			stack.append(child)

	return result
