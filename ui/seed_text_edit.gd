class_name SeedTextEdit extends TextEdit

var _regex := RegEx.create_from_string(r"[^\w]*")


func _ready() -> void:
	text_changed.connect(_on_text_changed)


func _on_text_changed() -> void:
	var caret_column := get_caret_column()
	var valid_text := _regex.sub(text, "", true)
	var do_set_caret_column := text != valid_text
	text = valid_text
	set_caret_column(caret_column - (1 if do_set_caret_column else 0))


func get_seed_text() -> String:
	return placeholder_text if text.is_empty() else text
