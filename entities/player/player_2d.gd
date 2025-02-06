class_name Player2D extends Entity2D

signal turn_started

const SkinSubViewportPackedScene: PackedScene = preload("skin_sub_viewport.tscn")

const MOVE_AREAS_FOLDER := "move_areas"
const JUMP_HEIGHT := 15
const DURATION := 0.3
const MOVE_AREA_TEXTURE_RECT := Rect2(0.0, 40.0, 30.0, 20.0)
const MOVE_AREA_COLORS: Dictionary[String, Color] = {
	default = Palette.GREEN,
	hover = Palette.LIGHT_GREEN,
}

var _move_tween: Tween = create_tween()

var move_area: MoveArea2D = null

@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var eyes_animation_player: AnimationPlayer = %EyesAnimationPlayer
@onready var skin_sub_viewport: SkinSubViewport = %SkinSubViewport
@onready var extra: Node2D = %Extra2D
@onready var mouth_animated_sprite: AnimatedSprite2D = %MouthAnimatedSprite2D
@onready var inner_eyes: Array[ColorRect] = [%LeftInnerColorRect, %RightInnerColorRect]
@onready var ray_cast: RayCast2D = %RayCast2D
@onready var spawn_tile_map_layer: TileMapLayer = %SpawnTileMapLayer
@onready var points_label: Label = %PointsLabel
@onready var gpu_particles: GPUParticles2D = %GPUParticles2D
@onready var shadow_sprite: Sprite2D = %ShadowSprite2D


func _ready() -> void:
	super()
	_move_tween.stop()
	detect_area.input_event.connect(_on_detect_area_input_event)
	skin_sub_viewport.blob_added.connect(_on_skin_sub_viewport_blob.bind(true))
	skin_sub_viewport.blob_removed.connect(_on_skin_sub_viewport_blob.bind(false))

	await owner.ready
	skin_sub_viewport.world_2d = World2D.new()
	skin_sub_viewport.add_blob()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var mouse_global_position := get_global_mouse_position()
		for inner_eye: ColorRect in inner_eyes:
			inner_eye.rotation = inner_eye.global_position.angle_to_point(mouse_global_position)


func _on_skin_sub_viewport_blob(blob_count: int, is_added: bool) -> void:
	visible = blob_count > 0
	if not is_added:
		eyes_animation_player.play("attacked")


func _on_detect_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event.is_action_pressed("left_click"):
		turn_finished.emit()


func _on_move_area_body_shape_entered(
	_body_rid: RID, _body: Node2D, _body_shape_index: int, local_shape_index: int
) -> void:
	var collision_shape: CollisionShape2D = move_area.get_child(local_shape_index)
	collision_shape.set_deferred("disabled", true)


func _on_move_area_input_event(_viewport: Node, event: InputEvent, shape_index: int) -> void:
	var collision_shape: MoveAreaCollisionShape2D = move_area.get_child(shape_index)
	if event is InputEventMouse:
		collision_shape.modulate = MOVE_AREA_COLORS.hover

	if not _move_tween.is_running() and event.is_action_pressed("left_click"):
		var tween := create_tween().set_trans(Tween.TRANS_QUAD)
		tween.tween_property(shadow_sprite, "scale", 0.3 * Vector2.ONE, DURATION)
		tween.tween_property(shadow_sprite, "scale", Vector2.ONE, DURATION)
		for node: Node2D in [skin_sub_viewport.get_child(0), extra]:
			tween = create_tween().set_trans(Tween.TRANS_QUAD)
			tween.tween_property(node, "position:y", -JUMP_HEIGHT, DURATION).as_relative()
			tween.tween_property(node, "position:y", JUMP_HEIGHT, DURATION).as_relative()

		var target_position := collision_shape.global_position
		_move_tween = create_tween()
		_move_tween.tween_property(self, "position", target_position, 2.0 * DURATION)
		await _move_tween.finished
		_detect_enemy(target_position)
		turn_finished.emit()


func _on_move_area_mouse_exited() -> void:
	for collision_shape: MoveAreaCollisionShape2D in move_area.get_children():
		collision_shape.modulate = MOVE_AREA_COLORS.default


func _connect_move_area() -> void:
	move_area.body_shape_entered.connect(_on_move_area_body_shape_entered)
	move_area.input_event.connect(_on_move_area_input_event)
	move_area.mouse_exited.connect(_on_move_area_mouse_exited)


func _detect_enemy(target_position: Vector2) -> void:
	if target_position in Blackboard.enemies_map:
		var enemy := Blackboard.enemies_map[target_position]
		Blackboard.enemies_map.erase(target_position)
		if Blackboard.is_valid(enemy):
			_eat_enemy(enemy.move_area, enemy.points)
			enemy.queue_free()
	else:
		Blackboard.set_point_count(Blackboard.get_point_count() - 1)
		skin_sub_viewport.remove_blob()


func _eat_enemy(enemy_move_area: Area2D, enemy_points: int) -> void:
	Blackboard.set_point_count(Blackboard.get_point_count() + enemy_points)
	skin_sub_viewport.add_blob()
	var move_area_collision_shape_positions := move_area.get_children().map(func(cs: MoveAreaCollisionShape2D) -> Vector2: return cs.position)
	for collision_shape: MoveAreaCollisionShape2D in enemy_move_area.get_children():
		if collision_shape.position not in move_area_collision_shape_positions:
			var new_move_area_collision_shape := MoveAreaCollisionShape2DPackedScene.instantiate()
			move_area.add_child(new_move_area_collision_shape)
			new_move_area_collision_shape.position = collision_shape.position
			new_move_area_collision_shape.modulate = MOVE_AREA_COLORS.default
			new_move_area_collision_shape.sprite.region_rect = MOVE_AREA_TEXTURE_RECT

	move_area.visible = true
	_toggle_area_shapes(move_area, {is_disabled = false})

	mouth_animated_sprite.play()
	animation_player.play("eat")
	await animation_player.animation_finished
	gpu_particles.emitting = false


func setup_move_area(new_move_area: MoveArea2D) -> void:
	if Blackboard.is_valid(move_area):
		move_area.queue_free()

	move_area = new_move_area
	areas.add_child(move_area)
	move_area.position = Vector2.ZERO
	for collision_shape:MoveAreaCollisionShape2D in move_area.get_children():
		collision_shape.modulate = MOVE_AREA_COLORS.default
	_connect_move_area()


func is_dead() -> bool:
	return skin_sub_viewport.blob_count < 1


func start_turn() -> void:
	areas.visible = true
	turn_started.emit()
	_toggle_area_shapes(move_area, {is_disabled = false})


func end_turn() -> void:
	areas.visible = false
	_toggle_area_shapes(move_area, {is_disabled = true})
	const DISTANCE_SQUARED_CHECK := 2
	var _sector_player_position := Blackboard.sector_tile_map_layer.local_to_map(position)
	for sector_offset: Vector2i in Blackboard.sectors_map:
		if _sector_player_position.distance_squared_to(sector_offset) > DISTANCE_SQUARED_CHECK:
			Blackboard.sectors_map[sector_offset].queue_free()
			Blackboard.sectors_map.erase(sector_offset)
	Blackboard.spawn_enemies(spawn_tile_map_layer)
	Blackboard.spawn_stinger_enemies()
	Blackboard.generate()
