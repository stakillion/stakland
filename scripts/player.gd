extends Node

# control settings
@export var mouse_sensitivity = Vector2(10.0, 10.0)
@export var joy_sensitivity = Vector2(10.0, 7.5)
@export var zoom_min = 2.0
@export var zoom_max = 4.5
@export var auto_jump = true

# character we are controlling
@onready var pawn = $/root/World/Pawn

# camera
var camera:Camera3D
var ang_velocity = Vector3()
var desired_zoom = 0.0
var zoom = 20.0


func _ready():
	# give player control of pawn
	if pawn.get("controller"):
		pawn.controller = self

	# spawn camera
	camera = Camera3D.new()
	add_child(camera)
	camera.name = "Camera"
	camera.fov = 90
	camera.make_current()


func _process(delta):
	# rotate camera by angular velocity (joystick)
	if ang_velocity.length_squared() != 0.0:
		camera.rotation -= ang_velocity * delta
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-89), deg_to_rad(89))

	# lerp current camera zoom to desired zoom for smooth zoom effect
	zoom = lerp(zoom, desired_zoom, 3 * delta)

	# have camera follow pawn, or its head if it has one
	var follow_pos = pawn.global_position if !pawn.get("head") else pawn.head.global_position
	var new_pos = follow_pos + camera.global_transform.basis.z * zoom
	if zoom > 0.0:
		# check for collisions behind the camera to prevent it from going through walls
		var query = PhysicsShapeQueryParameters3D.new()
		query.transform.origin = follow_pos
		query.shape = SphereShape3D.new()
		query.shape.radius = 0.1
		query.motion = new_pos - follow_pos
		var collision = camera.get_world_3d().direct_space_state.cast_motion(query)
		new_pos = follow_pos + query.motion * collision[0]

	# update camera position
	camera.global_position = new_pos


func _unhandled_input(event):
	if event is InputEventMouseMotion:
		# get mouse coordinates for camera rotation
		var rot = camera.rotation
		rot.y -= event.relative.x * (mouse_sensitivity.x / 10000)
		rot.x -= event.relative.y * (mouse_sensitivity.y / 10000)
		# rotate view
		camera.rotation = rot
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-89), deg_to_rad(89))
	else:
		# or use input mapping to rotate over time (e.g. joystick)
		ang_velocity.y = (Input.get_action_strength("look_right") - Input.get_action_strength("look_left")) * (joy_sensitivity.x / 5)
		ang_velocity.x = (Input.get_action_strength("look_down") - Input.get_action_strength("look_up")) * (joy_sensitivity.y / 5)

	# *zoom*
	if event.is_action_released("ui_page_up"):
		desired_zoom = clamp(desired_zoom - 0.5, 0.0, zoom_max) if desired_zoom - 0.5 >= zoom_min else 0.0
	if event.is_action_released("ui_page_down"):
		desired_zoom = zoom_min if desired_zoom + 0.5 <= zoom_min else clamp(desired_zoom + 0.5, 0.0, zoom_max)


func get_aim_target():
	var ray_start = camera.global_position
	var ray_end = camera.global_position - camera.global_transform.basis.z * 32768
	var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	query.exclude = [pawn]

	var collision = camera.get_world_3d().direct_space_state.intersect_ray(query)
	if !collision:
		collision.position = ray_end

	return collision


func get_movement():
	var movement = Vector3()
	# get direction and speed from input
	movement.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	movement.z = Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	var speed = movement.length()
	# rotate direction vector according to the camera angle
	var dir = movement.rotated(Vector3.UP, camera.rotation.y).normalized()

	# jumping
	var jump = 0 # no jump
	if Input.is_action_just_pressed("jump"):
		jump = 1 # jump
	elif auto_jump && Input.is_action_pressed("jump"):
		jump = 2 # auto jump (no midair)

	return {"dir" = dir, "speed" = speed, "jump" = jump}
