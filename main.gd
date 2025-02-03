extends Node

const MainBlobTextureRectPackedScene := preload("ui/main_blob_texture_rect.tscn")
const BlobTextureRectPackedScene := preload("ui/blob_texture_rect.tscn")

const DEFAULT_SEED_TEXT := "world"

var offscreen_position: Vector2 = Vector2.RIGHT * ProjectSettings.get_setting("display/window/size/viewport_width")

@onready var enemies: Node2D = %Enemies2D
@onready var stinger_enemies: Node2D = %StingerEnemies2D
@onready var sector_tile_map_layer: TileMapLayer = %SectorTileMapLayer
@onready var sectors: Node2D = %Sectors2D
@onready var player: Player2D = %Player2D
@onready var base_point_light: PointLight2D = %BasePointLight2D

@onready var menu_control: MenuControl = %MenuControl
@onready var blobs_h_box_container: HBoxContainer = %BlobsHBoxContainer
@onready var turn_label: Label = %TurnLabel

@onready var player_start_position := player.position


func _ready() -> void:
	menu_control.start_button.pressed.connect(_on_menu_control_start_button_pressed)
	player.skin_sub_viewport.blob_added.connect(_on_player_skin_sub_viewport_blob.bind(true))
	player.skin_sub_viewport.blob_removed.connect(_on_player_skin_sub_viewport_blob.bind(false))

	menu_control.seed_text_edit.placeholder_text = DEFAULT_SEED_TEXT

	Blackboard.sector_tile_map_layer = sector_tile_map_layer
	Blackboard.sectors = sectors
	Blackboard.enemies = enemies
	Blackboard.stinger_enemies = stinger_enemies
	Blackboard.player = player
	Blackboard.turn_label = turn_label
	Blackboard.seed_text = menu_control.seed_text_edit.get_seed_text()
	Blackboard.generate()


func _on_menu_control_start_button_pressed() -> void:
	Blackboard.generate(true)
	_start_turn_based_loop()

	var tween := create_tween().set_parallel()
	tween.tween_property(base_point_light, "energy", 1.0, 1.0)
	tween.tween_property(base_point_light, "texture_scale", 1.0, 1.0)

	turn_label.visible = true
	blobs_h_box_container.visible = true
	menu_control.position = offscreen_position


func _on_player_skin_sub_viewport_blob(blob_count: int, is_added: bool) -> void:
	if is_added:
		var TextureRectPackedScene := MainBlobTextureRectPackedScene if blob_count == 1 else BlobTextureRectPackedScene
		blobs_h_box_container.add_child(TextureRectPackedScene.instantiate())
	elif blob_count >= 0:
		blobs_h_box_container.get_children().back().queue_free()


func _start_turn_based_loop() -> void:
	player.setup_move_area(menu_control.get_move_area(true))
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

			if player.is_dead():
				break

		if player.is_dead():
			break
	_end()


func _end() -> void:
	player.visible = false
	for entity: Entity2D in Blackboard.get_entities().slice(1):
		if Blackboard.is_valid(entity):
			entity.queue_free()

	var turn_count := turn_label.text.to_int()
	var main_tween := create_tween().set_trans(Tween.TRANS_SINE)
	main_tween.tween_property(base_point_light, "energy", 0.0, 2.0)
	main_tween.tween_method(func(x: int) -> void: turn_label.text = str(x), turn_count, 0, 1.0)

	var turn_label_modulate := turn_label.modulate
	var blink_tween := create_tween().set_loops()
	blink_tween.tween_property(turn_label, "modulate", Palette.LIGHT_GREEN, 0.1)
	blink_tween.tween_property(turn_label, "modulate", turn_label_modulate, 0.05)
	await main_tween.finished
	blink_tween.kill()

	turn_label.modulate = turn_label_modulate
	player.position = player_start_position
	Blackboard.generate()

	menu_control.position = Vector2.ZERO
	turn_label.visible = false
	blobs_h_box_container.visible = false

	main_tween = menu_control.points_label.create_tween().set_trans(Tween.TRANS_SINE)
	main_tween.tween_method(func(x: int) -> void: menu_control.points_label.text = str(x), Blackboard.point_count, Blackboard.point_count + turn_count, 1.0)
	Blackboard.point_count += turn_count
	for _i in player.skin_sub_viewport.MAX_BLOBS:
		player.skin_sub_viewport.add_blob()

	var menu_control_points_label_modulate := menu_control.points_label.modulate
	blink_tween = create_tween().set_loops()
	blink_tween.tween_property(menu_control.points_label, "modulate", Palette.LIGHT_GREEN, 0.1)
	blink_tween.tween_property(menu_control.points_label, "modulate", menu_control_points_label_modulate, 0.05)
	await main_tween.finished
	blink_tween.kill()

	menu_control.points_label.modulate = menu_control_points_label_modulate
	player.skin_sub_viewport.add_blob()
	player.visible = true

	main_tween = create_tween().set_trans(Tween.TRANS_SINE)
	main_tween.tween_property(base_point_light, "energy", 0.6, 2.0)
