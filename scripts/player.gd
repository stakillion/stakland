class_name Player
extends Node

# networked player data
var data = {
	pawn_scene = "res://scenes/actors/pawn.tscn",
}

# networked input
var input = {
	movement = Vector2(),
	jump = false,
	action = false,
	interact = false,
	desired_zoom = 0.0
}
var last_input = {}

# control settings
@export var mouse_sensitivity = Vector2(5.0, 5.0)
@export var joy_sensitivity = Vector2(5.0, 3.5)
@export var zoom_min = 2.0
@export var zoom_max = 4.5

# character we are controlling
var pawn = null

# camera
var camera:Camera3D
var zoom = 10.0
var cursor_aim = false


func _init(id:int, player_data = {}):
	name = str(id)
	Game.player_list.add_child(self)
	set_multiplayer_authority(id)
	data.merge(player_data, true)


func _ready():
	# create the camera
	camera = Camera3D.new()
	camera.name = "Camera"
	add_child(camera, true)
	# multiplayer tick
	Game.mp_tick.connect("timeout", mp_tick)


func _process(delta):
	if !pawn:
		return

	# lerp current camera zoom to desired zoom for smooth zoom effect
	zoom = lerp(zoom, input.desired_zoom, 3 * delta)
	# have the camera follow our pawn
	var follow_pos = pawn.head.global_position if "head" in pawn else pawn.global_position
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


func _physics_process(delta):
	# inputs
	read_input(delta)
	apply_input()


func _unhandled_input(event):
	if !is_multiplayer_authority() || Game.menu.visible:
		return

	if event is InputEventMouseMotion && Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# get mouse coordinates for camera rotation
		var angle = camera.rotation
		angle.y -= event.relative.x * (mouse_sensitivity.x / 4096)
		angle.x -= event.relative.y * (mouse_sensitivity.y / 4096)
		# rotate view
		camera.rotation = angle
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-89), deg_to_rad(89))


func read_input(delta):
	if !is_multiplayer_authority() || Game.menu.visible:
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
	input.movement = Input.get_vector("move_forward", "move_back", "move_left", "move_right")
	# jumping
	input.jump = Input.is_action_pressed("jump")
	# interaction
	input.action = Input.is_action_pressed("action")
	input.interact = Input.is_action_pressed("interact")

	# camera zoom
	if Input.is_action_just_pressed("zoom_in"):
		input.desired_zoom = clamp(input.desired_zoom - 0.5, 0.0, zoom_max) if input.desired_zoom - 0.5 >= zoom_min else 0.0
	if Input.is_action_just_pressed("zoom_out"):
		input.desired_zoom = zoom_min if input.desired_zoom + 0.5 <= zoom_min else clamp(input.desired_zoom + 0.5, 0.0, zoom_max)

	# send input over network
	if input != last_input:
		mp_send_input.rpc(input, last_input)


func apply_input():
	if !pawn || !(pawn is Pawn):
		return

	# tell our pawn to perform desired actions
	pawn.desired_move = input.movement.rotated(camera.rotation.y)

	if input.jump && !last_input.jump:
		pawn.jump()
	elif input.jump:
		pawn.jump(false)

	if input.action:
		pawn.action()
	if input.interact && !last_input.interact:
		pawn.interact()

	last_input = input.duplicate()


@rpc("authority", "call_local", "reliable")
func spawn():
	if pawn:
		pawn.name = "_Pawn"
		pawn.queue_free()

	pawn = load(data.pawn_scene).instantiate()
	add_child(pawn)
	# teleport our pawn to spawn - TODO: find a better way to look for spawns on the map
	pawn.global_position = Game.world.spawn_pos
	camera.global_rotation = Game.world.spawn_ang
	if is_multiplayer_authority():
		# activate player camera and in-game menu
		camera.make_current()
		Game.menu.toggle_player_menu()


@rpc("authority", "call_local", "reliable")
func set_pawn_variable(variable, value):
	if variable in pawn:
		pawn.set(variable, value)


func mp_tick():
	if is_multiplayer_authority():
		mp_send_view.rpc(camera.rotation)


@rpc func mp_send_input(new_input, old_input):
	input = new_input 
	last_input = old_input
	apply_input()

@rpc func mp_send_view(camera_ang):
	camera.rotation = camera_ang
