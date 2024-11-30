class_name EnemyEntity2D extends Entity2D

signal eaten(move_area: Area2D)


func _ready() -> void:
	super()
	detect_area.connect("area_entered", _on_detect_area_area_entered)


func _on_detect_area_area_entered(_area: Area2D) -> void:
	is_my_turn = false
	queue_free()
	eaten.emit(move_area.duplicate())
	turn_finished.emit()


func _get_sorted_move_choices(to: Vector2) -> Array[Vector2]:
	var result: Array[Vector2] = []
	var direction := to - position
	var move_choices := move_area.get_children().map(
		func(cs: CollisionShape2D) -> Dictionary: return {cs = cs, angle = abs(direction.angle_to(cs.position))}
	)
	move_choices.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.angle < b.angle)
	result.assign(move_choices
		.filter(func(d: Dictionary) -> bool: return d.cs.disabled == false)
		.map(func(d: Dictionary) -> Vector2: return d.cs.position)
	)
	return result


func move(player_position: Vector2) -> void:
	var tween := create_tween()
	for target: Vector2 in _get_sorted_move_choices(player_position):
		tween.tween_property(self, "position", target, 0.25).as_relative()
		break
	await tween.finished
	_enable_move_area_collision_shapes()
