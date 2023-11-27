extends Item

@export var projectile_scene = preload("res://scenes/objects/rocket.tscn")
@export var cooldown = 500
var last_fire:int


func action():
	var tick = Time.get_ticks_msec()
	if last_fire + cooldown > tick:
		return
	last_fire = tick
	# spawn projectile
	var projectile = projectile_scene.instantiate()
	add_child(projectile, true)

	# aim projectile towards crosshair
	if user:
		var aim_pos = user.get_aim().position
		if global_position.distance_squared_to(aim_pos) > 64:
			projectile.look_at(aim_pos)
