class_name GamePlayer extends Node

# networked player data
var data: = {
	pawn_scene = "res://scenes/actors/pawn.tscn",
}

# networked input
var input: = {
	movement = Vector2(),
	jump = false,
	crouch = false,
	action = false,
	interact = false,
	next_item = false,
	prev_item = false,
	drop_item = false,
	in_menu = false,
	alt_look = false,
	desired_zoom = 0.0
}
var last_input: = {}

# control settings
@export var mouse_sensitivity: = Vector2(3.0, 3.0)
@export var joy_sensitivity: = Vector2(5.0, 3.5)
@export var zoom_min: = 2.0
@export var zoom_max: = 4.5

# character we are controlling
var pawn:Pawn = null

# camera
var camera:Camera3D
var cam_follow:Node3D = null
var cam_offset:Vector3
var cam_zoom: = 0.0
var aim_position:Vector3


func _init() -> void:
	# create the camera
	camera = Camera3D.new()
	camera.name = "Camera"
	add_child(camera, true)


func _ready() -> void:
	if Player == self:
		var current_cam: = get_viewport().get_camera_3d()
		camera.rotation = current_cam.global_rotation
		cam_activate(null, current_cam.global_position)


func _process(delta:float) -> void:
	var follow_pos: = Vector3()
	if cam_follow:
		# set position to the position of our follow target
		follow_pos = cam_follow.head.global_position if "head" in cam_follow else cam_follow.global_position
	elif Player == self && !input.in_menu:
		# no follow target, free cam mode
		var dir: = Vector3(input.movement.y, 0.0, input.movement.x)
		dir = dir.rotated(Vector3.RIGHT, camera.rotation.x)
		dir = dir.rotated(Vector3.UP, camera.rotation.y)
		cam_offset += dir * 24 * delta
	follow_pos += cam_offset
	# distance the camera from the follow position by our zoom level
	cam_zoom = lerp(cam_zoom, input.desired_zoom, 3 * delta)
	var zoom_vec: = camera.basis.z * cam_zoom
	if cam_zoom > 0.1: zoom_vec *= cam_cast_motion(follow_pos, zoom_vec)[0]
	# update camera position
	camera.position = follow_pos + zoom_vec

	if is_multiplayer_authority():
		if !input.alt_look && !input.in_menu:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		if input.alt_look && !input.in_menu:
			aim_position = get_aim().position
	# have the pawn look where the camera is looking
	if pawn && pawn.alive && "set_angle" in pawn:
		if input.alt_look:
			var angle: = camera.global_transform.looking_at(aim_position).basis.get_euler()
			pawn.set_angle(angle)
		else:
			pawn.set_angle(camera.rotation)


func _physics_process(delta:float) -> void:
	# inputs
	read_input(delta)
	if pawn: apply_input()
	last_input = input.duplicate()


func _unhandled_input(event:InputEvent) -> void:
	if Player != self || Game.menu.visible:
		return

	if event is InputEventMouseMotion && Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# rotate view based on mouse coordinates
		camera.rotation.y -= deg_to_rad(event.relative.x * mouse_sensitivity.x * 0.022)
		camera.rotation.x -= deg_to_rad(event.relative.y * mouse_sensitivity.y * 0.022)
		# clamp vertical rotation
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-89), deg_to_rad(89))


func read_input(delta:float) -> void:
	if Player != self:
		return

	var ang_velocity: = Input.get_vector("look_left", "look_right", "look_up", "look_down")
	if ang_velocity.length_squared() != 0.0:
		# rotate view based on angular velocity
		camera.rotation.y -= ang_velocity.x * joy_sensitivity.x * delta
		camera.rotation.x -= ang_velocity.y * joy_sensitivity.y * delta
		# clamp vertical rotation
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-89), deg_to_rad(89))

	# directional movement
	input.movement = Input.get_vector("move_forward", "move_back", "move_left", "move_right")
	# jumping, crouching
	input.jump = Input.is_action_pressed("jump")
	input.crouch = Input.is_action_pressed("crouch")
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

	input.alt_look = Input.is_action_pressed("alt_look")

	input.in_menu = Game.menu.visible

	# send input over network
	if input != last_input && is_multiplayer_authority():
		if input.alt_look:
			mp_send_view.rpc(camera.rotation, aim_position)
		else:
			mp_send_view.rpc(camera.rotation)
		mp_send_input.rpc(input, last_input)


# tells our pawn to perform desired actions
func apply_input() -> void:
	if input.in_menu:
		pawn.desired_move = Vector2()
	elif pawn.alive:
		pawn.desired_move = input.movement.rotated(camera.rotation.y)
		# jumping, crouching
		if input.jump && !last_input.jump:
			pawn.jump()
		elif input.jump:
			pawn.jump(false)
		if input.crouch && !last_input.crouch:
			pawn.crouch(true)
		elif !input.crouch && last_input.crouch:
			pawn.crouch(false)
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


@rpc("call_local", "reliable")
func spawn() -> void:
	if pawn:
		# dispose of existing pawn
		pawn.queue_free()
		pawn.name += "_"
	# create pawn
	pawn = load(data.pawn_scene).instantiate()
	add_child(pawn)
	# teleport our pawn to spawn
	var spawn_point:Node3D = Game.world.find_player_spawn()
	pawn.set_origin(spawn_point.position)
	pawn.set_angle(spawn_point.rotation)
	# have the camera follow our pawn
	cam_activate(pawn, Vector3.ZERO, 5.0)

	if Player == self:
		Game.menu.update_settings()


@rpc("call_local", "reliable")
func set_physics_parameter(property, value) -> void:
	pawn.physics[property] = value


func cam_activate(follow:Node3D = null, offset: = Vector3.ZERO, zoom: = 0.0) -> void:
	cam_follow = follow
	cam_offset = offset
	cam_zoom = zoom
	if follow:
		camera.rotation.y = follow.rotation.y
		camera.rotation.x = follow.head.rotation.x if "head" in follow else follow.rotation.x
	if Player == self:
		camera.make_current()


func cam_cast_motion(start:Vector3, motion:Vector3) -> PackedFloat32Array:
	var query: = PhysicsShapeQueryParameters3D.new()
	query.transform.origin = start
	query.shape = SphereShape3D.new()
	query.shape.radius = 0.1
	query.motion = motion
	query.exclude = [cam_follow] + cam_follow.find_children("*") if cam_follow else []
	return camera.get_world_3d().direct_space_state.cast_motion(query)


func get_aim(distance: = 32768.0, exclude: = []) -> Dictionary:
	var ray_start: = camera.global_position
	var ray_end:Vector3
	if input.alt_look:
		ray_end = camera.project_position(get_viewport().get_mouse_position(), distance)
	else:
		ray_end = camera.global_position - camera.global_transform.basis.z * distance
	var query: = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	query.exclude = [self] + find_children("*") + exclude
	# check for collision
	var collision: = camera.get_world_3d().direct_space_state.intersect_ray(query)
	if !collision:
		# if we missed, set position to end position anyway
		collision.position = ray_end
		collision.collider = null

	return collision


func _on_mp_sync_frame() -> void:
	if !is_multiplayer_authority():
		return
	if input.alt_look:
		mp_send_view.rpc(camera.rotation, aim_position)
	else:
		mp_send_view.rpc(camera.rotation)

@rpc("unreliable_ordered")
func mp_send_input(new_input:Dictionary, old_input:Dictionary) -> void:
	input = new_input
	last_input = old_input
	if pawn: apply_input()
	last_input = input.duplicate()

@rpc("unreliable_ordered")
func mp_send_view(camera_ang:Vector3, aim_pos: = Vector3.ZERO) -> void:
	camera.rotation = camera_ang
	aim_position = aim_pos
