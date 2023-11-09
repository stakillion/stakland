class_name Player
extends Node

var spawned = false

# control settings
@export var mouse_sensitivity = Vector2(10.0, 10.0)
@export var joy_sensitivity = Vector2(10.0, 7.5)
@export var zoom_min = 2.0
@export var zoom_max = 4.5
@export var auto_jump = true

# character we are controlling
@export var pawn_scene = preload("res://scenes/actors/pawn.tscn")
var pawn:Pawn

# camera
var camera:Camera3D
var ang_velocity = Vector2()
var desired_zoom = 0.0
var zoom = 10.0

# hud
@export var hud_scene = preload("res://scenes/ui/hud.tscn")
var hud:Control


func _init(id:int):
	name = str(id)
	Game.player_list.add_child(self)
	set_multiplayer_authority(id)


func _ready():
	# create the pawn
	pawn = pawn_scene.instantiate()
	add_child(pawn)

	# create the camera
	camera = Camera3D.new()
	camera.name = "Camera"
	add_child(camera)

	# create the hud
	hud = hud_scene.instantiate()
	add_child(hud)

	# set as inactive until we spawn
	camera.current = false
	hud.visible = false
	pawn.process_mode = PROCESS_MODE_DISABLED
	if !is_multiplayer_authority() || name.to_int() != 1:
		pawn.visible = false

	# move pawn in front of the camera
	var current_cam = get_viewport().get_camera_3d()
	pawn.global_position = current_cam.global_position - current_cam.global_transform.basis.z * 2
	pawn.global_position -= Vector3(0.0, 0.75, 0.0)
	pawn.head.look_at(current_cam.global_position)


@rpc("any_peer", "call_local", "reliable")
func spawn():
	pawn.visible = true
	pawn.process_mode = PROCESS_MODE_INHERIT
	# teleport pawn to spawn - TODO: find a better way to look for spawns on the map
	pawn.global_position = Game.world.spawn_pos
	camera.global_rotation = Game.world.spawn_ang
	# tell the game we have spawned
	spawned = true
	if is_multiplayer_authority():
		camera.make_current()
		hud.visible = true
		Game.menu.toggle_player_menu()


func _process(delta):
	# rotate camera by angular velocity (joystick)
	if ang_velocity.length_squared() != 0.0:
		camera.rotation -= ang_velocity * delta
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-89), deg_to_rad(89))

	# inputs
	process_inputs()

	# lerp current camera zoom to desired zoom for smooth zoom effect
	if camera.current:
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
	if !spawned || Game.menu.visible || !is_multiplayer_authority():
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
			pawn.interact.rpc()
	if Input.is_action_just_pressed("action"):
		if pawn.has_method("action"):
			pawn.action.rpc()

	# camera zoom
	if Input.is_action_just_pressed("zoom_in"):
		desired_zoom = clamp(desired_zoom - 0.5, 0.0, zoom_max) if desired_zoom - 0.5 >= zoom_min else 0.0
	if Input.is_action_just_pressed("zoom_out"):
		desired_zoom = zoom_min if desired_zoom + 0.5 <= zoom_min else clamp(desired_zoom + 0.5, 0.0, zoom_max)


func _unhandled_input(event):
	if !spawned || Game.menu.visible || !is_multiplayer_authority():
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
