class_name Enemy2D extends Entity2D


func _get_sorted_move_choices(to: Vector2) -> Array[Vector2]:
	var result: Array[Vector2] = []
	var direction := to - position
	var move_choices := move_area.get_children().map(
		func(cs: CollisionShape2D) -> Dictionary:
			return {cs = cs, angle = abs(direction.angle_to(cs.position))}
	)
	move_choices.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.angle < b.angle)
	result.assign(
		(
			move_choices
			. filter(func(d: Dictionary) -> bool: return not d.cs.disabled)
			. map(func(d: Dictionary) -> Vector2: return d.cs.position)
		)
	)
	return result


func _get_random_move_choices() -> Array[Vector2]:
	var result: Array[Vector2] = []
	var move_choices = move_area.get_children()
	move_choices.shuffle()
	result.assign(
		(
			move_choices
			. filter(func(cs: CollisionShape2D) -> bool: return not cs.disabled)
			. map(func(cs: CollisionShape2D) -> Vector2: return cs.position)
		)
	)
	return result


func _move(is_random := false) -> void:
	var tween := create_tween()
	var positions := (
		_get_random_move_choices()
		if is_random
		else _get_sorted_move_choices(Blackboard.player.position)
	)
	for target: Vector2 in positions:
		tween.tween_property(self, "position", target, 0.25).as_relative()
		break
	await tween.finished


func start_turn() -> void:
	super()
	await _move()
	for area: Area2D in detect_area.get_overlapping_areas():
		if _is_my_turn and area.is_in_group("player"):
			await _move(true)
	turn_finished.emit()
