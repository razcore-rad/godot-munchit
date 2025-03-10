extends ProgressBar

signal animation_finished(anim_name: StringName)

@onready var animation_player: AnimationPlayer = $AnimationPlayer
