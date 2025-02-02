class_name PickControl extends Control

const PLAYER_MOVE_AREAS_PATH := "entities/player/move_areas"
const STEP := 7

var _move_areas: Array[Area2D] = []
var _move_area_index: int = -1:
	set(new_move_area_index):
		if _move_areas.is_empty():
			return

		for collision_shape: MoveAreaCollisionShape2D in _move_areas[_move_area_index].get_children():
			collision_shape.modulate = Palette.DARK_VIOLET

		_move_area_index = wrapi(new_move_area_index, 0, _move_areas.size())
		var move_area := _move_areas[_move_area_index]
		cost_label.text = str(move_area.cost)

		for collision_shape: MoveAreaCollisionShape2D in move_area.get_children():
			collision_shape.modulate = Palette.GREEN

		var tween := create_tween()
		tween.tween_property(areas_control, "position:x", -_move_area_index * STEP * Blackboard.TILE_SET.tile_size.x, 0.2)

@onready var areas_control: Control = %AreasControl
@onready var cost_label: Label = %CostLabel
@onready var buy_button: Button = %BuyButton
@onready var left_texture_button: TextureButton = %LeftTextureButton
@onready var right_texture_button: TextureButton = %RightTextureButton


func _ready() -> void:
	left_texture_button.pressed.connect(_on_texture_button.bind(-1))
	right_texture_button.pressed.connect(_on_texture_button.bind(1))

	var start := 0
	for move_area_file: String in DirAccess.get_files_at(PLAYER_MOVE_AREAS_PATH):
		var path := PLAYER_MOVE_AREAS_PATH.path_join(move_area_file)
		var move_area: MoveArea2D = load(path).instantiate()
		areas_control.add_child(move_area)
		move_area.position.x = start * Blackboard.TILE_SET.tile_size.x
		for collision_shape: MoveAreaCollisionShape2D in move_area.get_children():
			collision_shape.modulate = Palette.DARK_VIOLET
		_move_areas.push_back(move_area)
		start += STEP
	_move_area_index = 0


func _on_texture_button(delta: int) -> void:
	_move_area_index += delta


func get_move_area() -> MoveArea2D:
	return null if _move_areas.is_empty() else _move_areas[_move_area_index]
