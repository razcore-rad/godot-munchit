extends Node

const MainBlobTextureRectPackedScene := preload("ui/main_blob_texture_rect.tscn")
const BlobTextureRectPackedScene := preload("ui/blob_texture_rect.tscn")

const DEFAULT_SEED_TEXT := "world"

var offscreen_position: Vector2 = Vector2.RIGHT * ProjectSettings.get_setting("display/window/size/viewport_width")
var is_back_pressed := false
var is_playing := false

@onready var enemies: Node2D = %Enemies2D
@onready var stinger_enemies: Node2D = %StingerEnemies2D
@onready var sector_tile_map_layer: TileMapLayer = %SectorTileMapLayer
@onready var sectors: Node2D = %Sectors2D
@onready var player: Player2D = %Player2D
@onready var base_point_light: PointLight2D = %BasePointLight2D

@onready var player_hud_control: Control = %PlayerHUDControl
@onready var blobs_h_box_container: HBoxContainer = %BlobsHBoxContainer
@onready var points_h_box_container: HBoxContainer = %PointsHBoxContainer
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var points_label: Label = %PointsLabel
@onready var menu_control: MenuControl = %MenuControl
@onready var back_texture_button: TextureButton = %BackTextureButton

@onready var player_start_position := player.position
@onready var base_point_light_start_enerty := base_point_light.energy
@onready var base_point_light_start_texture_scale := base_point_light.texture_scale
@onready var progress_bar_stylebox: StyleBoxFlat = progress_bar.get_theme_stylebox("fill")
@onready var progress_bar_stylebox_start_bg_color := progress_bar_stylebox.bg_color


func _ready() -> void:
	menu_control.start_button.pressed.connect(_on_menu_control_start_button_pressed)
	back_texture_button.pressed.connect(_on_back_texture_rect_pressed)
	player.turn_started.connect(_on_player_turn.bind(true))
	player.turn_finished.connect(_on_player_turn.bind(false))
	player.skin_sub_viewport.blob_added.connect(_on_player_skin_sub_viewport_blob.bind(true))
	player.skin_sub_viewport.blob_removed.connect(_on_player_skin_sub_viewport_blob.bind(false))

	menu_control.seed_text_edit.placeholder_text = DEFAULT_SEED_TEXT

	Blackboard.sector_tile_map_layer = sector_tile_map_layer
	Blackboard.sectors = sectors
	Blackboard.enemies = enemies
	Blackboard.stinger_enemies = stinger_enemies
	Blackboard.player = player
	Blackboard.points_label = points_label
	Blackboard.progress_bar = progress_bar
	Blackboard.seed_text = menu_control.seed_text_edit.get_seed_text()
	Blackboard.generate()


func _on_menu_control_start_button_pressed() -> void:
	Blackboard.generate(true)
	_start_turn_based_loop()

	var tween := create_tween().set_parallel()
	tween.tween_property(base_point_light, "energy", 1.0, 1.0)
	tween.tween_property(base_point_light, "texture_scale", 1.0, 1.0)

	menu_control.position = offscreen_position
	player_hud_control.visible = true


func _on_back_texture_rect_pressed() -> void:
	if not is_playing:
		return

	is_back_pressed = true
	for entity: Entity2D in Blackboard.get_entities():
		if Blackboard.is_valid(entity):
			entity.turn_finished.emit()


func _on_player_turn(has_started: bool) -> void:
	progress_bar.visible = has_started
	if has_started:
		var tween := create_tween()
		player.turn_finished.connect(tween.kill)
		tween.tween_property(progress_bar_stylebox, "bg_color", Palette.YELLOW, 4.0)
		tween.tween_property(progress_bar_stylebox, "bg_color", Palette.RED, 7.0)
		tween.parallel().tween_property(progress_bar, "value", 0.0, 7.0)
		await tween.finished
		player.turn_finished.emit()
	else:
		progress_bar.value = 100.0
		progress_bar_stylebox.bg_color = progress_bar_stylebox_start_bg_color


func _on_player_skin_sub_viewport_blob(blob_count: int, is_added: bool) -> void:
	if is_added:
		var TextureRectPackedScene := MainBlobTextureRectPackedScene if blob_count == 1 else BlobTextureRectPackedScene
		blobs_h_box_container.add_child(TextureRectPackedScene.instantiate())
	elif blob_count >= 0:
		blobs_h_box_container.get_children().back().queue_free()


func _start_turn_based_loop() -> void:
	is_playing = true

	Blackboard.turn_count = 0
	Blackboard.spawn_stinger_enemies()
	player.setup_move_area(menu_control.get_move_area(true))
	for _i in player.skin_sub_viewport.MAX_BLOBS:
		player.skin_sub_viewport.add_blob()

	while true:
		for entity: Entity2D in Blackboard.get_entities():
			if Blackboard.is_valid(entity):
				entity.start_turn()
				await entity.turn_finished

				@warning_ignore("redundant_await")
				await entity.end_turn()

			if is_back_pressed or player.is_dead():
				break

		if is_back_pressed or player.is_dead():
			break

		Blackboard.turn_count += 1
	_end()


func _end() -> void:
	is_playing = false

	if is_back_pressed:
		points_label.text = "0"

	for entity: Entity2D in Blackboard.get_entities():
		if entity != player and Blackboard.is_valid(entity):
			entity.queue_free()

	menu_control.start_button.disabled = true
	var point_count := points_label.text.to_int()
	var main_tween := create_tween().set_trans(Tween.TRANS_SINE)
	main_tween.tween_property(base_point_light, "energy", 0.0, 2.0)
	main_tween.parallel().tween_property(base_point_light, "texture_scale", base_point_light_start_texture_scale, 2.0)
	if point_count > 0:
		main_tween.tween_method(func(x: int) -> void: points_label.text = str(x), point_count, 0, 1.0)

	var points_label_modulate := points_label.modulate
	var blink_tween: Tween = null
	if point_count > 0:
		blink_tween = create_tween().set_loops()
		blink_tween.tween_property(points_label, "modulate", Palette.LIGHT_GREEN, 0.1)
		blink_tween.tween_property(points_label, "modulate", points_label_modulate, 0.05)

	await main_tween.finished
	if blink_tween != null and point_count > 0:
		blink_tween.kill()

	points_label.modulate = points_label_modulate
	player.position = player_start_position
	Blackboard.generate()

	menu_control.position = Vector2.ZERO
	player_hud_control.visible = false

	if point_count > 0:
		main_tween = menu_control.menu_points_label.create_tween().set_trans(Tween.TRANS_SINE)
		main_tween.tween_method(func(x: int) -> void: menu_control.menu_points_label.text = str(x), Blackboard.point_count, Blackboard.point_count + point_count, 1.0)
	Blackboard.point_count += point_count
	for _i in player.skin_sub_viewport.MAX_BLOBS:
		player.skin_sub_viewport.add_blob()

	if point_count > 0:
		blink_tween = create_tween().set_loops()
		var menu_control_points_label_modulate := menu_control.menu_points_label.modulate
		blink_tween.tween_property(menu_control.menu_points_label, "modulate", Palette.LIGHT_GREEN, 0.1)
		blink_tween.tween_property(menu_control.menu_points_label, "modulate", menu_control_points_label_modulate, 0.05)
		await main_tween.finished
		blink_tween.kill()
		menu_control.menu_points_label.modulate = menu_control_points_label_modulate

	player.skin_sub_viewport.add_blob()

	main_tween = create_tween().set_trans(Tween.TRANS_SINE)
	main_tween.tween_property(base_point_light, "energy", base_point_light_start_enerty, 2.0)
	main_tween.parallel().tween_property(base_point_light, "texture_scale", base_point_light_start_texture_scale, 2.0)
	await main_tween.finished
	menu_control.start_button.disabled = false

	is_back_pressed = false
