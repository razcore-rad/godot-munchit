extends Control

@onready var menu_control: MenuControl = %MenuControl


func _ready() -> void:
	menu_control.seed_text_edit.gui_input.connect(_on_seed_text_edit_gui_input)
	menu_control.start_button.pressed.connect(func() -> void: ASP.play_stream("start.ogg"))
	for button: BaseButton in find_children("", "BaseButton"):
		button.mouse_entered.connect(_on_button_mouse_entered.bind(button))

	for button: Button in find_children("", "Button"):
		button.pressed.connect(ASP.play_stream.bind("click.ogg"))

	for button: TextureButton in find_children("", "TextureButton"):
		button.pressed.connect(ASP.play_stream.bind("cycle.ogg"))


func _on_button_mouse_entered(button: BaseButton) -> void:
	if not button.disabled:
		ASP.play_stream("hover.ogg")


func _on_seed_text_edit_gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed():
		ASP.play_stream("type.tres")
