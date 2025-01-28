extends Node

const BlobTextureRectPackedScene := preload("ui/blob_texture_rect.tscn")

const DEFAULT_SEED_TEXT := "world"

@onready var enemies: Node2D = %Enemies2D
@onready var sector_tile_map_layer: TileMapLayer = %SectorTileMapLayer
@onready var sectors: Node2D = %Sectors2D
@onready var player: Player2D = %Player2D

@onready var blobs_h_box_container: HBoxContainer = %BlobsHBoxContainer
@onready var turn_label: Label = %TurnLabel
@onready var pick_control: Control = %PickControl
@onready var v_box_container: VBoxContainer = %VBoxContainer
@onready var start_button: Button = %StartButton
@onready var seed_text_edit: SeedTextEdit = %SeedTextEdit


func _ready() -> void:
	start_button.pressed.connect(_on_start_button_pressed)
	# player.move_area.input_event.connect(_on_player_move_area_input_event)
	player.skin_sub_viewport.blob_added.connect(_on_player_skin_sub_viewport_blob.bind(true))
	player.skin_sub_viewport.blob_removed.connect(_on_player_skin_sub_viewport_blob.bind(false))
	for _i in range(10):
		player.skin_sub_viewport.add_blob()

	seed_text_edit.placeholder_text = DEFAULT_SEED_TEXT

	Blackboard.sector_tile_map_layer = sector_tile_map_layer
	Blackboard.sectors = sectors
	Blackboard.enemies = enemies
	Blackboard.player = player
	Blackboard.seed_text_edit = seed_text_edit
	Blackboard.generate()


func _on_start_button_pressed() -> void:
	if seed_text_edit.get_seed_text() != DEFAULT_SEED_TEXT:
		Blackboard.generate()
	_start_turn_based_loop()

	blobs_h_box_container.visible = true
	turn_label.visible = true

	v_box_container.queue_free()
	pick_control.queue_free()


func _on_player_move_area_input_event(
	_viewport: Node, event: InputEvent, _shape_index: int
) -> void:
	const DISTANCE_SQUARED_CHECK := 2
	if event.is_action_pressed("left_click"):
		var _sector_player_position := sector_tile_map_layer.local_to_map(player.position)
		for sector_offset: Vector2i in Blackboard.sectors_map:
			if _sector_player_position.distance_squared_to(sector_offset) > DISTANCE_SQUARED_CHECK:
				Blackboard.sectors_map[sector_offset].queue_free()
				Blackboard.sectors_map.erase(sector_offset)

		for sector_offset: Vector2i in Blackboard.get_neighbor_sector_coords(_sector_player_position):
			var sector := Blackboard.generate_sector(sector_offset)
			Blackboard.generate_enemies(sector)


func _on_player_skin_sub_viewport_blob(_blob_count: int, is_added: bool) -> void:
	if is_added:
		blobs_h_box_container.add_child(BlobTextureRectPackedScene.instantiate())
	else:
		blobs_h_box_container.get_children().back().queue_free()


func _start_turn_based_loop() -> void:
	player.setup_move_area(pick_control.get_move_area())
	while true:
		turn_label.text = str(turn_label.text.to_int() + 1)
		var entities := Blackboard.get_entities()
		if entities.is_empty():
			break

		for entity: Entity2D in entities:
			if not Blackboard.is_valid(entity):
				continue

			entity.start_turn()
			await entity.turn_finished
			await entity.end_turn()
