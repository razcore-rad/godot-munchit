extends AudioStreamPlayer

const DIR_PATH := "res://assets/sfx"

var _audio_stream_playback: AudioStreamPlaybackPolyphonic = null

func _ready() -> void:
	play()
	_audio_stream_playback = get_stream_playback()


func play_stream(file_name: String) -> int:
	var audio_stream := load(DIR_PATH.path_join(file_name))
	return _audio_stream_playback.play_stream(audio_stream)


func stop_stream(id: int) -> void:
	_audio_stream_playback.stop_stream(id)
