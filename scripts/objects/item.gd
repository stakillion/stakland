class_name Item extends RigidBody3D

@export var cooldown = 500
var last_use:int
var user:Pawn = null

var no_depth_mat = {}


func _ready():
	if Player: for mesh in find_children("*", "MeshInstance3D"):
		no_depth_mat[mesh] = mesh.get_active_material(0).duplicate()
		no_depth_mat[mesh].no_depth_test = true


func _process(_delta):
	# always draw on top if we are holding this item in first-person
	if Player: for mesh in find_children("*", "MeshInstance3D"):
		if user && user.is_player && Player.zoom < 0.5:
			mesh.set_surface_override_material(0, no_depth_mat[mesh])
		else:
			mesh.set_surface_override_material(0, null)


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
	# set physics and collision
	remove_collision_exception_with(user)
	global_position = user.get_aim(2.0, [user, self]).position
	angular_velocity = Vector3()
	freeze = false
	# tell the user to stop holding this if they are
	if user.active_item == self:
		user.set_active_item(null)
	user = null


func _on_mp_sync_frame():
	if is_multiplayer_authority():
		mp_send_position.rpc(position, rotation, linear_velocity, angular_velocity)

@rpc("unreliable_ordered")
func mp_send_position(pos, ang, vel, ang_vel):
	position = pos
	rotation = ang
	linear_velocity = vel
	angular_velocity = ang_vel
