extends Button

var drag_kind: String = ""
var drag_index: int = -1
var drag_color := Color.WHITE


func _get_drag_data(_at_position: Vector2) -> Variant:
	if drag_index < 0:
		return null
	var preview := Label.new()
	preview.text = text
	preview.add_theme_font_size_override("font_size", 18)
	preview.add_theme_color_override("font_color", Color(0.08, 0.08, 0.1))
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = drag_color
	style.set_corner_radius_all(8)
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", style)
	panel.add_child(preview)
	set_drag_preview(panel)
	return {"kind": drag_kind, "index": drag_index}
