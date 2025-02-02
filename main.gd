extends Node

const MainBlobTextureRectPackedScene := preload("ui/main_blob_texture_rect.tscn")
const BlobTextureRectPackedScene := preload("ui/blob_texture_rect.tscn")
const PickControlPackedScene := preload("ui/pick_control.tscn")
const MainVBoxContainerPackedScene := preload("ui/main_v_box_container.tscn")

const DEFAULT_SEED_TEXT := "world"

@onready var enemies: Node2D = %Enemies2D
@onready var stinger_enemies: Node2D = %StingerEnemies2D
@onready var sector_tile_map_layer: TileMapLayer = %SectorTileMapLayer
@onready var sectors: Node2D = %Sectors2D
@onready var player: Player2D = %Player2D
@onready var base_point_light: PointLight2D = %BasePointLight2D

@onready var ui_control: Control = %UIControl
@onready var blobs_h_box_container: HBoxContainer = %BlobsHBoxContainer
@onready var turn_label: Label = %TurnLabel
@onready var pick_control: PickControl = %PickControl
@onready var main_v_box_container: MainVBoxContainer = %MainVBoxContainer

@onready var player_start_position := player.position


func _ready() -> void:
	main_v_box_container.start_button.pressed.connect(_on_main_v_box_container_start_button_pressed)
	pick_control.buy_button.pressed.connect(_on_pick_control_buy_button_pressed)
	player.skin_sub_viewport.blob_added.connect(_on_player_skin_sub_viewport_blob.bind(true))
	player.skin_sub_viewport.blob_removed.connect(_on_player_skin_sub_viewport_blob.bind(false))

	main_v_box_container.seed_text_edit.placeholder_text = DEFAULT_SEED_TEXT

	Blackboard.sector_tile_map_layer = sector_tile_map_layer
	Blackboard.sectors = sectors
	Blackboard.enemies = enemies
	Blackboard.stinger_enemies = stinger_enemies
	Blackboard.player = player
	Blackboard.turn_label = turn_label
	Blackboard.seed_text = main_v_box_container.seed_text_edit.get_seed_text()
	Blackboard.generate()


func _on_pick_control_buy_button_pressed() -> void:
	var move_area := pick_control.get_move_area()
	print(move_area.cost)


func _on_main_v_box_container_start_button_pressed() -> void:
	Blackboard.generate(true)
	_start_turn_based_loop()

	var tween := create_tween().set_parallel()
	tween.tween_property(base_point_light, "energy", 1.0, 1.0)
	tween.tween_property(base_point_light, "texture_scale", 1.0, 1.0)

	turn_label.visible = true
	blobs_h_box_container.visible = true

	main_v_box_container.queue_free()
	pick_control.queue_free()


func _on_player_skin_sub_viewport_blob(blob_count: int, is_added: bool) -> void:
	if is_added:
		var TextureRectPackedScene := MainBlobTextureRectPackedScene if blob_count == 1 else BlobTextureRectPackedScene
		blobs_h_box_container.add_child(TextureRectPackedScene.instantiate())
	elif blob_count >= 0:
		blobs_h_box_container.get_children().back().queue_free()


func _start_turn_based_loop() -> void:
	player.setup_move_area(pick_control.get_move_area())
	for _i in player.skin_sub_viewport.MAX_BLOBS:
		player.skin_sub_viewport.add_blob()

	while true:
		Blackboard.increment_turn()
		for entity: Entity2D in Blackboard.get_entities():
			if Blackboard.is_valid(entity):
				entity.start_turn()
				await entity.turn_finished

				@warning_ignore("redundant_await")
				await entity.end_turn()

			if entity == player and player.is_dead():
				break

		if player.is_dead():
			break

	for entity: Entity2D in Blackboard.get_entities().slice(1):
		if Blackboard.is_valid(entity):
			entity.queue_free()
	_end()


func _end() -> void:
	var turn_count := turn_label.text.to_int()

	player.visible = false
	var main_tween := create_tween().set_trans(Tween.TRANS_SINE)
	main_tween.tween_property(base_point_light, "energy", 0.0, 2.0)
	main_tween.tween_method(func(x: int) -> void: turn_label.text = str(x), turn_count, 0, 1.0)

	var blink_tween := create_tween().set_loops()
	blink_tween.tween_property(turn_label, "modulate", Palette.LIGHT_GREEN, 0.1)
	blink_tween.tween_property(turn_label, "modulate", turn_label.modulate, 0.05)
	await main_tween.finished

	player.position = player_start_position
	Blackboard.generate()

	pick_control = PickControlPackedScene.instantiate()
	ui_control.add_child(pick_control)
	pick_control.buy_button.pressed.connect(_on_pick_control_buy_button_pressed)

	main_v_box_container = MainVBoxContainerPackedScene.instantiate()
	ui_control.add_child(main_v_box_container)
	main_v_box_container.start_button.pressed.connect(_on_main_v_box_container_start_button_pressed)

	blink_tween.kill()
	player.skin_sub_viewport.add_blob()
	player.visible = true
	turn_label.visible = false
	blobs_h_box_container.visible = false

	for _i in player.skin_sub_viewport.MAX_BLOBS:
		player.skin_sub_viewport.add_blob()

	main_tween = create_tween().set_trans(Tween.TRANS_SINE)
	main_tween.tween_method(func(x: int) -> void: main_v_box_container.points_label.text = str(x), Blackboard.point_count, Blackboard.point_count + turn_count, 1.0)
	Blackboard.point_count += turn_count

	blink_tween = create_tween().set_loops()
	blink_tween.tween_property(main_v_box_container.points_label, "modulate", Palette.LIGHT_GREEN, 0.1)
	blink_tween.tween_property(main_v_box_container.points_label, "modulate", main_v_box_container.points_label.modulate, 0.05)
	await main_tween.finished
	blink_tween.kill()

	main_tween = create_tween().set_trans(Tween.TRANS_SINE)
	main_tween.tween_property(base_point_light, "energy", 0.6, 2.0)
