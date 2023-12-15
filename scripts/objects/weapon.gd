extends Item

@export var projectile_scene = preload("res://scenes/objects/rocket.tscn")


func action():
	var tick = Time.get_ticks_msec()
	if last_use + cooldown > tick:
		return
	last_use = tick

	if is_multiplayer_authority():
		var fire_pos = global_position
		var fire_ang = global_rotation
		if user:
			var aim_pos = user.get_aim().position
			if global_position.distance_squared_to(aim_pos) > 64:
				fire_ang = global_transform.looking_at(aim_pos).basis.get_euler()

		fire.rpc(fire_pos, fire_ang)


@rpc("call_local", "reliable")
func fire(pos, ang):
	# spawn projectile
	var projectile = projectile_scene.instantiate()
	projectile.weapon = self
	projectile.position = pos
	projectile.rotation = ang
	owner.add_child(projectile, true)
