extends Node

# control settings
@export var mouse_sensitivity = Vector2(10.0, 10.0)
@export var joy_sensitivity = Vector2(10.0, 7.5)
@export var zoom_min = 2.0
@export var zoom_max = 4.5
@export var auto_jump = true

# character we are controlling
@onready var pawn = find_child("Pawn")

# camera
@onready var camera = find_child("Camera")
var ang_velocity = Vector2()
var desired_zoom = 0.0
var zoom = 10.0

# hud
@onready var hud = find_child("Hud")


func _enter_tree():
	set_multiplayer_authority(name.to_int())


func _ready():
	# teleport pawn to spawn - TODO: find a better way to look for spawns on the map
	pawn.global_position = $/root/World/SpawnPoint.global_position

	# tell the game if we are the player
	if is_multiplayer_authority():
		camera.make_current()
		hud.visible = true
		Game.player = self
		Game.menu.enable_game_menu()
	else:
		hud.visible = false


func _process(delta):
	if !pawn:
		return

	# rotate camera by angular velocity (joystick)
	if ang_velocity.length_squared() != 0.0:
		camera.rotation -= ang_velocity * delta
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-89), deg_to_rad(89))

	# inputs
	process_inputs()

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


func process_inputs():
	if Game.menu.visible || !is_multiplayer_authority():
		return

	# directional movement
	var dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	pawn.movement.x = dir.x
	pawn.movement.z = dir.y
	pawn.movement = pawn.movement.rotated(Vector3.UP, camera.rotation.y).normalized()

	# jumping
	if Input.is_action_just_pressed("jump"):
		pawn.jump()
	elif auto_jump && Input.is_action_pressed("jump"):
		pawn.jump(false) # auto jump (no midair)

	# interaction
	if Input.is_action_just_pressed("interact"):
		if pawn.has_method("interact"):
			pawn.interact()
	if Input.is_action_just_pressed("action"):
		if pawn.has_method("action"):
			pawn.action()

	# camera zoom
	if Input.is_action_just_pressed("zoom_in"):
		desired_zoom = clamp(desired_zoom - 0.5, 0.0, zoom_max) if desired_zoom - 0.5 >= zoom_min else 0.0
	if Input.is_action_just_pressed("zoom_out"):
		desired_zoom = zoom_min if desired_zoom + 0.5 <= zoom_min else clamp(desired_zoom + 0.5, 0.0, zoom_max)


func _unhandled_input(event):
	if Game.menu.visible || !is_multiplayer_authority():
		return
	if !pawn:
		return

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
		ang_velocity = Input.get_vector("look_left", "look_right", "look_up", "look_down")
		#ang_velocity.y = (Input.get_action_strength("look_right") - Input.get_action_strength("look_left")) * (joy_sensitivity.x / 5)
		#ang_velocity.x = (Input.get_action_strength("look_down") - Input.get_action_strength("look_up")) * (joy_sensitivity.y / 5)


func get_aim_target(distance = 32768.0, exclude = [pawn]):
	var ray_start = camera.global_position
	var ray_end = camera.global_position - camera.global_transform.basis.z * distance
	var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	query.exclude = exclude

	var collision = camera.get_world_3d().direct_space_state.intersect_ray(query)
	if !collision:
		collision.position = ray_end
		collision.collider = null

	return collision
