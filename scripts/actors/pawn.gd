class_name Pawn extends PhysicsBody3D

var is_player:
	get: return Player.pawn == self

# -- physics --
# higher air acceleration enables mid-air turns and slope surfing
@export var physics = {
	ground_speed = 6.5,
	ground_accel = 10.0,
	ground_friction = 5.0,
	air_speed = 1.0,
	air_accel = 20.0,
	air_friction = 0.0,
	jump_power = 7.0,
	jump_midair = 1,
	gravity = 20.0,
	max_speed = 40.0
}

var desired_move = Vector2()
var velocity = Vector3()
var on_ground = false
var jump_midair_count = 0

var health = 200
var alive:
	get: return health > 0

@onready var head = find_child("Head")
@onready var inventory = find_child("Inventory")
@onready var collision = find_children("*", "CollisionShape3D").front()

var active_item:Item
var grab_object:RigidBody3D
var grab_angle:Vector3


func _ready():
	if !head: head = self
	if !inventory:
		inventory = Node3D.new()
		inventory.name = "Inventory"
		head.add_child(inventory)
		inventory.global_position = head.global_position
	# make sure we are properly holding any items found in inventory
	for item in inventory.get_children():
		item.pick_up(self)
	# aim towards the center of our view
	inventory.look_at(head.position - head.basis.z * 12)

	# enable proximity fade if we are the player
	if is_player: for mesh in find_children("*", "MeshInstance3D"):
		mesh.set_instance_shader_parameter("fade_enabled", true)
 

func _process(_delta):
	if alive && "camera" in owner:
		# look where the camera is looking
		rotation.y = owner.camera.rotation.y
		head.rotation.x = owner.camera.rotation.x
		collision.global_rotation = Vector3.ZERO


func _physics_process(delta):
	if !alive: desired_move = Vector2.ZERO
	# accelerate velocity based on desired movement and ground state
	var dir = Vector3(desired_move.y, 0.0, desired_move.x)
	var speed = desired_move.length()
	if on_ground:
		# apply friction
		apply_friction(physics.ground_friction, delta)
		# apply acceleration
		ground_accelerate(dir, speed, delta)
		# go up stairs
		try_stair_step(delta)
	else:
		# apply gravity
		velocity.y -= physics.gravity * delta
		# apply friction
		apply_friction(physics.air_friction, delta)
		# apply acceleration
		air_accelerate(dir, speed, delta)

	if physics.max_speed > 0:
		# enforce speed limit
		apply_max_speed(physics.max_speed)

	# do move based on our new velocity
	move(delta)

	# update position of object we're grabbing
	if grab_object:
		update_grab_pos(grab_object, delta)

	# update shader fade position
	if is_player: for mesh in find_children("*", "MeshInstance3D"):
		mesh.set_instance_shader_parameter("fade_position", global_position)


func move(delta, max_slides = 6):
	on_ground = false
	var motion = (velocity / max_slides) * delta
	for slides in max_slides:
		# move and check for collision
		var collide = move_and_collide(motion, false, 0.001, true)
		if !collide:
			continue
		# if we hit something and it's not too steep then we consider it ground
		if collide.get_angle() < PI/4:
			on_ground = true
			jump_midair_count = 0
		# slide along the normal vector of the colliding body
		var collision_norm = collide.get_normal()
		motion = motion.slide(collision_norm)
		velocity = velocity.slide(collision_norm)


func ground_accelerate(dir, speed, delta):
	# get current speed towards desired direction
	var current_speed = velocity.length()
	# calculate speed we need to make up to reach our desired speed
	var new_speed = min(physics.ground_speed * speed, physics.ground_speed)
	var add_speed = new_speed - current_speed
	if add_speed > 0:
		# calculate acceleration and cap it to our desired speed
		var accel = min(physics.ground_accel * new_speed * delta, add_speed)
		# apply acceleration towards our desired direction
		velocity += accel * dir


func air_accelerate(dir, speed, delta):
	# get current speed towards desired direction
	var current_speed = velocity.dot(dir)
	# calcuate speed we need to make up to reach our desired speed
	var new_speed = min(physics.air_speed * speed, physics.air_speed)
	var add_speed = new_speed - current_speed
	if add_speed > 0:
		# calculate acceleration and cap it to our desired speed
		var accel = min(physics.air_accel * new_speed * delta, add_speed)
		# apply acceleration towards our desired direction
		velocity += accel * dir


func apply_friction(friction, delta):
	var current_speed = velocity.length()
	if current_speed == 0.0:
		return
	var drop = max(current_speed, 1.0) * friction * delta
	velocity.x *= max(current_speed - drop, 0.0) / current_speed
	velocity.z *= max(current_speed - drop, 0.0) / current_speed


func apply_max_speed(limit):
	var h_velocity = Vector3(velocity.x, 0.0, velocity.z)
	var current_speed = h_velocity.length()
	if current_speed > limit:
		var drop = current_speed - limit
		velocity.x *= max(current_speed - drop, 0.0) / current_speed
		velocity.z *= max(current_speed - drop, 0.0) / current_speed


func try_stair_step(delta, step_size = 1.0/3):
	var step_vec = Vector3(0.0, step_size, 0.0)
	var up_cast = cast_motion(position, step_vec)
	if up_cast:
		step_vec *= up_cast.fraction[0]
	var step_up = position + step_vec
	var desired_pos = step_up + velocity * delta
	var down_cast = cast_motion(desired_pos, -step_vec)
	if !down_cast:
		return
	var step = desired_pos - step_vec * down_cast.fraction[0]
	if down_cast.normal == Vector3.UP:
		position.y = step.y


func get_aim(distance = 32768.0, exclude = []):
	var ray_start = head.global_position
	var ray_end = head.global_position - head.global_transform.basis.z * distance
	var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	query.exclude = [self] + find_children("*") + exclude
	# check for collision
	var collide = get_world_3d().direct_space_state.intersect_ray(query)
	if !collide:
		# if we missed, set position to end position anyway
		collide.position = ray_end
		collide.collider = null

	return collide


func jump(midair = true):
	if on_ground:
		on_ground = false # no longer on ground
		velocity.y = physics.jump_power
		jump_midair_count = 0
	elif midair && jump_midair_count < physics.jump_midair:
		velocity.y = physics.jump_power
		jump_midair_count += 1


func interact():
	var target
	if active_item && active_item.get_parent() != inventory:
		target = active_item
	else:
		target = get_aim(2.0).collider
	if target:
		if target.has_method("activate"):
			target.activate(self)
		elif target is RigidBody3D:
			toggle_grab(target)


func action():
	if grab_object:
		toggle_grab(grab_object)
	elif active_item:
		if active_item.has_method("action"):
			active_item.action()
		elif active_item.has_method("activate"):
			active_item.activate(self)
	else:
		interact()


func item_next():
	var next_item = false
	# loop through inventory items
	for item in inventory.get_children():
		if item == active_item:
			next_item = true
		elif next_item:
			set_active_item(item)
			return


func item_prev():
	var next_item = false
	# loop through inventory items in reverse
	var items = inventory.get_children()
	for i in range(items.size() - 1, -1, -1):
		if items[i] == active_item:
			next_item = true
		elif next_item:
			set_active_item(items[i])
			return


func item_drop():
	if !active_item || active_item.user != self:
		set_active_item(null)
	else:
		active_item.drop()


func set_active_item(item:Item):
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


func toggle_grab(object:RigidBody3D):
	if object != grab_object:
		# start grab
		object.add_collision_exception_with(self)
		grab_angle = object.global_rotation - head.global_rotation
		grab_object = object
	else:
		# stop grab
		object.remove_collision_exception_with(self)
		object.angular_velocity = Vector3()
		grab_object = null

	if active_item:
		active_item.last_use = Time.get_ticks_msec()


func update_grab_pos(object:RigidBody3D, delta):
	var new_pos = get_aim(2.0, [self, object]).position
	object.linear_velocity = (new_pos - object.global_position) * (4096 * delta)

	# set rotation relative to where we're looking
	# TODO - figure out a better way to do this
	object.global_rotation = head.global_rotation + grab_angle


func cast_motion(start:Vector3, motion:Vector3):
	var query = PhysicsShapeQueryParameters3D.new()
	query.transform.origin = start
	query.motion = motion
	query.shape = collision.shape
	query.exclude = [self] + find_children("*")
	var fraction = get_world_3d().direct_space_state.cast_motion(query)

	query.transform.origin = start + motion * fraction[1]
	var dict = get_world_3d().direct_space_state.get_rest_info(query)
	if dict.is_empty():
		return null
	dict.fraction = fraction
	return dict


@rpc("call_local", "reliable")
func set_health(value):
	value = max(int(value), 0)
	if health == value:
		return
	if value <= 0: # dead
		# drop items
		while inventory.get_children():
			item_drop()

		head.rotation = Vector3()
		rotation += Vector3(0.0, 0.0, deg_to_rad(90.0))

	health = value


func _on_mp_sync_frame():
	if is_multiplayer_authority():
		mp_send_position.rpc(position, velocity)

@rpc("unreliable_ordered")
func mp_send_position(pos, vel):
	position = pos
	velocity = vel
