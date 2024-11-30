class_name PlayerEntity2D extends Entity2D


func _ready() -> void:
	super()
	_is_my_turn = true
	move_area.connect("input_event", _on_move_area_input_event)


func _on_move_area_input_event(_viewport: Node, event: InputEvent, shape_index: int) -> void:
	if event.is_action_pressed("left_click"):
		var collision_shape: CollisionShape2D = move_area.shape_owner_get_owner(shape_index)
		position += collision_shape.position
		_enable_move_area_collision_shapes()
