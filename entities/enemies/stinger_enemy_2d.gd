class_name StingerEnemy2D extends Entity2D

const MAX_DISTANCE := 400.0 ** 2

var _start_turn := Blackboard.get_turn()
var _life_turns := Blackboard.rng.randi_range(2, 4)

@onready var ray_cast: RayCast2D = %RayCast2D
@onready var animated_sprite: AnimatedSprite2D = %AnimatedSprite2D
@onready var fly_gpu_particles: GPUParticles2D = %FlyGPUParticles2D
@onready var dissolve_gpu_particles: GPUParticles2D = %DissolveGPUParticles2D
@onready var skin: Node2D = %Skin2D
@onready var eyes: Node2D = %Eyes2D


func _ready() -> void:
	animated_sprite.animation_finished.connect(_on_animated_sprite_animation_finished)
	while true:
		await get_tree().create_timer(Blackboard.rng.randf_range(0.5, 4.0)).timeout
		eyes.visible = not eyes.visible


func _on_animated_sprite_animation_finished() -> void:
	eyes.visible = false
	fly_gpu_particles.emitting = true

	skin.rotation = skin.global_position.angle_to_point(Blackboard.player.position)

	var tween := create_tween()
	tween.tween_property(self, "position", Blackboard.player.position, 0.2)
	await tween.finished

	fly_gpu_particles.emitting = false
	dissolve_gpu_particles.emitting = true

	await get_tree().create_timer(dissolve_gpu_particles.lifetime).timeout
	Blackboard.player.skin_sub_viewport.remove_blob()
	queue_free()


func start_turn() -> void:
	await _skip_process_frames()
	turn_finished.emit()

	if position.distance_squared_to(Blackboard.player.position) > MAX_DISTANCE or Blackboard.get_turn() - _start_turn > _life_turns:
		queue_free()
		return

	ray_cast.target_position = Blackboard.player.position - position
	ray_cast.force_raycast_update()
	if ray_cast.get_collider().owner == Blackboard.player:
		animated_sprite.visible = true
		animated_sprite.play()
