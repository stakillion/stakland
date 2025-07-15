extends Pawn


@export var turn_speed: = 360.0


func _process(_delta) -> void:
	if !alive:
		return
	# have the pawn look where the camera is looking
	if owner.input.alt_look:
		var angle:Vector3 = owner.camera.global_transform.looking_at(owner.aim_position).basis.get_euler()
		head.rotation.x = angle.x
	else:
		head.rotation.x = owner.camera.rotation.x


func _physics_process(delta) -> void:
	if !alive:
		desired_move = Vector2.ZERO
	if !is_instance_valid(vehicle):
		var dir: = Vector3(desired_move.y, 0.0, desired_move.x)
		if !dir.is_zero_approx():
			var angle_diff: = angle_difference(rotation.y, atan2(-dir.x, -dir.z))
			rotation.y += angle_diff * deg_to_rad(turn_speed) * delta
		if in_water:
			dir = dir.rotated(head.global_basis.x, head.rotation.x)
		if crouching:
			dir /= 2.5
		apply_kinematics(delta, dir)
	if on_ground:
		jump_midair_count = 0
	# smooth head movement for stairs/crouching/etc.
	head_offset = lerp(head_offset, Vector3.ZERO, 32 * delta)
	head.position = head_position + head_offset
	# update position of object we're grabbing
	if is_instance_valid(grab_object):
		update_grab_pos(grab_object, delta)
	# update shader fade position
	if is_player: for mesh in find_children("*", "MeshInstance3D"):
		mesh.set_instance_shader_parameter("fade_position", position)


func apply_kinematics(delta:float, dir: = Vector3.ZERO) -> void:
	if on_ground || on_ledge:
		apply_friction(run_friction, delta)
		accelerate_platformer(dir, run_speed, run_accel, delta, true)
		try_step_up(delta)
	elif in_water:
		if dir.is_zero_approx():
			velocity.y -= (gravity / swim_speed) * delta
		apply_friction(swim_friction, delta)
		accelerate_platformer(dir, swim_speed, swim_accel, delta)
	else:
		velocity.y -= gravity * delta
		apply_friction(air_friction, delta)
		accelerate_platformer(dir, air_speed, air_accel, delta)

	if max_speed > 0:
		apply_max_speed(max_speed)

	move(delta)
