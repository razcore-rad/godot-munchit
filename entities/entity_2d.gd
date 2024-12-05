class_name Entity2D extends Node2D

signal turn_finished

var _is_my_turn := false

@onready var areas: Node2D = %Areas2D
@onready var detect_area: Area2D = %DetectArea2D
@onready var move_area: Area2D = %MoveArea2D


func _toggle_area_shapes(area: Area2D, info := {}) -> void:
	for collision_shape: CollisionShape2D in area.get_children():
		collision_shape.set_deferred(
			"disabled",
			info.is_disabled if "is_disabled" in info else not collision_shape.is_disabled
		)


func skip_process_frames(n: int = 2) -> void:
	for _i in range(n):
		await get_tree().process_frame


func start_turn() -> void:
	_is_my_turn = true


func end_turn() -> void:
	_is_my_turn = false
