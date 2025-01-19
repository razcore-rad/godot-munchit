class_name Player2D extends Entity2D

const SkinSubViewportPackedScene: PackedScene = preload("skin_sub_viewport.tscn")

const JUMP_HEIGHT := 15
const DURATION := 0.3

var skin_sub_viewport: SkinSubViewport = null

@onready var skin_sub_viewport_container: SubViewportContainer = %SkinSubViewportContainer
@onready var eyes: Node2D = %Eyes2D


func _ready() -> void:
	detect_area.connect("input_event", _on_detect_area_input_event)
	_connect_move_area()

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
	if _is_my_turn and event.is_action_pressed("left_click"):
		for node: Node2D in [skin_sub_viewport.blob_animatable_body, eyes]:
			var tween := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS).set_trans(Tween.TRANS_QUAD)
			tween.tween_property(node, "position:y", -JUMP_HEIGHT, DURATION).as_relative()
			tween.tween_property(node, "position:y", JUMP_HEIGHT, DURATION).as_relative()

		var collision_shape: CollisionShape2D = move_area.shape_owner_get_owner(shape_index)
		var target_position := collision_shape.global_position
		var tween := create_tween()
		tween.tween_property(self, "position", target_position, 2.0 * DURATION)
		await tween.finished
		_detect_enemy(target_position)
		turn_finished.emit()


func _connect_move_area() -> void:
	move_area.connect("body_shape_entered", _on_move_area_body_shape_entered)
	move_area.connect("input_event", _on_move_area_input_event)


func _detect_enemy(target_position: Vector2) -> void:
	if Blackboard.enemies.has(target_position):
		var enemy := Blackboard.enemies[target_position]
		Blackboard.enemies.erase(target_position)
		eat_enemy(enemy.move_area.duplicate())
		enemy.queue_free()


func eat_enemy(new_move_area: Area2D) -> void:
	skin_sub_viewport.add_blob.call_deferred()
	var collision_layer := move_area.collision_layer
	var collision_mask := move_area.collision_mask

	move_area.queue_free()
	add_child.call_deferred(new_move_area)
	move_area = new_move_area
	move_area.visible = true

	move_area.set_deferred("collision_layer", collision_layer)
	move_area.set_deferred("collision_mask", collision_mask)
	_toggle_area_shapes(move_area, {is_disabled = false})
	_connect_move_area()


func end_turn() -> void:
	_toggle_area_shapes(move_area, {is_disabled = false})
	super()
