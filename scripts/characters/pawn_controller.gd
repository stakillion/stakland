class_name PawnController extends Node

var rotation: = Vector3.ZERO
var movement: = Vector2.ZERO
var action: = {
	jump = false,
	crouch = false,
	primary = false,
	interact = false,
	next_item = false,
	prev_item = false,
	drop_item = false,
}
var last_action: = action.duplicate()


func command(pawn:Pawn) -> Vector3:
	# jumping, crouching
	if action.jump && !last_action.jump:
		pawn.jump()
	elif action.jump:
		pawn.jump(false)
	if action.crouch && !pawn.crouching:
		pawn.crouch(true)
	elif !action.crouch && pawn.crouching:
		pawn.crouch(false)
	# interaction
	if action.primary:
		pawn.primary()
	if action.interact && !last_action.interact:
		pawn.interact()
	# inventory management
	if action.next_item && !last_action.next_item:
		pawn.item_next()
	if action.prev_item && !last_action.prev_item:
		pawn.item_prev()
	if action.drop_item && !last_action.drop_item:
		pawn.item_drop()

	last_action.merge(action, true)
	return Vector3(movement.y, 0.0, movement.x).rotated(Vector3.UP, rotation.y)
