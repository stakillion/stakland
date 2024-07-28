extends KinematicBody

@export var turn_speed: = 90.0
@export var jump_power: = 7.0
@export var seat:Node3D

var user:Pawn = null
 

func _physics_process(delta):
	if is_instance_valid(user):
		var dir: = Vector3(user.desired_move.y, 0.0, user.desired_move.x)
		if on_ground:
			vehicle_accelerate(dir, run_speed, run_accel, delta)
		if !dir.is_zero_approx():
			var angle_diff: = angle_difference(rotation.y, atan2(dir.x, dir.z))
			rotation.y += angle_diff * deg_to_rad(turn_speed) * delta

		user.position = seat.global_position
		user.move_and_collide(Vector3.ZERO)
		if user.position.distance_to(seat.global_position) > 0.1:
			exit()

	apply_kinematics(delta)


func vehicle_accelerate(dir:Vector3, speed:float, accel:float, delta:float) -> void:
	# get current speed towards desired direction
	var current_speed: = velocity.dot(basis.z)
	speed *= dir.dot(basis.z)
	# calculate speed we need to make up to reach our desired speed
	var add_speed: = speed - current_speed
	if add_speed > 0:
		# cap acceleration to our desired speed and apply towards our desired direction
		velocity += minf(accel * speed * delta, add_speed) * basis.z


func activate(pawn:Pawn) -> void:
	# do not allow other users to activate this if someone is already using it
	if is_instance_valid(user) && user != pawn:
		return

	if pawn == user:
		exit()
	else:
		enter(pawn)


func enter(pawn:Pawn) -> void:
	user = pawn
	pawn.vehicle = self
	pawn.add_collision_exception_with(self)


func exit() -> void:
	if is_instance_valid(user):
		user.vehicle = null
		user.remove_collision_exception_with(self)
	user = null


func jump() -> void:
	if on_ground:
		velocity.y = jump_power
	# no longer on ground
	on_ground = false


func _on_mp_sync_frame() -> void:
	if is_multiplayer_authority():
		mp_send_position.rpc(position, rotation, velocity)

@rpc("unreliable_ordered")
func mp_send_position(pos:Vector3, ang:Vector3, vel:Vector3) -> void:
	position = pos
	rotation = ang
	velocity = vel
