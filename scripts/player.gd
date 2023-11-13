class_name Player
extends Node

var spawned = false

# control settings
@export var mouse_sensitivity = Vector2(5.0, 5.0)
@export var joy_sensitivity = Vector2(5.0, 3.5)
@export var zoom_min = 2.0
@export var zoom_max = 4.5
@export var auto_jump = true

# character we are controlling
@export var pawn_scene = preload("res://scenes/actors/pawn.tscn")
var pawn = null

# camera
var camera:Camera3D
var desired_zoom = 0.0
var zoom = 10.0
var cursor_aim = false

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
	# inputs
	process_inputs(delta)

	# lerp current camera zoom to desired zoom for smooth zoom effect
	if spawned:
		zoom = lerp(zoom, desired_zoom, 3 * delta)

	# have camera follow the pawn, or its head if it has one
	var follow_pos = pawn.global_position if !pawn.get("head") else pawn.head.global_position
	var new_pos = follow_pos + camera.global_transform.basis.z * zoom
	if zoom > 0.1:
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


func process_inputs(delta):
	if !is_multiplayer_authority() || !spawned:
		return
	if Game.menu.visible:
		pawn.desired_move = Vector2()
		return

	# rotate camera by angular velocity (joystick)
	var ang_velocity = Input.get_vector("look_left", "look_right", "look_up", "look_down")
	if ang_velocity.length_squared() != 0.0:
		var rot = Vector3()
		rot.x = ang_velocity.y * joy_sensitivity.y
		rot.y = ang_velocity.x * joy_sensitivity.x
		# rotate view
		camera.rotation -= rot * delta
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-89), deg_to_rad(89))

	# directional movement
	pawn.desired_move = Input.get_vector("move_forward", "move_back", "move_left", "move_right")
	pawn.desired_move = pawn.desired_move.rotated(camera.rotation.y)

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

	# aim with projected cursor position
	if Input.is_action_pressed("cursor_aim"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		cursor_aim = true
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		cursor_aim = false


func _unhandled_input(event):
	if !is_multiplayer_authority() || !spawned || Game.menu.visible:
		return

	if event is InputEventMouseMotion && Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# get mouse coordinates for camera rotation
		var rot = camera.rotation
		rot.y -= event.relative.x * (mouse_sensitivity.x / 4096)
		rot.x -= event.relative.y * (mouse_sensitivity.y / 4096)
		# rotate view
		camera.rotation = rot
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-89), deg_to_rad(89))


func get_aim(distance = 32768.0, exclude = [pawn]):
	var ray_start = camera.global_position
	var ray_end
	# raycast from camera position to either center of view or cursor position
	if cursor_aim:
		ray_end = camera.project_position(get_viewport().get_mouse_position(), distance)
	else:
		ray_end = camera.global_position - camera.global_transform.basis.z * distance
	var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	query.exclude = exclude
	# check for collision
	var collision = camera.get_world_3d().direct_space_state.intersect_ray(query)
	if !collision:
		# if we missed, set position to end position anyway
		collision.position = ray_end
		collision.collider = null

	return collision
