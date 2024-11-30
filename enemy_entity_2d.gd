class_name EnemyEntity2D extends Entity2D


func _ready() -> void:
	super()
	# var tween := create_tween()
	# var final_val := _sort_move_choices(Vector2(495, 270))
	await get_tree().process_frame
	await get_tree().process_frame
	print(_sort_move_choices(Vector2(405, 230)))
	# tween.tween_property(self, "position", final_val, 0.25).as_relative()


func _sort_move_choices(to: Vector2) -> Array[Vector2]:
	var result: Array[Vector2] = []
	var direction := to - position
	var move_choices := move_area.get_children().map(
		func(cs: CollisionShape2D) -> Dictionary: return {cs = cs, angle = abs(direction.angle_to(cs.position))}
	)
	move_choices.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.angle < b.angle)
	result.assign(move_choices
		.filter(func(d: Dictionary) -> bool:
			prints(d.cs, d.cs.disabled)
			return d.cs.disabled == false)
		.map(func(d: Dictionary) -> Vector2: return d.cs.position)
	)
	return result

	# var move_priority := move_area.get_children().reduce(
	# 	func(acc, cs: CollisionShape2D) -> Dictionary:
	# 		var angle := absf(direction.angle_to(cs.position))
	# 		return {to = cs.position, angle = angle} if angle < acc.angle else acc,
	# 	{to = Vector2.ZERO, angle = INF}
	# ).to
