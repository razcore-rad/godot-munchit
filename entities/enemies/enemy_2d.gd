class_name Enemy2D extends Entity2D

const MOVE_AREA_TEXTURE_RECT := Rect2(30.0, 40.0, 28.0, 18.0)
const MOVE_RANDOM_CHANCE := 0.2


func _ready() -> void:
	super()

	move_area.visible = false
	for collision_shape: MoveAreaCollisionShape2D in move_area.get_children():
		collision_shape.modulate = Palette.ORANGE
		collision_shape.sprite.region_rect = MOVE_AREA_TEXTURE_RECT

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
			.filter(func(d: Dictionary) -> bool: return not Blackboard.is_sector_obstacle(d.cs.global_position))
			.map(func(d: Dictionary) -> Vector2: return d.cs.position)
	)
	return result


func _get_random_move_choices() -> Array[Vector2]:
	var result: Array[Vector2] = []
	var move_choices = move_area.get_children()
	move_choices.shuffle()
	result.assign(
		move_choices
			.filter(func(cs: CollisionShape2D) -> bool: return not Blackboard.is_sector_obstacle(cs.global_position))
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

	for target_position: Vector2 in target_positions:
		target_position = to_global(target_position)
		Blackboard.enemies.erase(position)
		Blackboard.enemies[target_position] = self

		var tween := create_tween()
		tween.finished.connect(_detect_player.bind(target_position))
		var tweener := tween.tween_property(self, "position", target_position, 0.1)
		if is_random:
			tweener.from(position.snapped(Blackboard.half_tile_size))
		break
	await skip_process_frames()


func _detect_player(target_position: Vector2) -> void:
	if target_position.is_equal_approx(Blackboard.player.position):
		Blackboard.player.queue_free()


func start_turn() -> void:
	super()
	if Blackboard.is_valid(Blackboard.player):
		await _move()
	turn_finished.emit()
