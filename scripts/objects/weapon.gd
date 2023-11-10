extends Item


@export var projectile_scene = preload("res://scenes/objects/rocket.tscn")


@rpc("any_peer", "call_local", "reliable")
func action():
	var projectile = projectile_scene.instantiate()
	add_child(projectile)
