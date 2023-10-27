extends Node3D


@rpc("any_peer", "call_local", "reliable", 0)
func activate(activator):
	if "held_item" not in activator:
		return

	if activator.held_item == self:
		activator.held_item = null
		self.collision_layer = 1
	else:
		activator.held_item = self
		self.collision_layer = 2
