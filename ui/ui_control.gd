extends Control

const AUDIO: Dictionary[String, Dictionary] = {
	click = {
		stream =  preload("../assets/sfx/click.ogg"),
		volume_db = -6.0,
	},
	hover = {
		stream = preload("../assets/sfx/hover.ogg"),
		volume_db = -10.0,
	},
	cycle = {
		stream = preload("../assets/sfx/cycle.ogg"),
		volume_db = -8.0,
	},
	type = {
		stream = preload("../assets/sfx/type/type.tres"),
		volume_db = 0.0,
	}
}

var _audio_stream_playback: AudioStreamPlaybackPolyphonic = null

@onready var ui_audio_stream_player: AudioStreamPlayer = %UIAudioStreamPlayer
@onready var seed_text_edit: TextEdit = %SeedTextEdit


func _ready() -> void:
	ui_audio_stream_player.play()
	_audio_stream_playback = ui_audio_stream_player.get_stream_playback()

	seed_text_edit.gui_input.connect(_on_seed_text_edit_gui_input)
	for button: BaseButton in find_children("", "BaseButton"):
		button.mouse_entered.connect(_on_button_mouse_entered.bind(button))
		
	for button: Button in find_children("", "Button"):
		button.pressed.connect(_play_sound.bind("click"))

	for button: TextureButton in find_children("", "TextureButton"):
		button.pressed.connect(_play_sound.bind("cycle"))


func _on_button_mouse_entered(button: BaseButton) -> void:
	if not button.disabled:
		_play_sound("hover")


func _on_seed_text_edit_gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed():
		_play_sound("type")


func _play_sound(id: String) -> void:
	var audio: Dictionary = AUDIO[id]
	_audio_stream_playback.play_stream(audio.stream, 0.0, audio.volume_db)
