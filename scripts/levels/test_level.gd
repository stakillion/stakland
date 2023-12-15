extends Node3D


func _ready():
	for node in find_children("*", "RigidBody3D"):
		# save rigidbody spawn positions
		node.set_meta("spawn_pos", node.global_position)
		node.set_meta("spawn_ang", node.global_rotation)


func find_player_spawn():
	var spawn_point = $Spawns.get_children().pick_random()
	return spawn_point


func _on_world_boundary_entered(body):
	# teleport props to their spawn
	if body is RigidBody3D && body.has_meta("spawn_pos"):
		body.global_position = body.get_meta("spawn_pos")
		body.global_rotation = body.get_meta("spawn_ang")
		body.linear_velocity = Vector3()
		body.angular_velocity = Vector3()
	# teleport players to their spawn
	elif body is Pawn && body.alive:
		body.global_position = find_player_spawn().position
		body.velocity = Vector3()
	# delete items
	elif body is Item:
		body.queue_free()


func _on_mp_sync_frame():
	if !is_multiplayer_authority():
		return
	for node in find_children("*", "RigidBody3D"):
		mp_send_body_position.rpc(node.get_path(), node.position, node.rotation, node.linear_velocity, node.angular_velocity)

@rpc("unreliable_ordered")
func mp_send_body_position(node_path, pos, ang, vel, ang_vel):
	var body = get_node_or_null(node_path)
	if body:
		body.position = pos
		body.rotation = ang
		body.linear_velocity = vel
		body.angular_velocity = ang_vel
