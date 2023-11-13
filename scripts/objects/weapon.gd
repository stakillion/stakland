extends Item


@export var projectile_scene = preload("res://scenes/objects/rocket.tscn")
@export var cooldown = 500
var last_fire:int


@rpc("any_peer", "call_local", "reliable")
func action():
	var tick = Time.get_ticks_msec()
	if last_fire + cooldown < tick:
		# spawn projectile
		last_fire = tick
		var projectile = projectile_scene.instantiate()
		add_child(projectile)

		# aim projectile towardsd crosshair
		var aim_pos = user.get_aim().position
		if global_position.distance_squared_to(aim_pos) > 32.0:
			projectile.look_at(aim_pos)
