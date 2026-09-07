class_name Biomes
extends Object

enum Id { MOUNTAIN, FOREST, MEADOW, WATER }

const SERIES_MIN_LENGTH := 3
const SERIES_POINTS_PER_STEP := 5


static func all_ids() -> Array[int]:
	return [Id.MOUNTAIN, Id.FOREST, Id.MEADOW, Id.WATER]


static func display_name(biome: int) -> String:
	match biome:
		Id.MOUNTAIN:
			return "Mountain"
		Id.FOREST:
			return "Forest"
		Id.MEADOW:
			return "Meadow"
		Id.WATER:
			return "Water"
		_:
			return "Unknown"


static func tile_name(tile: Dictionary) -> String:
	if not bool(tile.get("is_half", false)):
		return display_name(int(tile.biome))
	var pair: Array = tile.get("biomes", [tile.biome, tile.biome])
	if pair.size() < 2:
		return display_name(int(pair[0]))
	if pair.size() == 2 and int(pair[0]) == int(pair[1]):
		return "Half %s" % display_name(int(pair[0]))
	return "%s / %s" % [display_name(int(pair[0])), display_name(int(pair[1]))]


static func tile_biomes(tile: Dictionary) -> Array:
	if tile.has("biomes"):
		return tile.biomes
	return [tile.biome]


static func tile_colors(tile: Dictionary) -> Array:
	var result: Array = []
	for biome in tile_biomes(tile):
		result.append(color(int(biome)))
	return result


static func color(biome: int) -> Color:
	match biome:
		Id.MOUNTAIN:
			return Color(0.62, 0.58, 0.54)
		Id.FOREST:
			return Color(0.23, 0.52, 0.30)
		Id.MEADOW:
			return Color(0.78, 0.82, 0.34)
		Id.WATER:
			return Color(0.28, 0.52, 0.78)
		_:
			return Color(0.4, 0.4, 0.4)


static func dark_color(biome: int) -> Color:
	return color(biome).darkened(0.35)
