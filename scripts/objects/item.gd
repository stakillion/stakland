class_name Item
extends RigidBody3D

# who is using this item?
var user:Pawn
# does it go into the inventory?
@export var use_inventory:bool
var held_angle:Vector3

# spawn position
@onready var spawn_pos = global_position
@onready var spawn_ang = global_rotation


func _ready():
	# multiplayer tick
	Game.mp_tick.connect("timeout", mp_tick)


func _physics_process(delta):
	# update position of held item
	if !use_inventory && user:
		update_position(delta)


func activate(activator:Pawn):
	if user && user != activator:
		return

	if activator == user:
		drop()
	else:
		pick_up(activator)


func pick_up(new_user:Pawn):
	if !use_inventory:
		held_angle = global_rotation - new_user.head.global_rotation
		collision_layer = 2
		new_user.held_item = self
	else:
		reparent(new_user.inventory)
		position = Vector3()
		rotation = Vector3()
		collision_layer = 0
		freeze = true
		new_user.active_item = self

	user = new_user


func drop():
	if user.held_item == self:
		user.held_item = null
	elif user.active_item == self:
		user.active_item = null
		reparent(Game.world)
		freeze = false
		update_position(0.0)

	angular_velocity = Vector3()
	collision_layer = 1

	user = null


func update_position(delta):
	var new_pos = user.get_aim_target(2.0, [user, self]).position
	linear_velocity = (new_pos - global_position) * (4096 * delta)

	# set rotation relative to where we're looking
	# TODO - figure out a better way to do this
	global_rotation = user.head.global_rotation + held_angle


func mp_tick():
	if is_multiplayer_authority():
		mp_update_pos.rpc(global_position, global_rotation, self.linear_velocity, self.angular_velocity)


@rpc
func mp_update_pos(pos, ang, vel, ang_vel):
	global_position = pos
	global_rotation = ang
	self.linear_velocity = vel
	self.angular_velocity = ang_vel
