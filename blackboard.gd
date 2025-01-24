class_name Blackboard

const TILE_SET := preload("sectors/tile_set.tres")
const INVALID_ATLAS_COORD := -1 * Vector2i.ONE

static var obstacles: Array[Vector2i] = []
static var sectors: Dictionary[Vector2i, Sector2D] = {}
static var enemies: Dictionary[Vector2,Enemy2D] = {}
static var half_tile_size := TILE_SET.tile_size / 2

static var sector_tile_map_layer: TileMapLayer = null
static var player: Player2D = null


static func _static_init() -> void:
	for index: int in range(TILE_SET.get_source_count()):
		var source: TileSetAtlasSource = TILE_SET.get_source(index)
		for i in source.get_tiles_count():
			var atlas_coords := source.get_tile_id(i)
			var tile_data := source.get_tile_data(atlas_coords, 0)
			if tile_data.get_occluder(0) != null:
				obstacles.push_back(atlas_coords)


static func get_sector(at: Vector2) -> Sector2D:
	var coord := sector_tile_map_layer.local_to_map(at)
	return sectors.get(coord)


static func get_sector_local_to_map(at: Vector2) -> Vector2i:
	var sector := get_sector(at)
	return INVALID_ATLAS_COORD if sector == null else sector.top_tile_map_layer.local_to_map(at)


static func get_sector_atlas_coords(at: Vector2) -> Vector2i:
	var sector := get_sector(at)
	at = sector.to_local(at)
	return INVALID_ATLAS_COORD if sector == null else sector.top_tile_map_layer.get_cell_atlas_coords(sector.top_tile_map_layer.local_to_map(at))


static func is_sector_obstacle(at: Vector2) -> bool:
	var coords := get_sector_atlas_coords(at)
	return coords in obstacles or at in enemies


static func is_valid(v: Variant) -> bool:
	return is_instance_valid(v) and not v.is_queued_for_deletion()
