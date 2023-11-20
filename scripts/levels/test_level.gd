extends Node3D

# spawn point
@onready var spawn_pos = $SpawnPoint.global_position + Vector3(0.0, 0.75, 0.0)
@onready var spawn_ang = $SpawnPoint.global_rotation


func _on_world_boundary_entered(object):
	# respawn
	object.global_position = object.spawn_pos if "spawn_pos" in object else spawn_pos
	object.global_rotation = object.spawn_ang if "spawn_ang" in object else spawn_ang
	if "velocity" in object:
		object.velocity = Vector3()
	if "linear_velocity" in object:
		object.linear_velocity = Vector3()
	if "angular_velocity" in object:
		object.angular_velocity = Vector3()
