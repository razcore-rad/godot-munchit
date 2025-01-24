class_name Player2D extends Entity2D

const SkinSubViewportPackedScene: PackedScene = preload("skin_sub_viewport.tscn")

const JUMP_HEIGHT := 15
const DURATION := 0.3
const MOVE_AREA_TEXTURE_RECT := Rect2(0.0, 40.0, 30.0, 20.0)
const MOVE_AREA_COLORS: Dictionary[String, Color] = {
	default = Palette.GREEN,
	hover = Palette.LIGHT_GREEN,
}

var _move_tween: Tween = create_tween()

var skin_sub_viewport: SkinSubViewport = null

@onready var skin_sub_viewport_container: SubViewportContainer = %SkinSubViewportContainer
@onready var extra: Node2D = %Extra2D
@onready var eyes: Node2D = %Eyes2D
@onready var mouth_animated_sprite: AnimatedSprite2D = %MouthAnimatedSprite2D


func _ready() -> void:
	super()

	detect_area.connect("input_event", _on_detect_area_input_event)
	_connect_move_area()

	_move_tween.stop()
	skin_sub_viewport = SkinSubViewportPackedScene.instantiate()
	skin_sub_viewport.world_2d = World2D.new()
	skin_sub_viewport_container.add_child(skin_sub_viewport)
	skin_sub_viewport.connect("blobs_removed", queue_free)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_right"):
		skin_sub_viewport.add_blob()

	elif event.is_action_pressed("ui_left"):
		skin_sub_viewport.remove_blob()

	elif event is InputEventMouseMotion:
		var mouse_global_position := get_global_mouse_position()
		for eye: ColorRect in eyes.get_children():
			eye.rotation = eyes.global_position.angle_to_point(mouse_global_position)


func _on_detect_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event.is_action_pressed("left_click"):
		turn_finished.emit()


func _on_move_area_body_shape_entered(
	_body_rid: RID, _body: Node2D, _body_shape_index: int, local_shape_index: int
) -> void:
	var collision_shape: CollisionShape2D = move_area.shape_owner_get_owner(local_shape_index)
	collision_shape.set_deferred("disabled", true)


func _on_move_area_input_event(_viewport: Node, event: InputEvent, shape_index: int) -> void:
	var collision_shape: MoveAreaCollisionShape2D = move_area.shape_owner_get_owner(shape_index)
	if event is InputEventMouse:
		collision_shape.modulate = MOVE_AREA_COLORS.hover

	if not _move_tween.is_running() and event.is_action_pressed("left_click"):
		for node: Node2D in [skin_sub_viewport.blob_animatable_body, extra]:
			var tween := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS).set_trans(Tween.TRANS_QUAD)
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
	move_area.connect("body_shape_entered", _on_move_area_body_shape_entered)
	move_area.connect("input_event", _on_move_area_input_event)
	move_area.connect("mouse_exited", _on_move_area_mouse_exited)


func _detect_enemy(target_position: Vector2) -> void:
	if Blackboard.enemies.has(target_position):
		var enemy := Blackboard.enemies[target_position]
		Blackboard.enemies.erase(target_position)
		_eat_enemy(enemy.move_area)
		enemy.queue_free()


func _eat_enemy(enemy_move_area: Area2D) -> void:
	skin_sub_viewport.add_blob.call_deferred()
	var move_area_collision_shape_positions := move_area.get_children().map(func(cs: MoveAreaCollisionShape2D) -> Vector2: return cs.position)
	for collision_shape: MoveAreaCollisionShape2D in enemy_move_area.get_children():
		if not collision_shape.position in move_area_collision_shape_positions:
			var new_move_area_collision_shape := MoveAreaCollisionShape2DPackedScene.instantiate()
			move_area.add_child(new_move_area_collision_shape)
			new_move_area_collision_shape.position = collision_shape.position
			new_move_area_collision_shape.modulate = MOVE_AREA_COLORS.default
			new_move_area_collision_shape.sprite.region_rect = MOVE_AREA_TEXTURE_RECT

	move_area.visible = true
	_toggle_area_shapes(move_area, {is_disabled = false})
	mouth_animated_sprite.play()


func end_turn() -> void:
	_toggle_area_shapes(move_area, {is_disabled = false})
	super()
