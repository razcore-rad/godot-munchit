class_name Blackboard

const Sector2DPackedScene := preload("sectors/sector_2d.tscn")
const StingerEnemy2DPackedScene := preload("entities/enemies/stinger_enemy_2d.tscn")

const TILE_SET := preload("sectors/tile_set.tres")
const ENEMY_FILE_PATHS: Array[String] = [
	"entities/enemies/enemy_2d_a.tscn",
	"entities/enemies/enemy_2d_b.tscn",
]

const MAX_ENEMIES := 300
const MAX_STINGER_ENEMIES := 4
const STINGER_ENEMIES_DIV := 12
const ENEMY_SPAN := Vector2i(MAX_ENEMIES - 20, MAX_ENEMIES)

static var _blue_noise_tile_size := Vector2i(8, 7)
static var _sector_offset_span := range(-1, 2)
static var _obstacle_patterns: Array[TileMapPattern] = []

static var rng := RandomNumberGenerator.new()

static var obstacles: Array[Vector2i] = []
static var sectors_map: Dictionary[Vector2i, Sector2D] = {}
static var enemies_map: Dictionary[Vector2, Enemy2D] = {}
static var half_tile_size := TILE_SET.tile_size / 2
static var seed_text: String = ""
static var point_count := 0

static var sector_tile_map_layer: TileMapLayer = null
static var sectors: Node2D = null
static var enemies: Node2D = null
static var stinger_enemies: Node2D = null
static var player: Player2D = null
static var turn_label: Label = null


static func _static_init() -> void:
	for index: int in range(TILE_SET.get_source_count()):
		var source: TileSetAtlasSource = TILE_SET.get_source(index)
		for i in source.get_tiles_count():
			var atlas_coords := source.get_tile_id(i)
			var tile_data := source.get_tile_data(atlas_coords, 0)
			if tile_data.get_occluder(0) != null:
				obstacles.push_back(atlas_coords)

	for index: int in range(TILE_SET.get_patterns_count()):
		_obstacle_patterns.push_back(TILE_SET.get_pattern(index))


static func _add_enemy(enemy_position: Vector2, file_path := "") -> void:
	if file_path.is_empty():
		file_path = ENEMY_FILE_PATHS.pick_random()
	var enemy: Enemy2D = load(file_path).instantiate()
	enemy.position = enemy_position
	enemies.add_child(enemy)
	enemies_map[enemy.position] = enemy


static func _add_stinger_enemey(position: Vector2) -> void:
	var stinger: StingerEnemy2D = StingerEnemy2DPackedScene.instantiate()
	stinger.position = position
	stinger_enemies.add_child(stinger)


static func get_sector(at: Vector2) -> Sector2D:
	var coord := sector_tile_map_layer.local_to_map(at)
	return sectors_map.get(coord)


static func is_obstacle(at: Vector2) -> bool:
	var sector := get_sector(at)
	return sector == null or sector.top_tile_map_layer.local_to_map(sector.to_local(at)) in sector.top_tile_map_layer.get_used_cells() or at in enemies_map


static func is_valid(v: Variant) -> bool:
	return is_instance_valid(v) and not v.is_queued_for_deletion()


static func generate(do_generate_enemies := false) -> void:
	seed(hash(Blackboard.seed_text))
	var relative_to: Vector2i = sector_tile_map_layer.local_to_map(player.position)
	for sector_x: int in _sector_offset_span:
		for sector_y: int in _sector_offset_span:
			var tile_map_layer := generate_sector(relative_to + Vector2i(sector_x, sector_y))
			if do_generate_enemies:
				generate_enemies(tile_map_layer)
	if do_generate_enemies:
		spawn_stinger_enemies()



static func generate_sector(offset: Vector2i) -> Sector2D:
	if offset in sectors_map:
		return sectors_map[offset]

	var sector: Sector2D = Sector2DPackedScene.instantiate()
	sectors.add_child(sector)
	sectors_map[offset] = sector

	sector.position = sector_tile_map_layer.tile_set.tile_size * offset
	var tile_map_size := sector.base_tile_map_layer.get_used_rect().size

	rng.seed = hash("%s_%d_%d" % [seed_text, offset.x, offset.y])
	for x: int in range(0, tile_map_size.x, _blue_noise_tile_size.x):
		for y: int in range(0, tile_map_size.y, _blue_noise_tile_size.y):
			var pattern: TileMapPattern = _obstacle_patterns.pick_random()
			var pattern_tile_size := pattern.get_size()
			var blue_noise_tile_position := Vector2i(
				x + rng.randi_range(0, _blue_noise_tile_size.x - pattern_tile_size.x - 1),
				y + rng.randi_range(0, _blue_noise_tile_size.y - pattern_tile_size.y - 1),
			)
			sector.top_tile_map_layer.set_pattern(blue_noise_tile_position, pattern)
	return sector


static func generate_enemies(sector: Sector2D) -> void:
	if sector == null:
		return

	var available_coords := sector.base_tile_map_layer.get_used_cells()
	for obstacle_coord: Vector2i in sector.top_tile_map_layer.get_used_cells():
		available_coords.erase(obstacle_coord)

	@warning_ignore("integer_division")
	for _i: int in range(randi_range(ENEMY_SPAN.x, ENEMY_SPAN.y) / sectors_map.size()):
		var coord: Vector2i = available_coords.pick_random()
		var enemy_position := sector.top_tile_map_layer.to_global(sector.top_tile_map_layer.map_to_local(coord))
		_add_enemy(enemy_position)
		available_coords.erase(coord)


static func spawn_enemies(spawn_tile_map_layer: TileMapLayer) -> void:
	var available_positions: Array[Vector2i] = spawn_tile_map_layer.get_used_cells().reduce(func(acc: Dictionary[Vector2i, Variant], v: Vector2i) -> Dictionary[Vector2i, Variant]:
		v = spawn_tile_map_layer.to_global(spawn_tile_map_layer.map_to_local(v))
		return acc.merged({v: null}) if not Blackboard.is_obstacle(v) else acc , {} as Dictionary[Vector2i, Variant]).keys()

	for _i: int in range(enemies_map.size(), MAX_ENEMIES):
		var enemy_position: Vector2i = available_positions.pick_random()
		_add_enemy(enemy_position)
		available_positions.erase(enemy_position)


static func spawn_stinger_enemies() -> void:
	@warning_ignore("integer_division")
	var max_stinger_enemies := mini(get_turn() / STINGER_ENEMIES_DIV, MAX_STINGER_ENEMIES)
	var stinger_enemy_count := stinger_enemies.get_children().filter(func(s: StingerEnemy2D) -> void: return is_valid(s)).size()

	for _i: int in range(stinger_enemy_count, max_stinger_enemies):
		var r := 100.0 * (1 + sqrt(rng.randf()))
		var theta := rng.randf_range(0.0, TAU)
		player.ray_cast.target_position = r * Vector2(cos(theta), sin(theta))
		player.ray_cast.force_raycast_update()
		var stinger_enemey_position := player.to_global(player.ray_cast.target_position)
		if player.ray_cast.is_colliding() and not is_obstacle(stinger_enemey_position):
			_add_stinger_enemey(stinger_enemey_position)


static func increment_turn() -> void:
	turn_label.text = str(turn_label.text.to_int() + 1)


static func get_turn() -> int:
	return turn_label.text.to_int()


static func get_neighbor_sector_coords(relative_to := Vector2i.ZERO) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for x in _sector_offset_span:
		for y in _sector_offset_span:
			var xy := Vector2i(x, y)
			if xy == Vector2i.ZERO:
				continue
			result.push_back(relative_to + xy)
	return result


static func get_entities() -> Array[Entity2D]:
	const DISTANCE_SQUARED_CHECK := 400 ** 2
	var result: Array[Entity2D] = []
	if is_valid(player):
		result.push_back(player)
		result.append_array(stinger_enemies.get_children())
		result.append_array(enemies.get_children().filter(func(e: Enemy2D) -> bool:
			return e.position.distance_squared_to(player.position) < DISTANCE_SQUARED_CHECK
		))
	return result
