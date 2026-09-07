extends "res://scripts/drag_button.gd"

var tile: Dictionary = {}
var selected := false


func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	queue_redraw()


func _draw() -> void:
	if tile.is_empty():
		return
	var colors: Array = BIOMES.tile_colors(tile)
	if colors.size() > 1:
		draw_rect(Rect2(Vector2.ZERO, Vector2(size.x * 0.5, size.y)), colors[0], true)
		draw_rect(Rect2(Vector2(size.x * 0.5, 0), Vector2(size.x * 0.5, size.y)), colors[1], true)
	else:
		draw_rect(Rect2(Vector2.ZERO, size), colors[0], true)
	var border := Color(1, 0.92, 0.4) if selected else Color(0.08, 0.08, 0.1, 0.7)
	draw_rect(Rect2(Vector2.ZERO, size).grow(-1), border, false, 3.0 if selected else 1.5)


const BIOMES = preload("res://scripts/biomes.gd")
