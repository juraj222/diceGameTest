class_name GameState
extends RefCounted

const BIOMES = preload("res://scripts/biomes.gd")
enum Phase { PLACE_TILES, PLACE_DICE, GAME_OVER }

signal changed

var round_index: int = 0
var phase: Phase = Phase.PLACE_TILES
var pile: Array[Dictionary] = []
var revealed: Array[Dictionary] = []
var bag: Array[Dictionary] = []
var task_pile: Array[Dictionary] = []
var hand: Array[Dictionary] = []
var kept: Array[Dictionary] = []
var cells: Dictionary = {}
var task_placements: Array[Dictionary] = []
var tile_history: Array[Dictionary] = []
var die_history: Array[Dictionary] = []
var selected_tile: int = -1
var selected_die: int = -1
var message: String = ""
var level: int = 1
var board_center: Vector2i = Vector2i.ZERO
var placed_map_tile_count: int = 0


func start_game() -> void:
	round_index = 0
	phase = Phase.PLACE_TILES
	pile.clear()
	revealed.clear()
	bag.clear()
	task_pile.clear()
	hand.clear()
	kept.clear()
	cells.clear()
	task_placements.clear()
	tile_history.clear()
	die_history.clear()
	selected_tile = -1
	selected_die = -1
	level = 1
	board_center = Vector2i.ZERO
	placed_map_tile_count = 0
	_build_components()
	_begin_round()
	changed.emit()


func _build_components() -> void:
	var paired_biome := {
		BIOMES.Id.MOUNTAIN: BIOMES.Id.FOREST,
		BIOMES.Id.FOREST: BIOMES.Id.MEADOW,
		BIOMES.Id.MEADOW: BIOMES.Id.WATER,
		BIOMES.Id.WATER: BIOMES.Id.MOUNTAIN,
	}
	for biome in BIOMES.all_ids():
		for _i in 6:
			pile.append({"biome": biome, "biomes": [biome], "is_half": false})
		for _i in 4:
			pile.append({
				"biome": biome,
				"biomes": [biome, paired_biome[biome]],
				"is_half": true,
			})
		for _i in 5:
			bag.append({"biome": biome, "value": 1})
	pile.shuffle()
	bag.shuffle()
	for task_id in range(1, 17):
		task_pile.append(_task_definition(task_id))
	task_pile.shuffle()


func _add_level_components(unlocked_level: int) -> void:
	var ids := BIOMES.all_ids()
	var offset := (unlocked_level - 2) * 2
	for biome in ids:
		pile.append({"biome": biome, "biomes": [biome], "is_half": false})
		pile.append({
			"biome": biome,
			"biomes": [biome, (biome + 1) % ids.size()],
			"is_half": true,
		})
	for i in 2:
		var extra_biome: int = ids[(offset + i) % ids.size()]
		pile.append({"biome": extra_biome, "biomes": [extra_biome], "is_half": false})
	for i in 10:
		var die_biome: int = ids[(offset + i) % ids.size()]
		bag.append({"biome": die_biome, "value": 1})
	pile.shuffle()
	bag.shuffle()


func _begin_round() -> void:
	round_index += 1
	tile_history.clear()
	die_history.clear()
	selected_tile = -1
	selected_die = -1
	var take: int = mini(5, pile.size())
	revealed.clear()
	for _i in take:
		revealed.append(pile.pop_back())
	if level >= 3 and not task_pile.is_empty():
		revealed.append(task_pile.pop_back())
	hand.clear()
	hand.append_array(kept)
	kept.clear()
	var need: int = 5 - hand.size()
	while need > 0 and not bag.is_empty():
		hand.append(bag.pop_back())
		need -= 1
	for die in hand:
		die.value = randi_range(1, 6)
	if revealed.is_empty() and hand.is_empty():
		phase = Phase.GAME_OVER
		message = "No tiles left. Final scoring."
		return
	if revealed.is_empty():
		phase = Phase.PLACE_DICE
		message = "No map tiles remain. Resolve the carried dice."
	else:
		phase = Phase.PLACE_TILES
		message = "Place all revealed tiles on the board."


func occupied() -> bool:
	return not cells.is_empty()


func get_cell(coord: Vector2i) -> Dictionary:
	if cells.has(coord):
		return cells[coord]
	return {}


func is_complete(cell: Dictionary) -> bool:
	return not cell.is_empty() and int(cell.get("halves", 0)) >= 2


func _neighbors(coord: Vector2i) -> Array[Vector2i]:
	return [
		coord + Vector2i(1, 0),
		coord + Vector2i(-1, 0),
		coord + Vector2i(0, 1),
		coord + Vector2i(0, -1),
	]


func _has_occupied_neighbor(coord: Vector2i) -> bool:
	for n in _neighbors(coord):
		if cells.has(n):
			return true
	return false


func _adjacency_ok_for_new_piece(coord: Vector2i, existing: Dictionary) -> bool:
	if not existing.is_empty():
		return true
	if not occupied():
		return true
	return _has_occupied_neighbor(coord)


func _boundary_radius() -> int:
	if placed_map_tile_count <= 0:
		return 0
	return ceili(sqrt(float(placed_map_tile_count) * 1.3 / PI))


func _inside_level_boundary(coord: Vector2i) -> bool:
	if level < 2 or placed_map_tile_count <= 0:
		return true
	return Vector2(coord).distance_to(Vector2(board_center)) <= float(_boundary_radius())


func can_place_tile_at(tile: Dictionary, coord: Vector2i) -> bool:
	if bool(tile.get("is_task", false)):
		# v5 does not assign a biome to task cards. Treat them as objective
		# overlays on completed map cells so every task can inspect "this tile".
		var task_cell: Dictionary = get_cell(coord)
		return is_complete(task_cell) and task_cell.get("task") == null
	var existing: Dictionary = get_cell(coord)
	if not _adjacency_ok_for_new_piece(coord, existing):
		return false
	if not _inside_level_boundary(coord):
		return false
	if tile.is_half:
		if existing.is_empty():
			return true
		if is_complete(existing):
			return false
		return existing.get("biomes", [existing.biome]) == tile.get("biomes", [tile.biome])
	return existing.is_empty()


func valid_coords_for_selected_tile() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if selected_tile < 0 or selected_tile >= revealed.size():
		return result
	var tile: Dictionary = revealed[selected_tile]
	var candidates: Dictionary = {}
	if bool(tile.get("is_task", false)):
		for key in cells.keys():
			candidates[key] = true
	else:
		for dx in range(-10, 11):
			for dy in range(-8, 9):
				candidates[Vector2i(dx, dy)] = true
	for key in cells.keys():
		var occupied_coord: Vector2i = key
		candidates[occupied_coord] = true
		for n in _neighbors(occupied_coord):
			candidates[n] = true
	for key in candidates.keys():
		var coord: Vector2i = key
		if can_place_tile_at(tile, coord):
			result.append(coord)
	return result


func place_selected_tile(coord: Vector2i) -> bool:
	if phase != Phase.PLACE_TILES:
		return false
	if selected_tile < 0 or selected_tile >= revealed.size():
		return false
	var tile: Dictionary = revealed[selected_tile]
	if not can_place_tile_at(tile, coord):
		message = "That cell is not a legal placement."
		changed.emit()
		return false
	var prev: Dictionary = get_cell(coord).duplicate()
	if bool(tile.get("is_task", false)):
		cells[coord]["task"] = tile.duplicate()
		task_placements.append({"task": tile.duplicate(), "coord": coord})
		tile_history.append({"kind": "task", "coord": coord, "tile": tile, "prev": prev, "index": selected_tile})
	else:
		var previous_center := board_center
		var previous_count := placed_map_tile_count
		if placed_map_tile_count == 0:
			board_center = coord
		placed_map_tile_count += 1
		if tile.is_half:
			if cells.has(coord):
				cells[coord].halves = 2
			else:
				cells[coord] = {
					"biome": tile.biome,
					"biomes": tile.get("biomes", [tile.biome]),
					"halves": 1,
					"was_full": false,
					"die": null,
					"task": null,
				}
		else:
			cells[coord] = {
				"biome": tile.biome,
				"biomes": tile.get("biomes", [tile.biome]),
				"halves": 2,
				"was_full": true,
				"die": null,
				"task": null,
			}
		tile_history.append({
			"kind": "map",
			"coord": coord,
			"tile": tile,
			"prev": prev,
			"index": selected_tile,
			"previous_center": previous_center,
			"previous_count": previous_count,
		})
	revealed.remove_at(selected_tile)
	selected_tile = -1
	if revealed.is_empty():
		phase = Phase.PLACE_DICE
		message = "Place matching dice, or keep / return unused ones."
	else:
		message = "Tiles left to place: %d" % revealed.size()
	changed.emit()
	return true


func undo_tile() -> void:
	if tile_history.is_empty() or phase == Phase.GAME_OVER:
		return
	if phase == Phase.PLACE_DICE and not die_history.is_empty():
		return
	var step: Dictionary = tile_history.pop_back()
	var coord: Vector2i = step.coord
	var prev: Dictionary = step.prev
	if prev.is_empty():
		cells.erase(coord)
	else:
		cells[coord] = prev
	if step.get("kind", "map") == "task":
		for i in range(task_placements.size() - 1, -1, -1):
			if task_placements[i].coord == coord:
				task_placements.remove_at(i)
				break
	else:
		board_center = step.previous_center
		placed_map_tile_count = int(step.previous_count)
	revealed.insert(mini(int(step.index), revealed.size()), step.tile)
	phase = Phase.PLACE_TILES
	selected_tile = -1
	message = "Tile placement undone."
	changed.emit()


func can_place_die_at(die: Dictionary, coord: Vector2i) -> bool:
	if not cells.has(coord):
		return false
	var cell: Dictionary = cells[coord]
	if cell.get("die") != null:
		return false
	return int(die.biome) in cell.get("biomes", [cell.biome])


func place_selected_die(coord: Vector2i) -> bool:
	if phase != Phase.PLACE_DICE:
		return false
	if selected_die < 0 or selected_die >= hand.size():
		return false
	var die: Dictionary = hand[selected_die]
	if not can_place_die_at(die, coord):
		message = "Dice only go on an occupied tile of a matching biome."
		changed.emit()
		return false
	cells[coord]["die"] = die.duplicate()
	die_history.append({"kind": "place", "coord": coord, "die": die.duplicate(), "index": selected_die})
	hand.remove_at(selected_die)
	selected_die = -1
	_update_level()
	_after_die_action()
	return true


func keep_selected_die() -> bool:
	if phase != Phase.PLACE_DICE:
		return false
	if selected_die < 0 or selected_die >= hand.size():
		return false
	var die: Dictionary = hand[selected_die]
	kept.append(die)
	die_history.append({"kind": "keep", "die": die, "index": selected_die})
	hand.remove_at(selected_die)
	selected_die = -1
	_after_die_action()
	return true


func bag_selected_die() -> bool:
	if phase != Phase.PLACE_DICE:
		return false
	if selected_die < 0 or selected_die >= hand.size():
		return false
	var die: Dictionary = hand[selected_die]
	bag.append(die)
	bag.shuffle()
	die_history.append({"kind": "bag", "die": die, "index": selected_die})
	hand.remove_at(selected_die)
	selected_die = -1
	_after_die_action()
	return true


func undo_die() -> void:
	if die_history.is_empty() or phase == Phase.GAME_OVER:
		return
	var step: Dictionary = die_history.pop_back()
	var die: Dictionary = step.die
	if step.kind == "place":
		var coord: Vector2i = step.coord
		if cells.has(coord):
			cells[coord].die = null
	elif step.kind == "keep":
		kept.erase(die)
	elif step.kind == "bag":
		bag.erase(die)
	hand.insert(mini(int(step.index), hand.size()), die)
	phase = Phase.PLACE_DICE
	selected_die = -1
	message = "Dice action undone."
	changed.emit()


func _after_die_action() -> void:
	if hand.is_empty():
		if kept.is_empty() and pile.is_empty() and (level < 3 or task_pile.is_empty()):
			phase = Phase.GAME_OVER
			message = "The pile is empty. Game over — see your score."
		else:
			message = "Round complete. Start the next round."
	else:
		message = "Dice left this round: %d" % hand.size()
	changed.emit()


func next_round() -> void:
	if phase == Phase.GAME_OVER:
		return
	if not revealed.is_empty() or not hand.is_empty():
		message = "Finish placing tiles and resolving dice first."
		changed.emit()
		return
	_begin_round()
	changed.emit()


func select_tile(index: int) -> void:
	if phase != Phase.PLACE_TILES:
		return
	selected_tile = index
	selected_die = -1
	changed.emit()


func select_die(index: int) -> void:
	if phase != Phase.PLACE_DICE:
		return
	selected_die = index
	selected_tile = -1
	changed.emit()


func _update_level() -> void:
	var base_score := int(score_report().base_total)
	if level == 1 and base_score >= 125:
		level = 2
		_add_level_components(level)
		message = "Level 2 unlocked: the map now grows inside a circular boundary."
	if level == 2 and base_score >= 150:
		level = 3
		_add_level_components(level)
		message = "Level 3 unlocked: task tiles will be drawn from the next round."


func _task_definition(task_id: int) -> Dictionary:
	var descriptions := {
		1: "All dice in this row have value 5.",
		2: "All 4 orthogonal neighbors have die value 1.",
		3: "This tile is surrounded by Mountain on all 4 sides.",
		4: "This tile is surrounded by Water on all 4 sides.",
		5: "All dice in this column have value 6.",
		6: "The 4 orthogonal neighbor dice sum to exactly 10.",
		7: "Two opposite diagonal neighbors have the same die value.",
		8: "This tile's biome region has at least 5 tiles.",
		9: "None of the orthogonal neighbors share this biome.",
		10: "The 4 orthogonal neighbors are all different biomes.",
		11: "This tile does not neighbor Water.",
		12: "The die on this tile has an even value.",
		13: "The die on this tile is odd and at least 3.",
		14: "At least 3 orthogonal neighbors have dice.",
		15: "This tile sits on the final circular map boundary.",
		16: "This die plus a diagonal neighbor is a multiple of 5.",
	}
	return {
		"is_task": true,
		"task_id": task_id,
		"description": descriptions[task_id],
	}


func score_report() -> Dictionary:
	var base_total: int = 0
	var details: Array = []
	for region in _largest_biome_regions():
		var values: Array[int] = []
		for coord in region.coords:
			var cell: Dictionary = cells[coord]
			if cell.get("die") != null:
				values.append(int(cell.die.value))
		var basic: int = 0
		for v in values:
			basic += v
		var series: Dictionary = _series_bonus(values)
		var subtotal: int = basic + int(series.bonus)
		base_total += subtotal
		details.append({
			"biome": region.biome,
			"size": region.coords.size(),
			"dice": values,
			"basic": basic,
			"bonus": series.bonus,
			"runs": series.runs,
			"subtotal": subtotal,
		})
	var task_result := {"bonus": 0, "completed": []}
	if phase == Phase.GAME_OVER:
		task_result = _task_score()
	return {
		"total": base_total + int(task_result.bonus),
		"base_total": base_total,
		"task_bonus": task_result.bonus,
		"tasks": task_result.completed,
		"regions": details,
	}


func _largest_biome_regions() -> Array:
	var regions: Array = []
	for biome in BIOMES.all_ids():
		var seen: Dictionary = {}
		var largest: Dictionary = {}
		for key in cells.keys():
			var start: Vector2i = key
			if seen.has(start) or not _cell_has_biome(cells[start], biome):
				continue
			var queue: Array[Vector2i] = [start]
			var coords: Array[Vector2i] = []
			seen[start] = true
			while not queue.is_empty():
				var cur: Vector2i = queue.pop_back()
				coords.append(cur)
				for n in _neighbors(cur):
					if seen.has(n) or not cells.has(n):
						continue
					if not _cell_has_biome(cells[n], biome):
						continue
					seen[n] = true
					queue.append(n)
			if largest.is_empty() or coords.size() > largest.coords.size():
				largest = {"biome": biome, "coords": coords}
		if not largest.is_empty():
			regions.append(largest)
	return regions


func _cell_has_biome(cell: Dictionary, biome: int) -> bool:
	return biome in cell.get("biomes", [cell.get("biome", -1)])


func _series_bonus(values: Array[int]) -> Dictionary:
	var unique: Dictionary = {}
	for v in values:
		unique[v] = true
	var nums: Array = unique.keys()
	nums.sort()
	var best_run: Array = []
	var i: int = 0
	while i < nums.size():
		var j: int = i
		while j + 1 < nums.size() and int(nums[j + 1]) == int(nums[j]) + 1:
			j += 1
		var length: int = j - i + 1
		if length >= BIOMES.SERIES_MIN_LENGTH and length > best_run.size():
			var run: Array = nums.slice(i, j + 1)
			best_run = run
		i = j + 1
	var bonus := 0 if best_run.size() < BIOMES.SERIES_MIN_LENGTH else best_run.size() * BIOMES.SERIES_POINTS_PER_STEP
	var runs: Array = [] if best_run.is_empty() else [best_run]
	return {"bonus": bonus, "runs": runs}


func _task_score() -> Dictionary:
	var completed: Array = []
	for placement in task_placements:
		var task: Dictionary = placement.task
		var coord: Vector2i = placement.coord
		var success := _task_completed(task, coord)
		completed.append({
			"id": int(task.task_id),
			"description": task.description,
			"coord": coord,
			"completed": success,
			"points": 10 if success else 0,
		})
	return {"bonus": completed.filter(func(item: Dictionary) -> bool: return item.completed).size() * 10, "completed": completed}


func _die_value_at(coord: Vector2i) -> int:
	if not cells.has(coord):
		return -1
	var die = cells[coord].get("die")
	return -1 if die == null else int(die.value)


func _orthogonal_dice(coord: Vector2i) -> Array[int]:
	var values: Array[int] = []
	for neighbor in _neighbors(coord):
		var value := _die_value_at(neighbor)
		if value < 0:
			return []
		values.append(value)
	return values


func _line_dice(coord: Vector2i, horizontal: bool) -> Array[int]:
	var values: Array[int] = []
	for key in cells.keys():
		var candidate: Vector2i = key
		if (horizontal and candidate.y != coord.y) or (not horizontal and candidate.x != coord.x):
			continue
		var value := _die_value_at(candidate)
		if value >= 0:
			values.append(value)
	return values


func _diagonal_coords(coord: Vector2i) -> Array[Vector2i]:
	return [
		coord + Vector2i(1, 1),
		coord + Vector2i(1, -1),
		coord + Vector2i(-1, 1),
		coord + Vector2i(-1, -1),
	]


func _region_at(coord: Vector2i) -> Array[Vector2i]:
	if not cells.has(coord):
		return []
	var biome := int(cells[coord].biome)
	var queue: Array[Vector2i] = [coord]
	var seen: Dictionary = {coord: true}
	var result: Array[Vector2i] = []
	while not queue.is_empty():
		var current: Vector2i = queue.pop_back()
		result.append(current)
		for neighbor in _neighbors(current):
			if seen.has(neighbor) or not cells.has(neighbor):
				continue
			if not _cell_has_biome(cells[neighbor], biome):
				continue
			seen[neighbor] = true
			queue.append(neighbor)
	return result


func _task_completed(task: Dictionary, coord: Vector2i) -> bool:
	var task_id := int(task.task_id)
	var target_die := _die_value_at(coord)
	var neighbors := _neighbors(coord)
	match task_id:
		1:
			var row := _line_dice(coord, true)
			return not row.is_empty() and row.all(func(value: int) -> bool: return value == 5)
		2:
			var values := _orthogonal_dice(coord)
			return values.size() == 4 and values.all(func(value: int) -> bool: return value == 1)
		3, 4:
			var required_biome := BIOMES.Id.MOUNTAIN if task_id == 3 else BIOMES.Id.WATER
			for neighbor in neighbors:
				if not cells.has(neighbor) or not _cell_has_biome(cells[neighbor], required_biome):
					return false
			return true
		5:
			var column := _line_dice(coord, false)
			return not column.is_empty() and column.all(func(value: int) -> bool: return value == 6)
		6:
			var sum_values := _orthogonal_dice(coord)
			if sum_values.size() != 4:
				return false
			var total := 0
			for value in sum_values:
				total += value
			return total == 10
		7:
			var diagonals := _diagonal_coords(coord)
			return (_die_value_at(diagonals[0]) >= 0 and _die_value_at(diagonals[0]) == _die_value_at(diagonals[3])) or (_die_value_at(diagonals[1]) >= 0 and _die_value_at(diagonals[1]) == _die_value_at(diagonals[2]))
		8:
			return _region_at(coord).size() >= 5
		9:
			var biomes: Array = cells[coord].get("biomes", [cells[coord].biome])
			for neighbor in neighbors:
				if cells.has(neighbor):
					for biome in biomes:
						if _cell_has_biome(cells[neighbor], int(biome)):
							return false
			return true
		10:
			var neighbor_biomes: Dictionary = {}
			for neighbor in neighbors:
				if not cells.has(neighbor):
					return false
				neighbor_biomes[int(cells[neighbor].biome)] = true
			return neighbor_biomes.size() == 4
		11:
			for neighbor in neighbors:
				if cells.has(neighbor) and _cell_has_biome(cells[neighbor], BIOMES.Id.WATER):
					return false
			return true
		12:
			return target_die >= 0 and target_die % 2 == 0
		13:
			return target_die >= 3 and target_die % 2 == 1
		14:
			var dice_count := 0
			for neighbor in neighbors:
				if _die_value_at(neighbor) >= 0:
					dice_count += 1
			return dice_count >= 3
		15:
			if level < 2 or placed_map_tile_count <= 0:
				return false
			var radius := float(_boundary_radius())
			var distance := Vector2(coord).distance_to(Vector2(board_center))
			if distance > radius:
				return false
			for neighbor in neighbors:
				if Vector2(neighbor).distance_to(Vector2(board_center)) > radius:
					return true
			return distance >= radius - 1.0
		16:
			if target_die < 0:
				return false
			for diagonal in _diagonal_coords(coord):
				var diagonal_die := _die_value_at(diagonal)
				if diagonal_die >= 0 and (target_die + diagonal_die) % 5 == 0:
					return true
			return false
	return false
