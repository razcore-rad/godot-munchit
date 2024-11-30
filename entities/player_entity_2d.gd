class_name PlayerEntity2D extends Entity2D


func _ready() -> void:
	super()
	move_area.connect("input_event", _on_move_area_input_event)


func _on_move_area_input_event(_viewport: Node, event: InputEvent, shape_index: int) -> void:
	if is_my_turn and event.is_action_pressed("left_click"):
		var collision_shape: CollisionShape2D = move_area.shape_owner_get_owner(shape_index)
		position += collision_shape.position
		_enable_move_area_collision_shapes()


func _connect_move_area() -> void:
	move_area.connect("area_shape_entered", _on_move_area_area_shape_entered)
	move_area.connect("input_event", _on_move_area_input_event)


func update_move_area(new_move_area: Area2D) -> void:
	move_area.queue_free()
	add_child.call_deferred(new_move_area)
	move_area = new_move_area
	_connect_move_area()
