class_name Effect extends Node3D

@export var timeout: = 0.0
@export var destroy_on_timeout: = false
@export var start_activated: = false
@export var render_distance: = 1024

@onready var cpu_particles: = find_children("*", "CPUParticles3D")
@onready var gpu_particles: = find_children("*", "GPUParticles3D")

var activated: = false: set = activate


func _ready() -> void:
	if start_activated:
		activate()


func activate(state = true) -> void:
	if activated == state:
		return
	activated = state

	for particle in cpu_particles:
		particle.emitting = state
	for particle in gpu_particles:
		particle.emitting = state

	if timeout == 0.0 || state == false:
		return
	await get_tree().create_timer(timeout).timeout

	activated = false

	if destroy_on_timeout:
		queue_free()
		return

	for particle in cpu_particles:
		particle.emitting = false
	for particle in gpu_particles:
		particle.emitting = false


func set_direction(dir: = Vector3.ZERO) -> void:
	for particle in cpu_particles:
		particle.direction = dir
	for particle in gpu_particles:
		particle.direction = dir


func _physics_process(_delta) -> void:
	if !activated || !render_distance:
		return

	# optimization: only show effects that are near the player
	var view_pos: = get_viewport().get_camera_3d().global_position
	if view_pos.distance_squared_to(global_position) > render_distance:
		for particle in cpu_particles:
			particle.emitting = false
		for particle in gpu_particles:
			particle.emitting = false
	else:
		for particle in cpu_particles:
			particle.emitting = true
		for particle in gpu_particles:
			particle.emitting = true
