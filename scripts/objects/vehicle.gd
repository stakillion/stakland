extends KinematicBody

@export var seat:Node3D
@export var jump_power: = 7.0

var user:Pawn = null
 

func _physics_process(delta):
	if user && "desired_move" in user:
		var dir: = Vector3(user.desired_move.y, 0.0, user.desired_move.x)
		apply_kinematics(delta, dir)
		user.position = seat.global_position
		rotation.y = user.rotation.y
	else:
		apply_kinematics(delta)


func activate(pawn:Pawn) -> void:
	# do not allow other users to activate this if someone is already using it
	if user && user != pawn:
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
	if user:
		user.vehicle = null
		user.remove_collision_exception_with(self)
	user = null


func jump() -> void:
	if !in_air:
		velocity.y = jump_power
	# no longer on floor
	in_air = true


func _on_mp_sync_frame() -> void:
	if is_multiplayer_authority():
		mp_send_position.rpc(position, rotation, velocity)

@rpc("unreliable_ordered")
func mp_send_position(pos:Vector3, ang:Vector3, vel:Vector3) -> void:
	position = pos
	rotation = ang
	velocity = vel
