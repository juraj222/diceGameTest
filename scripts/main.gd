extends Control

var game: GameState

@onready var board: Control = $BoardView
@onready var hud: Control = $HUD
@onready var background: ColorRect = $Background


func _ready() -> void:
	randomize()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.color = Color(0.09, 0.10, 0.12)
	board.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	board.anchor_right = 0.70
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.anchor_left = 0.70
	game = GameState.new()
	board.game = game
	hud.game = game
	game.changed.connect(_refresh)
	board.cell_clicked.connect(_on_cell_clicked)
	hud.tile_chosen.connect(func(i: int) -> void: game.select_tile(i))
	hud.die_chosen.connect(func(i: int) -> void: game.select_die(i))
	hud.keep_pressed.connect(func() -> void: game.keep_selected_die())
	hud.bag_pressed.connect(func() -> void: game.bag_selected_die())
	hud.undo_pressed.connect(_on_undo)
	hud.next_pressed.connect(func() -> void: game.next_round())
	hud.restart_pressed.connect(func() -> void: game.start_game())
	game.start_game()


func _refresh() -> void:
	board.queue_redraw()
	hud.refresh()


func _on_cell_clicked(coord: Vector2i) -> void:
	if game.phase == GameState.Phase.PLACE_TILES:
		game.place_selected_tile(coord)
	elif game.phase == GameState.Phase.PLACE_DICE:
		game.place_selected_die(coord)


func _on_undo() -> void:
	if game.phase == GameState.Phase.PLACE_DICE and not game.die_history.is_empty():
		game.undo_die()
	else:
		game.undo_tile()
