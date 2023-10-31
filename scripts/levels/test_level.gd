extends Node3D


var spawn_pos = Vector3(0, 1, 0)


func _ready():
	Game.world = self


func _on_world_boundary_entered(body):
	# respawn
	body.global_position = spawn_pos
	if "linear_velocity" in body:
		body.linear_velocity = Vector3()
	if "angular_velocity" in body:
		body.angular_velocity = Vector3()
