class_name Effect extends Node3D

@export var timeout: = 0.0
@export var destroy_on_timeout: = false
@export var start_active: = false
@export var render_distance: = 1024
@export var pitch_range: = 0.0

@onready var cpu_particles: = find_children("*", "CPUParticles3D")
@onready var gpu_particles: = find_children("*", "GPUParticles3D")
@onready var audio_streams: = find_children("*", "AudioStreamPlayer3D")

var source:Node
var move_offset:Vector3

var active:bool: set = activate, get = is_active


func activate(value = true) -> void:
	for particle:CPUParticles3D in cpu_particles:
		particle.emitting = value
	for particle:GPUParticles3D in gpu_particles:
		particle.emitting = value
	for sound:AudioStreamPlayer3D in audio_streams:
		sound.pitch_scale += randf_range(-pitch_range, pitch_range)
		sound.playing = value

	if timeout == 0.0 || !value:
		return
	await get_tree().create_timer(timeout).timeout
	if destroy_on_timeout:
		queue_free()
		return
	activate(false)


func set_direction(dir: = Vector3.ZERO) -> void:
	for particle:CPUParticles3D in cpu_particles:
		particle.direction = dir
	for particle:GPUParticles3D in gpu_particles:
		particle.direction = dir


func _ready() -> void:
	if !source:
		source = get_parent()
		if source && "to_local" in source:
			move_offset = source.to_local(global_position)
			global_position = Vector3(0.0, -32768.0, 0.0)
		get_parent().remove_child.call_deferred(self)
		Game.effects.add_child.call_deferred(self, true)

	if start_active:
		activate()


func _physics_process(_delta) -> void:
	if !source:
		if active:
			await get_tree().create_timer(10).timeout
		queue_free()
		return
	if "to_global" in source:
		global_position = source.to_global(move_offset)

	if !active || !render_distance:
		return

	# optimization: only show effects that are near the player
	var view_pos: = get_viewport().get_camera_3d().global_position
	if view_pos.distance_squared_to(global_position) > render_distance:
		for particle:CPUParticles3D in cpu_particles:
			particle.emitting = false
		for particle:GPUParticles3D in gpu_particles:
			particle.emitting = false
	else:
		for particle:CPUParticles3D in cpu_particles:
			particle.emitting = true
		for particle:GPUParticles3D in gpu_particles:
			particle.emitting = true


func is_active() -> bool:
	for particle:CPUParticles3D in cpu_particles:
		if particle.emitting:
			return true
	for particle:GPUParticles3D in gpu_particles:
		if particle.emitting:
			return true
	for sound:AudioStreamPlayer3D in audio_streams:
		if sound.playing:
			return true

	return false
