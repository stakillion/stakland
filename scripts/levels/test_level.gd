extends Node3D


func _ready():
	for node in get_children():
		if not node is RigidBody3D:
			continue
		# save rigidbody spawn positions
		node.set_meta("spawn_pos", node.global_position)
		node.set_meta("spawn_ang", node.global_rotation)


func find_player_spawn():
	var spawn_point = $Spawns.get_children().pick_random()
	return {position = spawn_point.global_position + Vector3(0.0, 0.75, 0.0),
			rotation = spawn_point.global_rotation}


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
