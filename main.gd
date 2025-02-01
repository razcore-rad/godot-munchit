extends Node

const BlobTextureRectPackedScene := preload("ui/blob_texture_rect.tscn")

const DEFAULT_SEED_TEXT := "world"

@onready var enemies: Node2D = %Enemies2D
@onready var stinger_enemies: Node2D = %StingerEnemies2D
@onready var sector_tile_map_layer: TileMapLayer = %SectorTileMapLayer
@onready var sectors: Node2D = %Sectors2D
@onready var player: Player2D = %Player2D
@onready var base_point_light: PointLight2D = %BasePointLight2D

@onready var blobs_h_box_container: HBoxContainer = %BlobsHBoxContainer
@onready var turn_label: Label = %TurnLabel
@onready var pick_control: Control = %PickControl
@onready var v_box_container: VBoxContainer = %VBoxContainer
@onready var start_button: Button = %StartButton
@onready var seed_text_edit: SeedTextEdit = %SeedTextEdit


func _ready() -> void:
	start_button.pressed.connect(_on_start_button_pressed)
	player.skin_sub_viewport.blob_added.connect(_on_player_skin_sub_viewport_blob.bind(true))
	player.skin_sub_viewport.blob_removed.connect(_on_player_skin_sub_viewport_blob.bind(false))
	for _i in player.skin_sub_viewport.MAX_BLOBS:
		player.skin_sub_viewport.add_blob()

	seed_text_edit.placeholder_text = DEFAULT_SEED_TEXT

	Blackboard.sector_tile_map_layer = sector_tile_map_layer
	Blackboard.sectors = sectors
	Blackboard.enemies = enemies
	Blackboard.stinger_enemies = stinger_enemies
	Blackboard.player = player
	Blackboard.turn_label = turn_label

	Blackboard.seed_text = seed_text_edit.get_seed_text()
	seed(hash(Blackboard.seed_text))

	Blackboard.generate()


func _on_start_button_pressed() -> void:
	Blackboard.generate(true)
	_start_turn_based_loop()

	var tween := create_tween().set_parallel()
	tween.tween_property(base_point_light, "energy", 1.0, 1.0)
	tween.tween_property(base_point_light, "texture_scale", 1.0, 1.0)

	blobs_h_box_container.visible = true
	turn_label.visible = true

	v_box_container.queue_free()
	pick_control.queue_free()


func _on_player_skin_sub_viewport_blob(_blob_count: int, is_added: bool) -> void:
	if is_added:
		blobs_h_box_container.add_child(BlobTextureRectPackedScene.instantiate())
	else:
		blobs_h_box_container.get_children().back().queue_free()


func _start_turn_based_loop() -> void:
	player.setup_move_area(pick_control.get_move_area())
	while true:
		Blackboard.increment_turn()
		var entities := Blackboard.get_entities()
		if entities.is_empty():
			break

		for entity: Entity2D in entities:
			if not Blackboard.is_valid(entity):
				continue

			entity.start_turn()
			await entity.turn_finished
			await entity.end_turn()
