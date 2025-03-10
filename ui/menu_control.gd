class_name MenuControl extends Control

signal unlocked_all

const PLAYER_MOVE_AREAS_PATH := "entities/player/move_areas"
const STEP := 8

@export var save: Save = null

var _move_areas: Array[MoveArea2D] = []
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
			collision_shape.modulate = Player2D.MOVE_AREA_COLORS.default

		var tween := create_tween()
		tween.tween_property(areas_control, "position:x", -_move_area_index * STEP * Blackboard.TILE_SET.tile_size.x, 0.2)

		var is_bought :=  move_area.cost == 0
		var are_enough_points := move_area.cost <= get_menu_point_count()
		bought_label.visible = is_bought
		buy_h_box_container.visible = not is_bought
		buy_button.disabled = is_bought or not are_enough_points
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
@onready var menu_points_label: Label = %MenuPointsLabel
@onready var reset_button: Button = %ResetButton
@onready var reset_h_box_container: HBoxContainer = %ResetHBoxContainer
@onready var reset_no_button: Button = %ResetNoButton
@onready var reset_yes_button: Button = %ResetYesButton
@onready var quit_button: Button = %QuitButton


func _setup() -> void:
	set_menu_point_count(save.point_count)
	for move_area: MoveArea2D in areas_control.get_children():
		_move_areas = []
		move_area.queue_free()

	var start := 0
	for move_area_file_name: String in DirAccess.get_files_at(PLAYER_MOVE_AREAS_PATH):
		var move_area_file_path := PLAYER_MOVE_AREAS_PATH.path_join(move_area_file_name)
		var move_area: MoveArea2D = load(move_area_file_path).instantiate()
		areas_control.add_child(move_area)
		move_area.position.x = start * Blackboard.TILE_SET.tile_size.x
		if move_area_file_name in save.move_area_file_names:
			move_area.cost = 0

		for collision_shape: MoveAreaCollisionShape2D in move_area.get_children():
			collision_shape.modulate = Palette.DARK_VIOLET
		_move_areas.push_back(move_area)
		start += STEP
	_move_area_index = 0

func _ready() -> void:
	left_texture_button.pressed.connect(_on_texture_button.bind(-1))
	right_texture_button.pressed.connect(_on_texture_button.bind(1))
	buy_button.pressed.connect(_on_buy_button_pressed)
	reset_button.pressed.connect(reset_h_box_container.set_visible.bind(true))
	reset_no_button.pressed.connect(reset_h_box_container.set_visible.bind(false))
	reset_yes_button.pressed.connect(_on_reset_yes_button_pressed)
	quit_button.pressed.connect(get_tree().quit)
	_setup()


func _on_texture_button(delta: int) -> void:
	_move_area_index += delta


func _on_buy_button_pressed() -> void:
	var move_area := get_move_area()
	var menu_point_count := get_menu_point_count()
	if move_area.cost <= menu_point_count:
		var final_menu_point_count := menu_point_count - move_area.cost
		save.move_area_file_names[move_area.scene_file_path.get_file()] = null
		update_save({
			point_count = final_menu_point_count,
			move_area_file_names = save.move_area_file_names.merged({move_area.scene_file_path.get_file(): null})
		})

		bought_label.visible = true
		buy_h_box_container.visible = false
		start_button.disabled = true
		left_texture_button.disabled = true
		right_texture_button.disabled = true

		var tween = create_tween().set_trans(Tween.TRANS_SINE)
		tween.tween_method(set_menu_point_count, menu_point_count, final_menu_point_count, 1.0)
		await tween.finished

		move_area.cost = 0
		cost_label.text = "0"
		start_button.disabled = false
		left_texture_button.disabled = false
		right_texture_button.disabled = false

	if _move_areas.filter(func(m: MoveArea2D) -> bool: return m.cost > 0).is_empty():
		unlocked_all.emit()


func _on_reset_yes_button_pressed() -> void:
	set_menu_point_count(0)
	update_save({point_count =  0, move_area_file_names = {} as Dictionary[String, Variant]})
	reset_h_box_container.visible = false
	_setup()


func get_move_area(is_duplicate: bool = false) -> MoveArea2D:
	var result: MoveArea2D = null
	if not _move_areas.is_empty():
		var move_area := _move_areas[_move_area_index]
		result = move_area.duplicate() if is_duplicate else move_area
	return result


func get_menu_point_count() -> int:
	return menu_points_label.text.to_int()


func set_menu_point_count(to: int) -> void:
	menu_points_label.text = str(to)


func update_save(info: Dictionary[String, Variant]) -> void:
	for key in info:
		save.set(key, info[key])
	ResourceSaver.save(save)
