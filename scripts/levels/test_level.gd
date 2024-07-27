extends Node3D

var area_env: = {}


func _ready() -> void:
	for area in find_children("*", "Area3D"):
		var env = area.get_meta("environment", false)
		if env:
			area_env[area] = env
		area.body_entered.connect(_on_environment_entered.bind(area))
		area.body_exited.connect(_on_environment_exited.bind(area))
		area.area_entered.connect(_on_environment_entered.bind(area))
		area.area_exited.connect(_on_environment_exited.bind(area))
	for node in find_children("*", "RigidBody3D"):
		# save rigidbody spawn positions
		node.set_meta("spawn_pos", node.global_position)
		node.set_meta("spawn_ang", node.global_rotation)


func find_player_spawn() -> Node3D:
	return $Spawns.get_children().pick_random()


func _on_world_boundary_entered(body:Node3D) -> void:
	# teleport props to their spawn
	if body is RigidBody3D && body.has_meta("spawn_pos"):
		body.global_position = body.get_meta("spawn_pos")
		body.global_rotation = body.get_meta("spawn_ang")
		body.linear_velocity = Vector3.ZERO
		body.angular_velocity = Vector3.ZERO
	# teleport players to their spawn
	elif body is Pawn && body.alive:
		var spawn_point: = find_player_spawn()
		body.set_origin(spawn_point.position)
		body.set_angle(spawn_point.rotation)
		body.velocity = Vector3.ZERO
	# delete items
	elif body is Item:
		body.queue_free()


func _on_environment_entered(node:Node3D, area:Area3D) -> void:
	if area.get_meta("is_water", false) && node is KinematicBody:
		node.in_water = true
	if is_instance_valid(Player) && node == Player.cam_area:
		Player.camera.environment = area_env[area]


func _on_environment_exited(node:Node3D, area:Area3D) -> void:
	if area.get_meta("is_water", false) && node is KinematicBody:
		node.in_water = false
	if is_instance_valid(Player) && node == Player.cam_area:
		Player.camera.environment = null


func _on_mp_sync_frame() -> void:
	if !is_multiplayer_authority():
		return
	for node in find_children("*", "RigidBody3D"):
		mp_send_body_position.rpc(node.get_path(), node.position, node.rotation, node.linear_velocity, node.angular_velocity)

@rpc("unreliable_ordered")
func mp_send_body_position(node_path:NodePath, pos:Vector3, ang:Vector3, vel:Vector3, ang_vel:Vector3) -> void:
	var body: = get_node_or_null(node_path) as RigidBody3D
	if body:
		body.position = pos
		body.rotation = ang
		body.linear_velocity = vel
		body.angular_velocity = ang_vel
