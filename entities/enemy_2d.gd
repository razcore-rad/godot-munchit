class_name Enemy2D extends Entity2D

const MOVE_RANDOM_CHANCE := 0.2


func _ready() -> void:
	detect_area.connect("mouse_entered", _on_detect_area_mouse.bind(true))
	detect_area.connect("mouse_exited", _on_detect_area_mouse.bind(false))

	areas.position = position
	move_area.visible = false

	_toggle_area_shapes(move_area, {is_disabled = true})


func _on_detect_area_mouse(has_entered: bool) -> void:
	move_area.visible = has_entered


func _get_sorted_move_choices(to: Vector2) -> Array[Vector2]:
	var result: Array[Vector2] = []
	var direction := to - position
	var move_choices := move_area.get_children().map(
		func(cs: CollisionShape2D) -> Dictionary:
			return {cs = cs, angle = abs(direction.angle_to(cs.position))}
	)
	move_choices.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.angle < b.angle)
	result.assign(
		move_choices
		. filter(func(d: Dictionary) -> bool:
			return not Blackboard.is_tile_map_layer_obstacle(d.cs.global_position))
		. map(func(d: Dictionary) -> Vector2: return d.cs.position)
	)
	return result


func _get_random_move_choices() -> Array[Vector2]:
	var result: Array[Vector2] = []
	var move_choices = move_area.get_children()
	move_choices.shuffle()
	result.assign(
		(
			move_choices
			. filter(func(cs: CollisionShape2D) -> bool:
				return not Blackboard.is_tile_map_layer_obstacle(cs.global_position))
			. map(func(cs: CollisionShape2D) -> Vector2: return cs.position)
		)
	)
	return result


func _move() -> void:
	var is_random := randf() < MOVE_RANDOM_CHANCE
	var target_positions := (
		_get_random_move_choices()
		if is_random
		else _get_sorted_move_choices(Blackboard.player.position)
	)

	for target_position: Vector2 in target_positions:
		Blackboard.enemies.erase(position)
		Blackboard.enemies[target_position] = null

		var tween := create_tween()
		areas.position = to_global(target_position).snapped(Blackboard.half_tile_size)
		var tweener := tween.tween_property(self, "position", target_position, 0.1).as_relative()
		if is_random:
			tweener.from(position.snapped(Blackboard.half_tile_size))
		break
	await skip_process_frames()


func start_turn() -> void:
	super()
	if Blackboard.is_valid(Blackboard.player):
		await _move()
	turn_finished.emit()
