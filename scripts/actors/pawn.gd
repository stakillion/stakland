class_name Pawn extends KinematicBody

var is_player:
	get: return (is_instance_valid(Player) && Player.pawn == self)

@export var max_health: = 200
@export var jump_power: = 7.0
@export var jump_midair: = 1

@export var collider:CollisionShape3D
@export var crouched_collider:CollisionShape3D
var desired_move: = Vector2()
var crouching: = false
var jump_midair_count: = 0
var vehicle:Node3D = null

var health: = max_health
var alive:
	get: return health > 0

@export var head:Node3D
var head_position: = Vector3()
var head_offset: = Vector3()

@export var inventory:Node3D
var active_item:Item
var next_use_time:int
var grab_object:RigidBody3D
var grab_angle:Vector3


func _ready() -> void:
	assert(is_instance_valid(head), "Pawn requires a head node.")
	assert(is_instance_valid(inventory), "Pawn requires an inventory node.")

	head_position = head.position
	# make sure we are properly holding any items found in inventory
	for item in inventory.get_children():
		item.pick_up(self)
	# aim towards the center of our view
	inventory.look_at(head_position - head.basis.z * 12)
	# enable proximity fade if we are the player
	if is_player: for mesh in find_children("*", "MeshInstance3D"):
		mesh.set_instance_shader_parameter("fade_enabled", true)


func _process(_delta) -> void:
	if !alive:
		return
	# have the pawn look where the camera is looking
	if owner.input.alt_look:
		var angle:Vector3 = owner.camera.global_transform.looking_at(owner.aim_position).basis.get_euler()
		set_angle(angle)
	else:
		set_angle(owner.camera.rotation)


func _physics_process(delta) -> void:
	if !alive:
		desired_move = Vector2.ZERO
	if !is_instance_valid(vehicle):
		var dir: = Vector3(desired_move.y, 0.0, desired_move.x)
		if in_water:
			dir = dir.rotated(head.global_basis.x, head.rotation.x)
		if crouching:
			dir /= 2.5
		apply_kinematics(delta, dir)
	if on_ground:
		jump_midair_count = 0
	# smooth head movement for stairs/crouching/etc.
	head_offset = lerp(head_offset, Vector3.ZERO, 32 * delta)
	head.position = head_position + head_offset
	# update position of object we're grabbing
	if is_instance_valid(grab_object):
		update_grab_pos(grab_object, delta)
	# update shader fade position
	if is_player: for mesh in find_children("*", "MeshInstance3D"):
		mesh.set_instance_shader_parameter("fade_position", position)


func get_aim(distance: = 32768.0, exclude: = []) -> Dictionary:
	var ray_start: = head.global_position
	var ray_end: = head.global_position - head.global_transform.basis.z * distance
	var query: = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	query.exclude = [self] + find_children("*") + exclude
	# check for collision
	var collision: = get_world_3d().direct_space_state.intersect_ray(query)
	if !collision:
		# if we missed, set position to end position anyway
		collision.position = ray_end
		collision.collider = null

	return collision


func jump(midair: = true) -> void:
	if is_instance_valid(vehicle):
		if "jump" in vehicle: vehicle.jump()
		return
	if on_ground:
		velocity.y = jump_power
		jump_midair_count = 0
	elif !in_water && midair && jump_midair_count < jump_midair:
		velocity.y = jump_power
		jump_midair_count += 1
	# no longer on ground
	on_ground = false


func crouch(state:bool) -> void:
	if is_instance_valid(collider) && is_instance_valid(crouched_collider):
		collider.disabled = state
		crouched_collider.disabled = !state
		if test_move(transform, Vector3.ZERO):
			collider.disabled = !state
			crouched_collider.disabled = state
			return
	var motion: = Vector3.ZERO
	if state == true && !crouching:
		crouching = true
		motion.y -= .5
	elif crouching:
		crouching = false
		motion.y += .5
	head_position += motion
	head_offset -= motion


func interact() -> void:
	var tick: = Time.get_ticks_msec()
	if next_use_time > tick:
		return

	var target:PhysicsBody3D
	if is_instance_valid(vehicle):
		target = vehicle
	elif is_instance_valid(active_item) && active_item.get_parent() != inventory:
		target = active_item
	else:
		target = get_aim(2).collider as PhysicsBody3D
	if is_instance_valid(target):
		if target.has_method("activate"):
			target.activate(self)
		elif target is RigidBody3D:
			toggle_grab(target)
		next_use_time = tick + 200


func action() -> void:
	var tick: = Time.get_ticks_msec()
	if next_use_time > tick:
		return

	if is_instance_valid(grab_object):
		toggle_grab(grab_object)
		next_use_time = tick + 200
	elif is_instance_valid(active_item):
		if active_item.has_method("action"):
			active_item.action()
		elif active_item.has_method("activate"):
			active_item.activate(self)
		next_use_time = tick + active_item.cooldown
	else:
		interact()


func item_next() -> void:
	var next_item: = false
	# loop through inventory items
	for item in inventory.get_children():
		if item == active_item:
			next_item = true
		elif next_item:
			set_active_item(item)
			return


func item_prev() -> void:
	var next_item: = false
	# loop through inventory items in reverse
	var items: = inventory.get_children()
	for i in range(items.size() - 1, -1, -1):
		if items[i] == active_item:
			next_item = true
		elif next_item:
			set_active_item(items[i])
			return


func item_drop() -> void:
	if !active_item || active_item.user != self:
		set_active_item(null)
	else:
		active_item.drop()


func set_active_item(item:Item) -> void:
	for inv_item in inventory.get_children():
		if item == null:
			item = inv_item
		elif item != inv_item:
			inv_item.process_mode = Node.PROCESS_MODE_DISABLED
			inv_item.visible = false
	if is_instance_valid(item):
		item.process_mode = Node.PROCESS_MODE_INHERIT
		item.visible = true

	active_item = item


func toggle_grab(object:RigidBody3D) -> void:
	if object != grab_object:
		# start grab
		object.add_collision_exception_with(self)
		grab_angle = Basis(head.global_basis.inverse() * object.basis).get_euler()
		grab_object = object
	else:
		# stop grab
		object.remove_collision_exception_with(self)
		object.angular_velocity = Vector3.ZERO
		grab_object = null

	if is_instance_valid(active_item):
		next_use_time = Time.get_ticks_msec() + active_item.cooldown


func update_grab_pos(object:RigidBody3D, delta:float) -> void:
	var new_pos:Vector3 = get_aim(1.90, [object]).position
	object.linear_velocity = (new_pos - object.global_position) * (4096 * delta)
	# set rotation relative to where we're looking
	object.global_rotation = Basis(head.global_basis * Basis.from_euler(grab_angle)).get_euler()
	object.move_and_collide(Vector3.ZERO)


func set_origin(pos:Vector3) -> void:
	position = pos + Vector3.UP
	move_and_collide(Vector3.DOWN)


func set_angle(ang:Vector3) -> void:
	rotation = Vector3(0.0, ang.y, 0.0)
	head.rotation = Vector3(ang.x, 0.0, 0.0)


@rpc("call_local", "reliable")
func set_health(value:int) -> void:
	value = max(value, 0)
	if health == value:
		return
	if value <= 0: # dead
		# drop items
		while inventory.get_children():
			item_drop()
		head.rotation = Vector3.ZERO
		rotation.z += deg_to_rad(90)

	health = value


func _on_mp_sync_frame() -> void:
	if is_multiplayer_authority():
		mp_send_position.rpc(position, velocity)

@rpc("unreliable_ordered")
func mp_send_position(pos:Vector3, vel:Vector3) -> void:
	position = pos
	velocity = vel
