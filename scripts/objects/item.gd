class_name Item
extends RigidBody3D

var user:Pawn = null


func _ready():
	# multiplayer sync
	Game.mp_sync.connect("timeout", mp_sync)


func activate(pawn:Pawn):
	# do not allow other users to activate this if someone is already using it
	if user && user != pawn:
		return

	if pawn == user:
		drop()
	else:
		pick_up(pawn)


func pick_up(pawn:Pawn):
	# add to pawn's inventory
	get_parent().remove_child(self)
	pawn.inventory.add_child(self, true)
	owner = pawn.owner
	# set physics and position
	add_collision_exception_with(pawn)
	position = Vector3()
	rotation = Vector3()
	freeze = true
	# set this as the pawn's active item
	user = pawn
	pawn.set_active_item(self)


func drop():
	if !user: return
	# remove from user's inventory
	get_parent().remove_child(self)
	user.owner.add_child(self, true)
	owner = user.owner
	# set physics and collision
	remove_collision_exception_with(user)
	global_position = user.get_aim(2.0, [user, self]).position
	angular_velocity = Vector3()
	freeze = false
	# tell the user to stop holding this if they are
	if user.active_item == self:
		user.set_active_item(null)
	user = null


func mp_sync():
	if is_multiplayer_authority():
		mp_send_position.rpc(position, rotation, linear_velocity, angular_velocity)

@rpc("unreliable_ordered")
func mp_send_position(pos, ang, vel, ang_vel):
	position = pos
	rotation = ang
	linear_velocity = vel
	angular_velocity = ang_vel
