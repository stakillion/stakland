class_name Pawn
extends PhysicsBody3D

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
	gravity = 20.0
}

var desired_move = Vector2()
var velocity = Vector3()
var on_ground = false
var jump_midair_count = 0

var health = 200
var alive:
	get: return health > 0

# head is used to track where we are looking
@onready var head = find_child("Head")
# inventory is used to store items
@onready var inventory = find_child("Inventory")

var active_item:RigidBody3D
var grab_angle:Vector3


func _ready():
	owner = get_parent()

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

	# multiplayer sync
	Game.mp_sync.connect("timeout", mp_sync)


func _process(_delta):
	if !alive: return
	if "camera" in owner:
		# look where the camera is looking
		head.rotation.x = owner.camera.rotation.x
		head.rotation.y = owner.camera.rotation.y


func _physics_process(delta):
	if !alive: desired_move = Vector3()
	# accelerate velocity based on desired movement and ground state
	var dir = Vector3(desired_move.y, 0.0, desired_move.x)
	var speed = desired_move.length()
	if on_ground:
		# apply friction
		apply_friction(physics.ground_friction, delta)
		# apply acceleration
		ground_accelerate(dir, speed, delta)
	else:
		# apply gravity
		velocity.y -= physics.gravity * delta
		# apply friction
		apply_friction(physics.air_friction, delta)
		# apply acceleration
		air_accelerate(dir, speed, delta)

	# do move based on our new velocity
	move(delta)

	# update position of object we're grabbing
	if active_item && not active_item is Item:
		update_grab_pos(active_item, delta)


func move(delta, max_slides = 6):
	on_ground = false
	var collisions = []
	var motion = velocity / max_slides * delta
	while max_slides:
		max_slides -= 1
		# move and check for collision
		var collision = move_and_collide(motion, false, 0.001, true)
		if !collision:
			continue
		collisions.append(collision)
		# if we hit something and it's not too steep then we consider it ground
		if rad_to_deg(collision.get_angle()) < 45:
			on_ground = true
			jump_midair_count = 0
		# slide along the normal vector of the colliding body
		var collision_norm = collision.get_normal()
		motion = motion.slide(collision_norm)
		velocity = velocity.slide(collision_norm)

	return collisions


func ground_accelerate(dir, speed, delta):
	# get current speed towards desired direction
	var current_speed = velocity.length()
	# calculate speed we need to make up to reach our desired speed
	var new_speed = min(physics.ground_speed * speed, physics.ground_speed)
	var add_speed = new_speed - current_speed
	if add_speed > 0:
		# calculate acceleration and cap it to our desired speed
		var accel = physics.ground_accel * new_speed * delta
		if accel > add_speed:
			accel = add_speed
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
		var accel = physics.air_accel * new_speed * delta
		if accel > add_speed:
			accel = add_speed
		# apply acceleration towards our desired direction
		velocity += accel * dir


func apply_friction(friction, delta):
	var current_speed = velocity.length()
	if current_speed == 0.0:
		return
	var drop = max(current_speed, 1.0) * friction * delta
	velocity.x *= max(current_speed - drop, 0.0) / current_speed
	velocity.z *= max(current_speed - drop, 0.0) / current_speed


func get_aim(distance = 32768.0, exclude = [self]):
	var ray_start = head.global_position
	var ray_end = head.global_position - head.global_transform.basis.z * distance
	var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	query.exclude = exclude
	# check for collision
	var collision = get_world_3d().direct_space_state.intersect_ray(query)
	if !collision:
		# if we missed, set position to end position anyway
		collision.position = ray_end
		collision.collider = null

	return collision


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
			grab_object(target)


func action():
	if active_item:
		if active_item.has_method("action"):
			active_item.action()
		elif active_item.has_method("activate"):
			active_item.activate(self)
		elif active_item is RigidBody3D:
			grab_object(active_item)
	else:
		interact()


func item_next():
	var next_item = false
	for item in inventory.get_children():
		if item == active_item:
			next_item = true
		elif next_item:
			set_active_item(item)
			return


func item_prev():
	var last_item = null
	for item in inventory.get_children():
		if item == active_item && last_item:
			set_active_item(last_item)
			return
		else:
			last_item = item


func item_drop():
	if !active_item || active_item.user != self:
		set_active_item(null)
	else:
		active_item.drop()


func set_active_item(item:RigidBody3D):
	for inv_item in inventory.get_children():
		if item == null:
			item = inv_item
			item.process_mode = Node.PROCESS_MODE_INHERIT
			item.visible = true
		elif item != inv_item && item.get_parent() == inventory:
			inv_item.process_mode = Node.PROCESS_MODE_DISABLED
			inv_item.visible = false

	active_item = item


func grab_object(object:RigidBody3D):
	if object != active_item:
		# start grab
		object.add_collision_exception_with(self)
		set_active_item(object)
		grab_angle = object.global_rotation - head.global_rotation
	else:
		# stop grab
		object.remove_collision_exception_with(self)
		set_active_item(null)
		object.angular_velocity = Vector3()


func update_grab_pos(object:RigidBody3D, delta):
	var new_pos = get_aim(2.0, [self, object]).position
	object.linear_velocity = (new_pos - object.global_position) * (4096 * delta)

	# set rotation relative to where we're looking
	# TODO - figure out a better way to do this
	object.global_rotation = head.global_rotation + grab_angle


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

func mp_sync():
	if is_multiplayer_authority():
		mp_send_position.rpc(position, velocity)


@rpc("unreliable_ordered")
func mp_send_position(pos, vel):
	position = pos
	velocity = vel
