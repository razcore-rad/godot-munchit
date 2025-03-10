class_name StingerEnemy2D extends Enemy2D

const MAX_DISTANCE := 400.0 ** 2

var _start_turn := Blackboard.turn_count
var _life_turns := Blackboard.rng.randi_range(2, 4)

@onready var ray_cast: RayCast2D = %RayCast2D
@onready var animated_sprite: AnimatedSprite2D = %AnimatedSprite2D
@onready var fly_gpu_particles: GPUParticles2D = %FlyGPUParticles2D
@onready var dissolve_gpu_particles: GPUParticles2D = %DissolveGPUParticles2D
@onready var skin: Node2D = %Skin2D
@onready var eyes: Node2D = %Eyes2D
@onready var shadow_sprite: Sprite2D = %ShadowSprite2D


func _ready() -> void:
	points = points
	animated_sprite.animation_finished.connect(_on_animated_sprite_animation_finished)
	while true:
		await get_tree().create_timer(Blackboard.rng.randf_range(0.5, 2.0)).timeout
		eyes.visible = not eyes.visible


func _on_animated_sprite_animation_finished() -> void:
	ASP.play_stream("stinger_woosh.ogg")
	eyes.visible = false
	fly_gpu_particles.emitting = true

	skin.rotation = skin.global_position.angle_to_point(Blackboard.player.position)

	var tween := create_tween()
	tween.tween_property(self, "position", Blackboard.player.position, 0.2)
	await tween.finished
	ASP.play_stream("stinger_impact.ogg")

	Blackboard.set_point_count(Blackboard.get_point_count() - points)
	Blackboard.player.skin_sub_viewport.remove_blob()

	skin.visible = false
	fly_gpu_particles.emitting = false
	dissolve_gpu_particles.emitting = true

	await get_tree().create_timer(dissolve_gpu_particles.lifetime).timeout
	turn_finished.emit()
	queue_free()


func start_turn() -> void:
	await _skip_process_frames()
	if position.distance_squared_to(Blackboard.player.position) > MAX_DISTANCE or Blackboard.turn_count - _start_turn > _life_turns:
		turn_finished.emit.call_deferred()
		queue_free()
		return

	ray_cast.target_position = ray_cast.to_local(Blackboard.player.position)
	ray_cast.force_raycast_update()
	await _skip_process_frames()

	var ray_cast_collider := ray_cast.get_collider()
	if ray_cast_collider != null and ray_cast_collider.owner == Blackboard.player:
		ASP.play_stream("stinger_chirp.ogg")
		points_label.visible = true
		shadow_sprite.visible = true
		animated_sprite.visible = true
		animated_sprite.play()
	else:
		turn_finished.emit.call_deferred()
