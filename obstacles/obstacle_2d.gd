class_name Obstacle2D extends Node2D

@onready var area: Area2D = %Area2D


func get_size() -> Vector2:
	var result := Vector2.ZERO
	for collision_shape:CollisionShape2D in area.get_children():
		result += collision_shape.position
	return result
