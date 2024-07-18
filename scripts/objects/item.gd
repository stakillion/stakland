class_name Item extends RigidBody3D

@export var cooldown: = 500
@onready var _collision_layer: = collision_layer

var last_use:int
var user:Pawn = null


func _ready() -> void:
	if Player: for mesh in find_children("*", "MeshInstance3D"):
		# create a duplicate mesh with no depth for first-person perspectives
		var no_depth_mesh: = mesh.duplicate() as MeshInstance3D
		var no_depth_mat: = mesh.get_active_material(0).duplicate() as StandardMaterial3D
		no_depth_mat.no_depth_test = true
		no_depth_mesh.set_surface_override_material(0, no_depth_mat)
		no_depth_mesh.name = "NoDepth"
		mesh.add_child(no_depth_mesh)
		no_depth_mesh.position = Vector3.ZERO
		no_depth_mesh.rotation = Vector3.ZERO


func _process(_delta:float) -> void:
	if !Player:
		return
	# true if the local player is holding this in first person
	var use_no_depth:bool = (user && Player.cam_follow_node == user.get_path() && Player.cam_zoom < 0.5)
	for mesh in find_children("*", "MeshInstance3D"):
		var no_depth_mesh: = mesh.find_child("NoDepth") as MeshInstance3D
		if !no_depth_mesh:
			continue
		if use_no_depth:
			no_depth_mesh.visible = true
		else:
			no_depth_mesh.visible = false


func activate(pawn:Pawn) -> void:
	# do not allow other users to activate this if someone is already using it
	if user && user != pawn:
		return

	if pawn == user:
		drop()
	else:
		pick_up(pawn)


func pick_up(pawn:Pawn) -> void:
	# add to pawn's inventory
	get_parent().remove_child(self)
	pawn.inventory.add_child(self, true)
	# set physics and position
	collision_layer = 0
	position = Vector3()
	rotation = Vector3()
	freeze = true
	# set this as the pawn's active item
	user = pawn
	pawn.set_active_item(self)


func drop() -> void:
	if !user: return
	# remove from user's inventory
	get_parent().remove_child(self)
	user.owner.add_child(self, true)
	# set physics and collision
	collision_layer = _collision_layer
	global_position = user.get_aim(2, [self]).position
	angular_velocity = Vector3()
	freeze = false
	# tell the user to stop holding this if they are
	if user.active_item == self:
		user.set_active_item(null)
	user = null


func _on_mp_sync_frame() -> void:
	if is_multiplayer_authority():
		mp_send_position.rpc(position, rotation, linear_velocity, angular_velocity)

@rpc("unreliable_ordered")
func mp_send_position(pos:Vector3, ang:Vector3, vel:Vector3, ang_vel:Vector3) -> void:
	position = pos
	rotation = ang
	linear_velocity = vel
	angular_velocity = ang_vel
