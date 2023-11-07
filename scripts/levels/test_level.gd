extends Node3D

# spawn point
@onready var spawn_pos = $SpawnPoint.global_position
@onready var spawn_ang = $SpawnPoint.global_rotation


func _ready():
	Game.world = self


func _on_world_boundary_entered(body):
	# respawn
	body.global_position = body.spawn_pos if "spawn_pos" in body else spawn_pos
	body.global_rotation = body.spawn_ang if "spawn_ang" in body else spawn_ang
	if "linear_velocity" in body:
		body.linear_velocity = Vector3()
	if "angular_velocity" in body:
		body.angular_velocity = Vector3()
