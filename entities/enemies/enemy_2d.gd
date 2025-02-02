class_name Enemy2D extends Entity2D

const MOVE_RANDOM_CHANCE := 0.2

@onready var move_area: Area2D = %MoveArea2D


func _ready() -> void:
	super()
	move_area.visible = false
	_toggle_area_shapes(move_area, {is_disabled = true})


func _on_detect_area_mouse(has_entered: bool) -> void:
	super(has_entered)
	move_area.visible = has_entered


func _get_sorted_move_choices(to: Vector2) -> Array[Vector2]:
	var result: Array[Vector2] = []
	var move_choices := move_area.get_children().map(
		func(cs: CollisionShape2D) -> Dictionary:
			return {cs = cs, distance = to.distance_to(cs.global_position)}
	)
	move_choices.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.distance < b.distance)
	result.assign(
		move_choices
			.filter(func(d: Dictionary) -> bool: return not Blackboard.is_obstacle(d.cs.global_position))
			.map(func(d: Dictionary) -> Vector2: return d.cs.position)
	)
	return result


func _get_random_move_choices() -> Array[Vector2]:
	var result: Array[Vector2] = []
	var move_choices = move_area.get_children()
	move_choices.shuffle()
	result.assign(
		move_choices
			.filter(func(cs: CollisionShape2D) -> bool: return not Blackboard.is_obstacle(cs.global_position))
			.map(func(cs: CollisionShape2D) -> Vector2: return cs.position)
	)
	return result


func _move() -> void:
	var is_random := randf() < MOVE_RANDOM_CHANCE
	var target_positions := (
		_get_random_move_choices()
		if is_random
		else _get_sorted_move_choices(Blackboard.player.position)
	)

	var original_position := position
	for target_position: Vector2 in target_positions:
		target_position = to_global(target_position)
		Blackboard.enemies_map.erase(position)
		Blackboard.enemies_map[target_position] = self

		var tween := create_tween()
		var tweener := tween.tween_property(self, "position", target_position, 0.05)
		if is_random:
			tweener.from(position.snapped(Blackboard.half_tile_size))
		await _detect_player(tween, original_position, target_position)
		break
	await _skip_process_frames()


func _detect_player(tween: Tween, original_position: Vector2, target_position: Vector2) -> void:
	if Blackboard.is_valid(Blackboard.player) and target_position.is_equal_approx(Blackboard.player.position):
		await tween.finished
		await _eat_player(original_position, target_position)


func _eat_player(original_position: Vector2, target_position: Vector2) -> void:
	Blackboard.player.skin_sub_viewport.remove_blob()
	var player_move_area_collision_shape_positions: Dictionary[Vector2, MoveAreaCollisionShape2D] = {}
	for collision_shape: MoveAreaCollisionShape2D in Blackboard.player.move_area.get_children():
		player_move_area_collision_shape_positions[collision_shape.position] = collision_shape

	for collision_shape: MoveAreaCollisionShape2D in move_area.get_children():
		if collision_shape.position in player_move_area_collision_shape_positions:
			player_move_area_collision_shape_positions[collision_shape.position].queue_free()

	var tween := create_tween()
	tween.tween_property(self, "position", original_position, 0.1)
	await tween.finished

	Blackboard.enemies_map.erase(target_position)
	Blackboard.enemies_map[original_position] = self


func start_turn() -> void:
	if Blackboard.is_valid(Blackboard.player):
		await _move()
	turn_finished.emit()
