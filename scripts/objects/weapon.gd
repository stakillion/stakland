extends Item


@export var projectile_scene = preload("res://scenes/objects/rocket.tscn")


func action():
	var projectile = projectile_scene.instantiate()
	add_child(projectile)
