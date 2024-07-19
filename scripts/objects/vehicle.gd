extends KinematicBody

var user:Pawn = null
var desired_move: = Vector2()


func _physics_process(delta):
	if !user: desired_move = Vector2.ZERO
	apply_kinematics(delta, desired_move)

	if user:
		user.position = position + Vector3.UP
		user.move_and_collide(Vector3.DOWN)


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


func exit() -> void:
	if !user: return
	user.vehicle = null
	user = null


func _on_mp_sync_frame() -> void:
	if is_multiplayer_authority():
		mp_send_position.rpc(position, rotation, velocity)

@rpc("unreliable_ordered")
func mp_send_position(pos:Vector3, ang:Vector3, vel:Vector3) -> void:
	position = pos
	rotation = ang
	velocity = vel
