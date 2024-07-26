extends Node


func _process(_delta:float) -> void:
	if Input.is_action_just_pressed("tool_remove"):
		tool_remove()


func tool_remove() -> void:
	if !Player.pawn || Game.menu.visible:
		return
	var target: = Player.pawn.get_aim().collider as CollisionObject3D
	if !target || target.get_collision_layer_value(1):
		return

	remove.rpc(target.get_path())

@rpc("any_peer", "call_local", "reliable")
func remove(target_path:NodePath) -> void:
	var target: = get_node_or_null(target_path)
	if !target:
		return
	if target.get_multiplayer_authority() != multiplayer.get_remote_sender_id():
		return

	if target is Pawn:
		target.owner.remove_pawn()
	else:
		target.queue_free()
