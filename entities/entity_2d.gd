class_name Entity2D extends Node2D

@warning_ignore("unused_signal")
signal turn_finished

const MoveAreaCollisionShape2DPackedScene := preload("move_area_collision_shape_2d.tscn")

@onready var areas: Node2D = %Areas2D
@onready var detect_area: Area2D = %DetectArea2D
@onready var detect_area_sprite: Sprite2D = %DetectAreaSprite2D


func _ready() -> void:
	detect_area.mouse_entered.connect(_on_detect_area_mouse.bind(true))
	detect_area.mouse_exited.connect(_on_detect_area_mouse.bind(false))


func _on_detect_area_mouse(has_entered: bool) -> void:
	detect_area_sprite.visible = has_entered


func _toggle_area_shapes(area: Area2D, info := {}) -> void:
	for collision_shape: CollisionShape2D in area.get_children():
		collision_shape.set_deferred(
			"disabled",
			info.is_disabled if "is_disabled" in info else not collision_shape.disabled
		)
	await _skip_process_frames(2)


func _skip_process_frames(n: int = 1) -> void:
	for _i in range(n):
		await get_tree().process_frame


func start_turn() -> void:
	pass


func end_turn() -> void:
	Blackboard.update_enemy_neighbor_count()
