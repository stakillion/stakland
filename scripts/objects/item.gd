extends Node3D


func activate(activator):

	if activator.held_item == self:
		activator.held_item = null
		self.collision_layer = 1
	else:
		activator.held_item = self
		self.collision_layer = 2
