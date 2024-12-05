class_name Player2D extends Entity2D


func _ready() -> void:
	detect_area.connect("area_entered", _on_detect_area_area_entered)
	detect_area.connect("input_event", _on_detect_area_input_event)
	_connect_move_area()


func _on_detect_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event.is_action_pressed("left_click"):
		turn_finished.emit()


func _on_detect_area_area_entered(area: Area2D) -> void:
	if not _is_my_turn and area.is_in_group("enemy"):
		queue_free()


func _on_move_area_body_shape_entered(
	_body_rid: RID, _body: Node2D, _body_shape_index: int, local_shape_index: int
) -> void:
	var collision_shape: CollisionShape2D = move_area.shape_owner_get_owner(local_shape_index)
	collision_shape.set_deferred("disabled", true)


func _on_move_area_input_event(_viewport: Node, event: InputEvent, shape_index: int) -> void:
	if _is_my_turn and event.is_action_pressed("left_click"):
		var collision_shape: CollisionShape2D = move_area.shape_owner_get_owner(shape_index)
		position += collision_shape.position

		await skip_process_frames()
		for area: Area2D in detect_area.get_overlapping_areas():
			if area.is_in_group("enemy"):
				var enemy: Enemy2D = area.owner
				_update_move_area(enemy.move_area.duplicate())
				enemy.queue_free()
		turn_finished.emit()


func _connect_move_area() -> void:
	move_area.connect("body_shape_entered", _on_move_area_body_shape_entered)
	move_area.connect("input_event", _on_move_area_input_event)


func _update_move_area(new_move_area: Area2D) -> void:
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
