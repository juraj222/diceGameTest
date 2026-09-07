extends Control

const BIOMES = preload("res://scripts/biomes.gd")
signal cell_clicked(coord: Vector2i)

const CELL := 76.0

var game: GameState
var pan: Vector2 = Vector2.ZERO
var zoom: float = 1.0
var _dragging := false
var _drag_from := Vector2.ZERO
var _pan_from := Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true


func _origin() -> Vector2:
	return size * 0.5 + pan


func _cell_size() -> float:
	return CELL * zoom


func world_to_cell(local: Vector2) -> Vector2i:
	var p: Vector2 = (local - _origin()) / _cell_size()
	return Vector2i(floori(p.x), floori(p.y))


func cell_to_rect(coord: Vector2i) -> Rect2:
	var cell_size := _cell_size()
	var pos: Vector2 = _origin() + Vector2(coord) * cell_size
	return Rect2(pos, Vector2(cell_size, cell_size)).grow(3.0 - cell_size * 0.08)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			_dragging = mb.pressed
			_drag_from = mb.position
			_pan_from = pan
			accept_event()
		elif mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			cell_clicked.emit(world_to_cell(mb.position))
			accept_event()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			zoom = minf(1.35, zoom * 1.08)
			queue_redraw()
			accept_event()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			zoom = maxf(0.75, zoom / 1.08)
			queue_redraw()
			accept_event()
	elif event is InputEventMouseMotion and _dragging:
		var mm := event as InputEventMouseMotion
		pan = _pan_from + (mm.position - _drag_from)
		queue_redraw()
		accept_event()


func _get_tooltip(at_position: Vector2) -> String:
	if game == null:
		return ""
	var coord := world_to_cell(at_position)
	if not game.cells.has(coord):
		return ""
	var task = game.cells[coord].get("task")
	if task == null:
		return ""
	return "Task %d\n%s" % [int(task.task_id), task.description]


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if not data is Dictionary or game == null:
		return false
	var coord := world_to_cell(at_position)
	if data.kind == "tile":
		if data.index < 0 or data.index >= game.revealed.size():
			return false
		return game.can_place_tile_at(game.revealed[data.index], coord)
	if data.kind == "die":
		if data.index < 0 or data.index >= game.hand.size():
			return false
		return game.can_place_die_at(game.hand[data.index], coord)
	return false


func _drop_data(at_position: Vector2, data: Variant) -> void:
	if not _can_drop_data(at_position, data):
		return
	var coord := world_to_cell(at_position)
	if data.kind == "tile":
		game.select_tile(data.index)
		game.place_selected_tile(coord)
	elif data.kind == "die":
		game.select_die(data.index)
		game.place_selected_die(coord)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.055, 0.07, 0.08), true)
	draw_circle(_origin(), 360.0, Color(0.08, 0.12, 0.12, 0.45))
	var title_font := ThemeDB.fallback_font
	draw_string(title_font, Vector2(28, 40), "BIOME MAP", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.72, 0.82, 0.78))
	draw_string(title_font, Vector2(28, 64), "Left click to place  •  Right drag to pan  •  Scroll to nudge", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.45, 0.55, 0.54))
	if game == null:
		return
	if game.level >= 2 and game.placed_map_tile_count > 0:
		var boundary_center := _origin() + (Vector2(game.board_center) + Vector2(0.5, 0.5)) * _cell_size()
		var boundary_radius := float(game._boundary_radius()) * _cell_size()
		draw_arc(boundary_center, boundary_radius, 0.0, TAU, 96, Color(1, 0.86, 0.38, 0.7), 2.0)
		draw_string(title_font, boundary_center + Vector2(12, -boundary_radius - 8), "LEVEL %d CIRCLE" % game.level, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 0.86, 0.38, 0.85))
	_draw_grid()
	var highlights: Array[Vector2i] = game.valid_coords_for_selected_tile()
	for coord in highlights:
		draw_rect(cell_to_rect(coord), Color(1, 1, 1, 0.16), true)
		draw_rect(cell_to_rect(coord), Color(1, 0.92, 0.45, 0.85), false, 2.0)
	for key in game.cells.keys():
		_draw_cell(key, game.cells[key])
	if game.phase == GameState.Phase.PLACE_DICE and game.selected_die >= 0:
		var die: Dictionary = game.hand[game.selected_die]
		for key in game.cells.keys():
			var coord: Vector2i = key
			if game.can_place_die_at(die, coord):
				draw_rect(cell_to_rect(coord), Color(1, 1, 1, 0.22), true)
				draw_rect(cell_to_rect(coord), Color(1, 0.85, 0.3, 1), false, 2.5)


func _draw_grid() -> void:
	var origin := _origin()
	var col := Color(1, 1, 1, 0.05)
	var min_c := Vector2i(-18, -12)
	var max_c := Vector2i(18, 12)
	for x in range(min_c.x, max_c.x + 1):
		var cell_size := _cell_size()
		var a: Vector2 = origin + Vector2(x * cell_size, min_c.y * cell_size)
		var b: Vector2 = origin + Vector2(x * cell_size, max_c.y * cell_size)
		draw_line(a, b, col, 1.0)
	for y in range(min_c.y, max_c.y + 1):
		var cell_size := _cell_size()
		var a: Vector2 = origin + Vector2(min_c.x * cell_size, y * cell_size)
		var b: Vector2 = origin + Vector2(max_c.x * cell_size, y * cell_size)
		draw_line(a, b, col, 1.0)


func _draw_cell(coord: Vector2i, cell: Dictionary) -> void:
	var rect := cell_to_rect(coord)
	var biome: int = int(cell.biome)
	var fill := BIOMES.color(biome)
	var edge := BIOMES.dark_color(biome)
	var cell_biomes: Array = cell.get("biomes", [biome])
	if int(cell.halves) == 1:
		if cell_biomes.size() > 1:
			draw_rect(Rect2(rect.position, Vector2(rect.size.x * 0.5, rect.size.y)), BIOMES.color(int(cell_biomes[0])), true)
			draw_rect(Rect2(rect.position + Vector2(rect.size.x * 0.5, 0), Vector2(rect.size.x * 0.5, rect.size.y)), BIOMES.color(int(cell_biomes[1])), true)
		else:
			draw_rect(rect, BIOMES.color(int(cell_biomes[0])), true)
		draw_rect(rect, edge, false, 2.0)
		_draw_label(rect, "½", Color(1, 1, 1, 0.9))
	else:
		if cell_biomes.size() > 1:
			draw_rect(Rect2(rect.position, Vector2(rect.size.x * 0.5, rect.size.y)), BIOMES.color(int(cell_biomes[0])), true)
			draw_rect(Rect2(rect.position + Vector2(rect.size.x * 0.5, 0), Vector2(rect.size.x * 0.5, rect.size.y)), BIOMES.color(int(cell_biomes[1])), true)
		else:
			draw_rect(rect, fill, true)
		draw_rect(rect, edge, false, 2.5)
		if bool(cell.was_full):
			_draw_label(Rect2(rect.position, Vector2(rect.size.x, 22)), BIOMES.display_name(biome), Color(0, 0, 0, 0.55))
		else:
			_draw_label(Rect2(rect.position, Vector2(rect.size.x, 22)), "joined", Color(0, 0, 0, 0.55))
	var placed_die = cell.get("die")
	if placed_die != null:
		var die: Dictionary = placed_die
		var cube := Rect2(rect.position + rect.size * 0.28, rect.size * 0.44)
		draw_rect(cube, BIOMES.color(int(die.biome)), true)
		draw_rect(cube, Color(0.08, 0.08, 0.1), false, 2.0)
		_draw_label(cube, str(int(die.value)), Color.WHITE)
	var task = cell.get("task")
	if task != null:
		var marker := Rect2(rect.position + Vector2(rect.size.x - 24, 4), Vector2(20, 20))
		draw_rect(marker, Color(0.72, 0.12, 0.14), true)
		draw_rect(marker, Color(1, 0.5, 0.45), false, 1.5)
		_draw_label(marker, "T", Color.WHITE)


func _draw_label(rect: Rect2, text: String, color: Color) -> void:
	var font := ThemeDB.fallback_font
	var size_px := 14 if text.length() > 2 else 22
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, size_px)
	var pos := rect.position + (rect.size - text_size) * 0.5 + Vector2(0, text_size.y * 0.8)
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, color)
