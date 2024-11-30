extends Node

@export var start_seed := "world"
@export var obstacle_packed_scenes: Array[PackedScene] = []

var _rng := RandomNumberGenerator.new()
var _sector_offset_span := range(-1, 2)
var _occupied_sectors := {}

@onready var obstacles: Node2D = %Obstacles2D
@onready var enemies: Node2D = %Enemies2D
@onready var player_entity: PlayerEntity2D = %PlayerEntity2D

@onready var sector_tile_map_layer: TileMapLayer = %SectorTileMapLayer
@onready var tile_map_layer: TileMapLayer = %TileMapLayer
@onready var _tile_map_used_size := tile_map_layer.get_used_rect().size
@onready var _half_tile_size := tile_map_layer.tile_set.tile_size / 2.0


func _ready() -> void:
	seed(hash(start_seed))
	player_entity.move_area.connect("input_event", _on_player_entity_move_area_input_event)
	for sector_offset_x in _sector_offset_span:
		for sector_offset_y in _sector_offset_span:
			_generate_obstacles(Vector2i(sector_offset_x, sector_offset_y))


func _generate_obstacles(sector_offset := Vector2i.ZERO) -> void:
	var sector_position := tile_map_layer.map_to_local(_tile_map_used_size * sector_offset) - _half_tile_size
	if sector_position in _occupied_sectors:
		return

	var blue_noise_rect := Rect2i(Vector2i.ZERO, Vector2i(8, 7))
	var sector := Node2D.new()
	obstacles.add_child(sector)
	sector.name = "Sector"
	sector.position = sector_position
	_occupied_sectors[sector.position] = null

	_rng.seed = hash("%s_%d_%d" % [start_seed, sector_offset.x, sector_offset.y])
	for cell_x: int in range(0, _tile_map_used_size.x, blue_noise_rect.size.x):
		for cell_y: int in range(0, _tile_map_used_size.y, blue_noise_rect.size.y):
			blue_noise_rect.position = Vector2i(cell_x, cell_y)

			var obstacle: Obstacle2D = obstacle_packed_scenes.pick_random().instantiate()
			sector.add_child(obstacle)
			var obstacle_size = obstacle.get_size()
			var map_obstacle_size := tile_map_layer.local_to_map(obstacle_size)

			var adjusted_blue_noise_rect := blue_noise_rect.grow_side(SIDE_LEFT, -1)
			adjusted_blue_noise_rect = adjusted_blue_noise_rect.grow_side(SIDE_RIGHT, -(map_obstacle_size.x + 1))
			adjusted_blue_noise_rect = adjusted_blue_noise_rect.grow_side(SIDE_TOP, -1)
			adjusted_blue_noise_rect = adjusted_blue_noise_rect.grow_side(SIDE_BOTTOM, -(map_obstacle_size.y + 1))

			var blue_noise_position := Vector2i(
				_rng.randi_range(adjusted_blue_noise_rect.position.x, adjusted_blue_noise_rect.end.x - 1),
				_rng.randi_range(adjusted_blue_noise_rect.position.y, adjusted_blue_noise_rect.end.y - 1),
			)
			obstacle.position = tile_map_layer.map_to_local(blue_noise_position) + _half_tile_size


func _on_player_entity_move_area_input_event(_viewport: Node, event: InputEvent, _shape_index: int) -> void:
	const DISTANCE_SQUARED_CHECK := 2
	if event.is_action_pressed("left_click"):
		var _sector_player_position := sector_tile_map_layer.local_to_map(player_entity.position)
		for sector: Node2D in obstacles.get_children():
			var distance_squared := sector_tile_map_layer.local_to_map(sector.position).distance_squared_to(_sector_player_position)
			if distance_squared > DISTANCE_SQUARED_CHECK:
				_occupied_sectors.erase(sector.position)
				sector.queue_free()

		for sector_coord: Vector2i in _get_neighbor_sector_coords(_sector_player_position):
			_generate_obstacles(sector_coord)


func _get_neighbor_sector_coords(relative_to := Vector2i.ZERO) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for x in _sector_offset_span:
		for y in _sector_offset_span:
			result.push_back(relative_to + Vector2i(x, y))
	return result
