extends Node3D


#func _ready():
	# multiplayer tick
#	if is_multiplayer_authority():
#		print("we mp auth")
#		Game.mp_tick.connect("timeout", mp_tick)


func activate(activator):
	if "held_item" not in activator:
		return

	if activator.held_item == self:
		activator.held_item = null
		self.collision_layer = 1
	else:
		activator.held_item = self
		self.collision_layer = 2


#func mp_tick():
#	mp_update_pos.rpc(global_position, global_rotation, self.linear_velocity, self.angular_velocity)


#@rpc
#func mp_update_pos(pos, rot, vel, ang_vel):
#	global_position = pos
#	global_rotation = rot
#	self.linear_velocity = vel
#	self.angular_velocity = ang_vel
