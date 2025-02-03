class_name MenuControl extends Control

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
		var move_area: MoveArea2D = _move_areas[_move_area_index]
		cost_label.text = str(move_area.cost)

		for collision_shape: MoveAreaCollisionShape2D in move_area.get_children():
			collision_shape.modulate = Palette.GREEN

		var tween := create_tween()
		tween.tween_property(areas_control, "position:x", -_move_area_index * STEP * Blackboard.TILE_SET.tile_size.x, 0.2)

		var is_bought :=  move_area.cost == 0
		var are_enough_points := Blackboard.point_count < move_area.cost

		bought_label.visible = is_bought
		buy_h_box_container.visible = not is_bought
		buy_button.disabled = are_enough_points
		start_button.disabled = not is_bought

@onready var areas_control: Control = %AreasControl
@onready var bought_label: Label = %BoughtLabel
@onready var buy_h_box_container: HBoxContainer = %BuyHBoxContainer
@onready var cost_label: Label = %CostLabel
@onready var buy_button: Button = %BuyButton
@onready var left_texture_button: TextureButton = %LeftTextureButton
@onready var right_texture_button: TextureButton = %RightTextureButton
@onready var start_button: Button = %StartButton
@onready var seed_text_edit: TextEdit = %SeedTextEdit
@onready var points_label: Label = %PointsLabel


func _ready() -> void:
	left_texture_button.pressed.connect(_on_texture_button.bind(-1))
	right_texture_button.pressed.connect(_on_texture_button.bind(1))
	buy_button.pressed.connect(_on_buy_button_pressed)

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


func _on_buy_button_pressed() -> void:
	var move_area := get_move_area()
	if move_area.cost <= Blackboard.point_count:
		var tween = create_tween().set_trans(Tween.TRANS_SINE)
		tween.tween_method(func(x: int) -> void: points_label.text = str(x), Blackboard.point_count, Blackboard.point_count - move_area.cost, 1.0)
		move_area.cost = 0
		cost_label.text = "0"


func get_move_area(is_duplicate: bool = false) -> MoveArea2D:
	var result: MoveArea2D = null
	if not _move_areas.is_empty():
		var move_area := _move_areas[_move_area_index]
		result = move_area.duplicate() if is_duplicate else move_area
	return result
