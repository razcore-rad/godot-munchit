class_name Entity2D extends Node2D

signal turn_finished

@warning_ignore("unused_private_class_variable")
var is_my_turn := false

@onready var detect_area: Area2D = %DetectArea2D
@onready var move_area: Area2D = %MoveArea2D


func _ready() -> void:
	move_area.connect("area_shape_entered", _on_move_area_area_shape_entered)


func _on_move_area_area_shape_entered(_area_rid: RID, _area: Area2D, _area_shape_index: int, local_shape_index: int) -> void:
	var collision_shape: CollisionShape2D = move_area.shape_owner_get_owner(local_shape_index)
	collision_shape.set_deferred("disabled", true)


func _enable_move_area_collision_shapes() -> void:
	for collision_shape: CollisionShape2D in move_area.get_children():
		collision_shape.disabled = false
	is_my_turn = false
	turn_finished.emit()
