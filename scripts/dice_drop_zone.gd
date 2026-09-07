extends PanelContainer

signal die_dropped(action: String, index: int)

var action := ""


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.get("kind", "") == "die"


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if _can_drop_data(_at_position, data):
		die_dropped.emit(action, int(data.index))
