extends Control

const BIOMES = preload("res://scripts/biomes.gd")
const DRAG_BUTTON = preload("res://scripts/drag_button.gd")
const DROP_ZONE = preload("res://scripts/dice_drop_zone.gd")
const TILE_BUTTON = preload("res://scripts/tile_button.gd")
signal tile_chosen(index: int)
signal die_chosen(index: int)
signal keep_pressed
signal bag_pressed
signal undo_pressed
signal next_pressed
signal restart_pressed

var game: GameState
var _round_label: Label
var _phase_label: Label
var _message_label: Label
var _tiles_box: HBoxContainer
var _tasks_box: HBoxContainer
var _dice_box: HBoxContainer
var _kept_label: Label
var _score_label: Label
var _next_button: Button


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()


func _build() -> void:
	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 8
	panel.offset_top = 8
	panel.offset_right = -8
	panel.offset_bottom = -8
	var pstyle := StyleBoxFlat.new()
	pstyle.bg_color = Color(0.12, 0.15, 0.17, 0.98)
	pstyle.border_color = Color(0.28, 0.36, 0.37, 0.9)
	pstyle.set_border_width_all(1)
	pstyle.set_corner_radius_all(14)
	pstyle.set_content_margin_all(20)
	panel.add_theme_stylebox_override("panel", pstyle)
	add_child(panel)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 10)
	scroll.add_child(vbox)

	var title := Label.new()
	title.text = "Biome Dice"
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(0.93, 0.95, 0.88))
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Solo tile-laying • grow biomes • score runs"
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.modulate = Color(0.75, 0.8, 0.85)
	vbox.add_child(subtitle)

	_round_label = Label.new()
	vbox.add_child(_round_label)
	_phase_label = Label.new()
	_phase_label.add_theme_color_override("font_color", Color(0.95, 0.82, 0.4))
	vbox.add_child(_phase_label)
	_message_label = Label.new()
	_message_label.add_theme_color_override("font_color", Color(0.88, 0.9, 0.84))
	_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_message_label)

	vbox.add_child(_section("Revealed tiles — drag a tile onto a highlighted board cell"))
	_tiles_box = HBoxContainer.new()
	_tiles_box.add_theme_constant_override("separation", 8)
	vbox.add_child(_tiles_box)

	vbox.add_child(_section("Level 3 task tiles — red, non-biome objectives"))
	_tasks_box = HBoxContainer.new()
	_tasks_box.add_theme_constant_override("separation", 8)
	vbox.add_child(_tasks_box)

	vbox.add_child(_section("Dice in hand — drag a die onto an occupied tile with its biome"))
	_dice_box = HBoxContainer.new()
	_dice_box.add_theme_constant_override("separation", 8)
	vbox.add_child(_dice_box)

	var die_btns := HBoxContainer.new()
	die_btns.add_theme_constant_override("separation", 8)
	vbox.add_child(die_btns)
	die_btns.add_child(_drop_zone("KEEP", "Drag here to keep for next round", Color(0.45, 0.35, 0.16)))
	die_btns.add_child(_drop_zone("BAG", "Drag here to return to bag", Color(0.25, 0.36, 0.48)))

	_kept_label = Label.new()
	_kept_label.modulate = Color(0.85, 0.78, 0.45)
	vbox.add_child(_kept_label)

	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 8)
	vbox.add_child(nav)
	nav.add_child(_btn("Undo", undo_pressed.emit))
	_next_button = _btn("Next round", next_pressed.emit)
	nav.add_child(_next_button)
	nav.add_child(_btn("New game", restart_pressed.emit))

	vbox.add_child(_section("Score"))
	_score_label = Label.new()
	_score_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_score_label)

	var rules := Label.new()
	rules.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rules.modulate = Color(0.7, 0.74, 0.78)
	rules.text = "Rules: the base supply is 40 map tiles and 20 dice. Reaching each new level adds 10 map tiles and 10 dice. Tiles are revealed in groups of up to five. Level 2 adds a growing Euclidean circle; Level 3 adds one task overlay per round; place each overlay on a completed map cell. Place every revealed tile, then place, keep, or return every die. Score only the largest connected region of each biome. Its dice sum plus one longest unique-value run of 3+ gives the subtotal. Completed tasks are worth 10 points each at game end. Drag the board with right mouse."
	vbox.add_child(rules)


func refresh() -> void:
	if game == null or _round_label == null:
		return
	_round_label.text = "Round %d    Level %d    map pile %d    dice bag %d    task pile %d" % [game.round_index, game.level, game.pile.size(), game.bag.size(), game.task_pile.size()]
	match game.phase:
		GameState.Phase.PLACE_TILES:
			_phase_label.text = "Phase: place tiles"
		GameState.Phase.PLACE_DICE:
			_phase_label.text = "Phase: place dice"
		GameState.Phase.GAME_OVER:
			_phase_label.text = "Phase: game over"
	_message_label.text = game.message
	_rebuild_tiles()
	_rebuild_dice()
	_kept_label.text = "Kept dice: %s" % _kept_text()
	_score_label.text = _score_text()
	_next_button.disabled = game.phase == GameState.Phase.GAME_OVER or not game.revealed.is_empty() or not game.hand.is_empty()
	_next_button.text = "Next round" if game.phase != GameState.Phase.GAME_OVER else "Finished"


func _section(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", Color(0.78, 0.84, 0.9))
	return label


func _btn(text: String, cb: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 36)
	button.pressed.connect(cb)
	return button


func _drop_zone(kind: String, caption: String, color: Color) -> Control:
	var zone := DROP_ZONE.new()
	zone.action = kind
	zone.custom_minimum_size = Vector2(150, 56)
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(8)
	style.set_border_width_all(1)
	style.border_color = color.lightened(0.3)
	zone.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.text = caption
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	zone.add_child(label)
	zone.die_dropped.connect(_on_die_drop_zone)
	return zone


func _on_die_drop_zone(action: String, index: int) -> void:
	game.select_die(index)
	if action == "KEEP":
		keep_pressed.emit()
	else:
		bag_pressed.emit()


func _rebuild_tiles() -> void:
	for child in _tiles_box.get_children():
		child.queue_free()
	for child in _tasks_box.get_children():
		child.queue_free()
	var map_count := 0
	var task_count := 0
	for tile in game.revealed:
		if bool(tile.get("is_task", false)):
			task_count += 1
		else:
			map_count += 1
	if map_count == 0:
		var empty := Label.new()
		empty.text = "No tiles in tray"
		_tiles_box.add_child(empty)
	if task_count == 0:
		var no_tasks := Label.new()
		no_tasks.text = "No task tile this round"
		_tasks_box.add_child(no_tasks)
	for i in game.revealed.size():
		var tile: Dictionary = game.revealed[i]
		var button: Button
		if bool(tile.get("is_task", false)):
			var task_button := DRAG_BUTTON.new()
			task_button.custom_minimum_size = Vector2(180, 66)
			task_button.text = "TASK %d\n%s" % [int(tile.task_id), tile.description]
			task_button.tooltip_text = tile.description
			task_button.drag_kind = "tile"
			task_button.drag_index = i
			task_button.drag_color = Color(0.72, 0.12, 0.14)
			button = task_button
			var task_style := StyleBoxFlat.new()
			task_style.bg_color = Color(0.48, 0.08, 0.1)
			task_style.set_corner_radius_all(8)
			task_style.set_border_width_all(2 if game.selected_tile == i else 1)
			task_style.border_color = Color(1, 0.5, 0.45)
			button.add_theme_stylebox_override("normal", task_style)
			button.add_theme_stylebox_override("hover", task_style)
			button.add_theme_stylebox_override("pressed", task_style)
		else:
			var tile_button := TILE_BUTTON.new()
			tile_button.custom_minimum_size = Vector2(78, 66)
			tile_button.text = ("½ " if tile.is_half else "") + BIOMES.tile_name(tile)
			tile_button.drag_kind = "tile"
			tile_button.drag_index = i
			tile_button.drag_color = BIOMES.color(tile.biome)
			tile_button.tile = tile
			tile_button.selected = game.selected_tile == i
			tile_button.add_theme_color_override("font_color", Color(0.08, 0.08, 0.1))
			button = tile_button
		var idx: int = i
		button.pressed.connect(func() -> void: tile_chosen.emit(idx))
		if bool(tile.get("is_task", false)):
			_tasks_box.add_child(button)
		else:
			_tiles_box.add_child(button)


func _rebuild_dice() -> void:
	for child in _dice_box.get_children():
		child.queue_free()
	if game.hand.is_empty():
		var empty := Label.new()
		empty.text = "No dice in hand"
		_dice_box.add_child(empty)
		return
	for i in game.hand.size():
		var die: Dictionary = game.hand[i]
		var button := DRAG_BUTTON.new()
		button.custom_minimum_size = Vector2(56, 56)
		button.text = "%s\n%d" % [_short(die.biome), int(die.value)]
		button.drag_kind = "die"
		button.drag_index = i
		button.drag_color = BIOMES.color(die.biome)
		var style := StyleBoxFlat.new()
		style.bg_color = BIOMES.dark_color(die.biome)
		style.set_corner_radius_all(8)
		if game.selected_die == i:
			style.bg_color = BIOMES.color(die.biome)
			style.border_color = Color(1, 0.9, 0.4)
			style.set_border_width_all(3)
		button.add_theme_stylebox_override("normal", style)
		button.add_theme_stylebox_override("hover", style)
		button.add_theme_stylebox_override("pressed", style)
		var idx: int = i
		button.pressed.connect(func() -> void: die_chosen.emit(idx))
		_dice_box.add_child(button)


func _short(biome: int) -> String:
	return BIOMES.display_name(biome).left(1)


func _kept_text() -> String:
	if game.kept.is_empty():
		return "none"
	var values: PackedStringArray = PackedStringArray()
	for die in game.kept:
		values.append("%s %d" % [_short(int(die.biome)), int(die.value)])
	return ", ".join(values)


func _score_text() -> String:
	var report: Dictionary = game.score_report()
	var lines: PackedStringArray = PackedStringArray()
	lines.append("Live base score: %d" % int(report.base_total))
	for region in report.regions:
		var run_text := ""
		if not region.runs.is_empty():
			run_text = "  series %s" % str(region.runs)
		lines.append(
			"%s (%d tiles): sum %d + bonus %d%s"
			% [BIOMES.display_name(region.biome), region.size, region.basic, region.bonus, run_text]
		)
	if int(report.task_bonus) > 0:
		lines.append("Task bonuses: +%d" % int(report.task_bonus))
	elif game.level >= 3:
		lines.append("Task bonuses: scored at game end")
	lines.append("Total: %d" % int(report.total))
	if game.phase == GameState.Phase.GAME_OVER:
		lines.append("Final total: %d" % int(report.total))
		for task in report.tasks:
			lines.append("Task %d: %s" % [int(task.id), "+10" if task.completed else "incomplete"])
	return "\n".join(lines)
