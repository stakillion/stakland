class_name player
extends Node

# networked player data
var data = {
	pawn_scene = "res://scenes/actors/pawn.tscn",
}

# networked input
var last_input = {}
var input = {
	movement = Vector2(),
	jump = false,
	action = false,
	interact = false,
	next_item = false,
	prev_item = false,
	drop_item = false,
	in_menu = false,
	desired_zoom = 0.0
}

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
var last_view:Vector3


func _init():
	last_input = input.duplicate()

	# create the camera
	camera = Camera3D.new()
	camera.name = "Camera"
	add_child(camera, true)


func _ready():
	# multiplayer sync
	Game.mp_sync.connect("timeout", mp_sync)


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
	if !pawn:
		return

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
	if !is_multiplayer_authority():
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
	# inventory management
	input.next_item = Input.is_action_pressed("next_item")
	input.prev_item = Input.is_action_pressed("prev_item")
	input.drop_item = Input.is_action_pressed("drop_item")

	# camera zoom
	if Input.is_action_just_pressed("zoom_in"):
		input.desired_zoom = clamp(input.desired_zoom - 0.5, 0.0, zoom_max) if input.desired_zoom - 0.5 >= zoom_min else 0.0
	if Input.is_action_just_pressed("zoom_out"):
		input.desired_zoom = zoom_min if input.desired_zoom + 0.5 <= zoom_min else clamp(input.desired_zoom + 0.5, 0.0, zoom_max)

	input.in_menu = Game.menu.visible

	# send input over network
	if input != last_input:
		mp_send_view.rpc(camera.rotation)
		mp_send_input.rpc(input, last_input)


# tells our pawn to perform desired actions
func apply_input():
	# directional movement
	if input.in_menu:
		pawn.desired_move = Vector2()
	elif pawn.alive:
		pawn.desired_move = input.movement.rotated(camera.rotation.y)
		# jumping
		if input.jump && !last_input.jump:
			pawn.jump()
		elif input.jump:
			pawn.jump(false)
		# interaction
		if input.action:
			pawn.action()
		if input.interact && !last_input.interact:
			pawn.interact()
		# inventory management
		if input.next_item && !last_input.next_item:
			pawn.item_next()
		if input.prev_item && !last_input.prev_item:
			pawn.item_prev()
		if input.drop_item && !last_input.drop_item:
			pawn.item_drop()
	elif is_multiplayer_authority():
		if input.jump && !last_input.jump || input.action && !last_input.action:
			spawn.rpc()

	last_input = input.duplicate()


@rpc("authority", "call_local", "reliable")
func spawn():
	if pawn:
		remove_child(pawn)
		pawn.queue_free()

	pawn = load(data.pawn_scene).instantiate()
	add_child(pawn)
	# teleport our pawn to spawn
	pawn.global_position = Game.world.find_player_spawn().position
	camera.global_rotation = Game.world.find_player_spawn().rotation
	if is_multiplayer_authority():
		# activate player camera and in-game menu
		camera.make_current()
		Game.menu.toggle_player_menu()


@rpc("authority", "call_local", "reliable")
func set_physics_parameter(property, value):
	if "physics" in pawn:
		pawn.physics[property] = value


func mp_sync():
	if is_multiplayer_authority():
		if last_view != camera.rotation:
			last_view = camera.rotation
			mp_send_view.rpc(camera.rotation)

@rpc("unreliable_ordered")
func mp_send_input(new_input, old_input):
	input = new_input
	last_input = old_input
	apply_input()

@rpc("unreliable_ordered")
func mp_send_view(camera_ang):
	camera.rotation = camera_ang
