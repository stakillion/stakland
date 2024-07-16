class_name Pawn extends PhysicsBody3D

# -- physics --
# higher air acceleration enables mid-air turns and slope surfing
@export var physics: = {
	run_speed = 8.0,
	run_accel = 10.0,
	run_friction = 8.0,
	air_speed = 8.0,
	air_accel = 1.0,
	air_friction = 0.0,
	jump_power = 7.0,
	jump_midair = 1,
	gravity = 20.0,
	max_speed = 100.0
}

var desired_move: = Vector2()
var velocity: = Vector3()
var in_air: = false
var on_ledge: = false
var crouching: = false
var jump_midair_count: = 0

@export var health: = 200
var alive:
	get: return health > 0

@onready var head:Node3D = find_child("Head")
@onready var inventory:Node3D = find_child("Inventory")
var head_position: = Vector3()
var head_offset: = Vector3()

@onready var collider:CollisionShape3D = find_children("*", "CollisionShape3D")[0]

var active_item:Item
var grab_object:RigidBody3D
var grab_angle:Vector3


func _ready() -> void:
	if !head: head = self
	head_position = head.position
	if !inventory:
		inventory = Node3D.new()
		inventory.name = "Inventory"
		head.add_child(inventory)
		inventory.position = Vector3(0.42, -0.175, -0.25)
	# make sure we are properly holding any items found in inventory
	for item in inventory.get_children():
		item.pick_up(self)
	# aim towards the center of our view
	inventory.look_at(head_position - head.basis.z * 12)

	# enable proximity fade if we are the player
	if Player.pawn == self: for mesh in find_children("*", "MeshInstance3D"):
		mesh.set_instance_shader_parameter("fade_enabled", true)


func _physics_process(delta:float) -> void:
	if !alive: desired_move = Vector2.ZERO
	# accelerate velocity based on desired movement and movement state
	var dir: = Vector3(desired_move.y, 0.0, desired_move.x)
	var speed: = desired_move.length()

	if !in_air || on_ledge:
		if crouching: speed /= 2
		# apply friction
		apply_friction(physics.run_friction, delta)
		# apply acceleration
		accelerate(dir, physics.run_speed * speed, delta)
		# step up stairs/ledges
		try_step_up(delta)
	else:
		# apply gravity
		velocity.y -= physics.gravity * delta
		# apply friction
		apply_friction(physics.air_friction, delta)
		# apply acceleration
		air_accelerate(dir, physics.air_speed * speed, delta)

	if physics.max_speed > 0:
		# enforce speed limit
		apply_max_speed(physics.max_speed)

	# do move based on our new velocity
	move(delta)

	# smooth head movement for stairs/crouching/etc.
	head_offset = lerp(head_offset, Vector3.ZERO, 32 * delta)
	head.position = head_position + head_offset

	# update position of object we're grabbing
	if grab_object:
		update_grab_pos(grab_object, delta)

	# update shader fade position
	if Player.pawn == self: for mesh in find_children("*", "MeshInstance3D"):
		mesh.set_instance_shader_parameter("fade_position", position)


func move(delta:float, max_slides: = 6) -> void:
	in_air = true
	var motion: = (velocity / max_slides) * delta
	for slide in max_slides:
		# move and check for collision
		var collision: = move_and_collide(motion, false, 0.001, true)
		if !collision:
			continue
		# if we hit something and it's not too steep then we consider it ground
		if collision.get_angle() < PI/4:
			in_air = false
			jump_midair_count = 0
		# slide along the normal vector of the colliding body
		var collision_norm: = collision.get_normal()
		motion = motion.slide(collision_norm)
		if !on_ledge:
			velocity = velocity.slide(collision_norm)


func accelerate(dir:Vector3, speed:float, delta:float) -> void:
	# get current speed towards desired direction
	var current_speed: = velocity.length()
	# calculate speed we need to make up to reach our desired speed
	var add_speed: = speed - current_speed
	if add_speed > 0:
		# calculate acceleration and cap it to our desired speed
		var accel: = minf(physics.run_accel * speed * delta, add_speed)
		# apply acceleration towards our desired direction
		velocity += accel * dir


func air_accelerate(dir:Vector3, speed:float, delta:float) -> void:
	# get current speed towards desired direction
	var current_speed: = velocity.dot(dir)
	# calcuate speed we need to make up to reach our desired speed
	var add_speed: = speed - current_speed
	if add_speed > 0:
		# calculate acceleration and cap it to our desired speed
		var accel: = minf(physics.air_accel * speed * delta, add_speed)
		# apply acceleration towards our desired direction
		velocity += accel * dir


func apply_friction(friction:float, delta:float) -> void:
	var h_velocity: = Vector3(velocity.x, 0.0, velocity.z)
	var current_speed: = h_velocity.length()
	if current_speed > 0:
		var drop: = maxf(current_speed, 1.0) * friction * delta
		velocity.x *= maxf(current_speed - drop, 0.0) / current_speed
		velocity.z *= maxf(current_speed - drop, 0.0) / current_speed


func apply_max_speed(limit:float) -> void:
	var h_velocity: = Vector3(velocity.x, 0.0, velocity.z)
	var current_speed: = h_velocity.length()
	if current_speed > limit:
		var drop: = current_speed - limit
		velocity.x *= maxf(current_speed - drop, 0.0) / current_speed
		velocity.z *= maxf(current_speed - drop, 0.0) / current_speed


func try_step_up(delta:float, max_height: = 0.5) -> void:
	on_ledge = false
	var forward: = Vector3(velocity.x, 0.0, velocity.z) * delta
	var motion: = Vector3(0.0, max_height, 0.0)
	# trace upward to the max step height and limit our motion to the ceiling
	var collision: = KinematicCollision3D.new()
	test_move(transform, motion, collision)
	motion -= collision.get_remainder()
	# trace downward to the height of any ledge in front of us
	var new_transform: = transform.translated(motion + forward)
	test_move(new_transform, -motion, collision)
	motion = -collision.get_remainder()
	if motion.is_zero_approx():
		# didn't find a ledge
		return
	# compare angle of collision with the next frame to determine if we've truly found a ledge
	var ledge_angle: = collision.get_angle()
	new_transform = transform.translated(motion + forward)
	if !test_move(new_transform, forward, collision) || ledge_angle > collision.get_angle():
		on_ledge = true
		# move up to the height of the ledge
		position += motion
		# snap to the floor
		if velocity.y > 0:
			velocity.y = 0
		# smooth head movement
		head_offset -= motion


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
	if !in_air:
		velocity.y = physics.jump_power
		jump_midair_count = 0
	elif midair && jump_midair_count < physics.jump_midair:
		velocity.y = physics.jump_power
		jump_midair_count += 1
	# no longer on floor
	in_air = true


func crouch(state:bool) -> void:
	var motion: = Vector3.ZERO
	if state == true:
		crouching = true
		motion.y -= .5
	else:
		crouching = false
		motion.y += .5
	head_position += motion
	head_offset -= motion


func interact() -> void:
	var target:PhysicsBody3D
	if active_item && active_item.get_parent() != inventory:
		target = active_item
	else:
		target = get_aim(2.0).collider as PhysicsBody3D
	if target:
		if target.has_method("activate"):
			target.activate(self)
		elif target is RigidBody3D:
			toggle_grab(target)


func action() -> void:
	if grab_object:
		toggle_grab(grab_object)
	elif active_item:
		if active_item.has_method("action"):
			active_item.action()
		elif active_item.has_method("activate"):
			active_item.activate(self)
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
	if item:
		item.last_use = Time.get_ticks_msec()
		item.process_mode = Node.PROCESS_MODE_INHERIT
		item.visible = true

	active_item = item


func toggle_grab(object:RigidBody3D) -> void:
	if object != grab_object:
		# start grab
		object.add_collision_exception_with(self)
		grab_angle = object.global_rotation - head.global_rotation
		grab_object = object
	else:
		# stop grab
		object.remove_collision_exception_with(self)
		object.angular_velocity = Vector3.ZERO
		grab_object = null

	if active_item:
		active_item.last_use = Time.get_ticks_msec()


func update_grab_pos(object:RigidBody3D, delta:float) -> void:
	var new_pos:Vector3 = get_aim(2.0, [self, object]).position
	object.linear_velocity = (new_pos - object.global_position) * (4096 * delta)

	# set rotation relative to where we're looking
	# TODO - figure out a better way to do this
	object.global_rotation = head.global_rotation + grab_angle


func set_origin(pos:Vector3) -> void:
	if "size" in collider.shape:
		pos.y += (collider.shape.size.y / 2) - collider.position.y
	elif "height" in collider.shape:
		pos.y += (collider.shape.height / 2) - collider.position.y
	position = pos


func set_angle(ang:Vector3) -> void:
	rotation = Vector3(0.0, ang.y, 0.0)
	head.rotation = Vector3(ang.x, 0.0, 0.0)
	collider.global_rotation = Vector3.ZERO


@rpc("call_local", "reliable")
func set_health(value:int) -> void:
	value = max(value, 0)
	if health == value:
		return
	if value <= 0: # dead
		# drop items
		while inventory.get_children():
			item_drop()
		head.rotation = Vector3()
		rotation += Vector3(0.0, 0.0, deg_to_rad(90.0))
		if Player.pawn == self:
			Player.cam_activate(null, head.global_position)

	health = value


func _on_mp_sync_frame() -> void:
	if is_multiplayer_authority():
		mp_send_position.rpc(position, velocity)

@rpc("unreliable_ordered")
func mp_send_position(pos:Vector3, vel:Vector3) -> void:
	position = pos
	velocity = vel
