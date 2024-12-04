class_name Entity2D extends Node2D

signal turn_finished

var _is_my_turn := false

@onready var detect_area: Area2D = %DetectArea2D
@onready var move_area: Area2D = %MoveArea2D


func _ready() -> void:
	move_area.connect("body_shape_entered", _on_move_area_body_shape_entered)


func _on_move_area_body_shape_entered(
	_body_rid: RID, _body: Node2D, _body_shape_index: int, local_shape_index: int
) -> void:
	var collision_shape: CollisionShape2D = move_area.shape_owner_get_owner(local_shape_index)
	collision_shape.set_deferred("disabled", true)


func _toggle_area_shapes(area: Area2D, info := {}) -> void:
	for collision_shape: CollisionShape2D in area.get_children():
		collision_shape.set_deferred(
			"disabled",
			info.is_disabled if "is_disabled" in info else not collision_shape.is_disabled
		)


func _enable_move_area_collision_shapes() -> void:
	for collision_shape: CollisionShape2D in move_area.get_children():
		collision_shape.disabled = false


func start_turn() -> void:
	_is_my_turn = true


func end_turn() -> void:
	_is_my_turn = false
	_toggle_area_shapes(move_area, {is_disabled = false})
