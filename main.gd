extends Node

@export var start_seed := "world"
@export var blue_noise_tile_size := Vector2i(8, 7)

const TileMapLayerPackedScene := preload("res://tilemap/tile_map_layer.tscn")

const ENEMY_SPAN := Vector2i(3, 7)
const ENEMY_FILE_PATHS: Array[String] = [
	"res://entities/enemies/enemy_2d_a.tscn",
	"res://entities/enemies/enemy_2d_b.tscn",
]

var _sector_size: Vector2i = Vector2i.ZERO
var _obstacle_patterns: Array[TileMapPattern] = []

var _rng := RandomNumberGenerator.new()
var _sector_offset_span := range(-1, 2)

@onready var enemies: Node2D = %Enemies2D
@onready var player: Player2D = %Player2D

@onready var sector_tile_map_layer: TileMapLayer = %SectorTileMapLayer
@onready var tile_maps: Node2D = %TileMaps2D


func _ready() -> void:
	_sector_size = sector_tile_map_layer.tile_set.tile_size
	for index: int in range(Blackboard.TILE_SET.get_patterns_count()):
		_obstacle_patterns.push_back(Blackboard.TILE_SET.get_pattern(index))

	seed(hash(start_seed))
	player.move_area.connect("input_event", _on_player_move_area_input_event)

	Blackboard.sector_tile_map_layer = sector_tile_map_layer
	Blackboard.player = player

	for sector_x: int in _sector_offset_span:
		for sector_y: int in _sector_offset_span:
			var tile_map_layer := _generate_sector(Vector2i(sector_x, sector_y))
			_generate_enemies(tile_map_layer)
	_start_turn_based_loop()


func _on_player_move_area_input_event(
	_viewport: Node, event: InputEvent, _shape_index: int
) -> void:
	const DISTANCE_SQUARED_CHECK := 2
	if event.is_action_pressed("left_click"):
		var _sector_player_position := sector_tile_map_layer.local_to_map(player.position)
		for sector_offset: Vector2i in Blackboard.sectors:
			if _sector_player_position.distance_squared_to(sector_offset) > DISTANCE_SQUARED_CHECK:
				Blackboard.sectors[sector_offset].queue_free()
				Blackboard.sectors.erase(sector_offset)

		for sector_offset: Vector2i in _get_neighbor_sector_coords(_sector_player_position):
			var tile_map_layer := _generate_sector(sector_offset)
			_generate_enemies(tile_map_layer)


func _generate_sector(offset: Vector2i) -> TileMapLayer:
	if offset in Blackboard.sectors:
		return null

	_rng.seed = hash("%s_%d_%d" % [start_seed, offset.x, offset.y])
	var tile_map_layer: TileMapLayer = TileMapLayerPackedScene.instantiate()
	tile_maps.add_child(tile_map_layer)
	Blackboard.sectors[offset] = tile_map_layer

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
	return tile_map_layer


func _add_enemy(enemy_position: Vector2, file_path := "") -> void:
	if file_path.is_empty():
		file_path = ENEMY_FILE_PATHS.pick_random()
	var enemy: Enemy2D = load(file_path).instantiate()
	enemy.position = enemy_position
	enemies.add_child(enemy)
	Blackboard.enemies[enemy.position] = enemy


func _generate_enemies(tile_map_layer: TileMapLayer) -> void:
	if tile_map_layer == null:
		return

	var available_coords := tile_map_layer.get_used_cells()
	for index: int in range(Blackboard.TILE_SET.get_source_count()):
		var tile_map_source: TileSetAtlasSource = Blackboard.TILE_SET.get_source(index)
		var atlast_grid_size := tile_map_source.get_atlas_grid_size()
		for atlas_x: int in range(atlast_grid_size.x):
			for atlas_y: int in range(atlast_grid_size.y):
				var atlas_coords := Vector2i(atlas_x, atlas_y)
				if atlas_coords > Vector2i.ZERO:
					for coord: Vector2i in tile_map_layer.get_used_cells_by_id(index, atlas_coords):
						available_coords.erase(coord)

	for _i: int in range(randi_range(ENEMY_SPAN.x, ENEMY_SPAN.y)):
		var coord: Vector2i = available_coords.pick_random()
		var enemy_position := tile_map_layer.to_global(tile_map_layer.map_to_local(coord))
		_add_enemy(enemy_position)
		available_coords.erase(coord)


func _get_neighbor_sector_coords(relative_to := Vector2i.ZERO) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for x in _sector_offset_span:
		for y in _sector_offset_span:
			result.push_back(relative_to + Vector2i(x, y))
	return result


func _get_entities() -> Array[Entity2D]:
	const DISTANCE_SQUARED_CHECK := 200 ** 2
	var result: Array[Entity2D] = []
	if Blackboard.is_valid(player):
		result.push_back(player)
		result.append_array(enemies.get_children().filter(
			func(e: Enemy2D) -> bool:
				return e.position.distance_squared_to(player.position) < DISTANCE_SQUARED_CHECK
		))
	return result


func _start_turn_based_loop() -> void:
	while true:
		var entities := _get_entities()
		if entities.is_empty():
			break

		for entity: Entity2D in entities:
			if not Blackboard.is_valid(entity):
				continue

			entity.start_turn()
			await entity.turn_finished
			await entity.end_turn()
