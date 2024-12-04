extends Node

@export var start_seed := "world"
@export var blue_noise_tile_size := Vector2i(8, 7)

const Enemy2DPackedScene := preload("res://entities/enemy_2d.tscn")
const TileMapLayerPackedScene := preload("res://tilemap/tile_map_layer.tscn")

const TILE_SET := preload("res://tilemap/tile_set.tres")

var _sector_size: Vector2i = Vector2i.ZERO
var _obstacle_patterns: Array[TileMapPattern] = []

var _rng := RandomNumberGenerator.new()
var _sector_offset_span := range(-1, 2)
var _sectors := {}

@onready var enemies: Node2D = %Enemies2D
@onready var player: Player2D = %Player2D

@onready var sector_tile_map_layer: TileMapLayer = %SectorTileMapLayer
@onready var tile_maps: Node2D = %TileMaps2D


func _ready() -> void:
	_sector_size = sector_tile_map_layer.tile_set.tile_size
	for index: int in range(TILE_SET.get_patterns_count()):
		_obstacle_patterns.push_back(TILE_SET.get_pattern(index))

	seed(hash(start_seed))
	player.move_area.connect("input_event", _on_player_move_area_input_event)

	Blackboard.player = player

	for sector_x: int in _sector_offset_span:
		for sector_y: int in _sector_offset_span:
			_generate_sector(Vector2i(sector_x, sector_y))

	_generate_enemies(_sectors[Vector2i.ZERO])
	_start_turn_based_loop()


func _on_player_move_area_input_event(
	_viewport: Node, event: InputEvent, _shape_index: int
) -> void:
	const DISTANCE_SQUARED_CHECK := 2
	if event.is_action_pressed("left_click"):
		var _sector_player_position := sector_tile_map_layer.local_to_map(player.position)
		for sector_offset: Vector2i in _sectors:
			if _sector_player_position.distance_squared_to(sector_offset) > DISTANCE_SQUARED_CHECK:
				_sectors[sector_offset].queue_free()
				_sectors.erase(sector_offset)

		for sector_offset: Vector2i in _get_neighbor_sector_coords(_sector_player_position):
			_generate_sector(sector_offset)


func _generate_sector(offset: Vector2i) -> void:
	if offset in _sectors:
		return

	_rng.seed = hash("%s_%d_%d" % [start_seed, offset.x, offset.y])
	var tile_map_layer: TileMapLayer = TileMapLayerPackedScene.instantiate()
	tile_maps.add_child(tile_map_layer)
	_sectors[offset] = tile_map_layer

	tile_map_layer.position = _sector_size * offset
	var tile_map_size := tile_map_layer.get_used_rect().size

	for x: int in range(0, tile_map_size.x, blue_noise_tile_size.x):
		for y: int in range(0, tile_map_size.y, blue_noise_tile_size.y):
			var pattern: TileMapPattern = _obstacle_patterns.pick_random()
			var pattern_tile_size := pattern.get_size()
			var blue_noise_tile_position := Vector2i(
				x + _rng.randi_range(0, blue_noise_tile_size.x - pattern_tile_size.x - 1),
				y + _rng.randi_range(0, blue_noise_tile_size.y - pattern_tile_size.y - 1),
			)
			tile_map_layer.set_pattern(blue_noise_tile_position, pattern)


func _generate_enemies(tile_map_layer: TileMapLayer) -> void:
	var available_coords := tile_map_layer.get_used_cells()
	for index: int in range(TILE_SET.get_source_count()):
		var tile_map_source: TileSetAtlasSource = TILE_SET.get_source(index)
		var atlast_grid_size := tile_map_source.get_atlas_grid_size()
		for atlas_x: int in range(atlast_grid_size.x):
			for atlas_y: int in range(atlast_grid_size.y):
				var atlas_coords := Vector2i(atlas_x, atlas_y)
				if atlas_coords > Vector2i.ZERO:
					for coord: Vector2i in tile_map_layer.get_used_cells_by_id(index, atlas_coords):
						available_coords.erase(coord)

	for index: int in range(3):
		var coord: Vector2i = available_coords.pick_random()
		var enemy := Enemy2DPackedScene.instantiate()
		enemies.add_child(enemy)
		enemy.position = tile_map_layer.map_to_local(coord)
		available_coords.erase(coord)


func _get_neighbor_sector_coords(relative_to := Vector2i.ZERO) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for x in _sector_offset_span:
		for y in _sector_offset_span:
			result.push_back(relative_to + Vector2i(x, y))
	return result


func _get_entities() -> Array[Entity2D]:
	var result: Array[Entity2D] = []
	result.push_back(player)
	result.append_array(enemies.get_children())
	return result


func _start_turn_based_loop() -> void:
	while true:
		var entities := _get_entities()
		for entity: Entity2D in entities:
			if not is_instance_valid(entity) or entity.is_queued_for_deletion():
				continue

			entity.start_turn()
			await entity.turn_finished
			entity.end_turn()
