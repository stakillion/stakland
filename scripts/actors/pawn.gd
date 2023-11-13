class_name Pawn
extends PhysicsBody3D

# -- physics --
# higher air acceleration enables mid-air turns and slope surfing
@export var ground_speed = 6.5
@export var ground_accel = 5.5
@export var ground_friction = 5.0
@export var air_speed = 1.0
@export var air_accel = 20.0
@export var air_friction = 0.0
@export var jump_power = 7.0
@export var jump_midair = 1
@export var gravity = 20.0

var desired_move = Vector2()
var velocity = Vector3()
var on_ground = false
var jump_midair_count = 0

# head is used to track where we are looking
@onready var head = find_child("Head")
# inventory is used to store items
@onready var inventory = find_child("Inventory")
var held_item:Item


func _ready():
	if !head: head = self
	if !inventory:
		inventory = Node3D.new()
		inventory.name = "Inventory"
		head.add_child(inventory)
		inventory.global_position = head.global_position
	# aim towards the center of our view
	inventory.look_at(head.global_position - head.global_transform.basis.z * 8)

	Game.mp_tick.connect("timeout", mp_tick)


func _process(_delta):
	if is_multiplayer_authority():
		# look where our controller is looking
		var controller = get_parent()
		if controller.has_method("get_aim"):
			var aim_pos = controller.get_aim().position
			head.look_at(aim_pos)


func _physics_process(delta):
	# accelerate velocity based on desired movement and ground state
	var dir = Vector3(desired_move.y, 0.0, desired_move.x)
	var speed = desired_move.length()
	if on_ground:
		# apply friction
		apply_friction(ground_friction, delta)
		# apply acceleration
		ground_accelerate(dir, speed, delta)
	else:
		# apply gravity
		velocity.y -= gravity * delta
		# apply friction
		apply_friction(air_friction, delta)
		# apply acceleration
		air_accelerate(dir, speed, delta)

	# do move based on our new velocity
	move(delta)


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
	var new_speed = min(ground_speed * speed, ground_speed)
	var add_speed = new_speed - current_speed
	if add_speed > 0:
		# calculate acceleration and cap it to our desired speed
		var accel = ground_accel * new_speed * delta
		if accel > add_speed:
			accel = add_speed
		# apply acceleration towards our desired direction
		velocity += accel * dir


func air_accelerate(dir, speed, delta):
	# get current speed towards desired direction
	var current_speed = velocity.dot(dir)
	# calcuate speed we need to make up to reach our desired speed
	var new_speed = min(air_speed * speed, air_speed)
	var add_speed = new_speed - current_speed
	if add_speed > 0:
		# calculate acceleration and cap it to our desired speed
		var accel = air_accel * new_speed * delta
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
		velocity.y = jump_power
		mp_send_velocity.rpc(velocity)
		jump_midair_count = 0
	elif midair && jump_midair_count < jump_midair:
		velocity.y = jump_power
		mp_send_velocity.rpc(velocity)
		jump_midair_count += 1


func interact():
	mp_send_position.rpc(position, rotation, head.position, head.rotation)
	var target
	if held_item && held_item.get_parent() != inventory:
		target = held_item
	else:
		target = get_aim(2.0).collider
	if target && target.has_method("activate"):
		target.activate.rpc(get_path())


func action():
	mp_send_position.rpc(position, rotation, head.position, head.rotation)
	if held_item:
		if held_item.has_method("action"):
			held_item.action.rpc()
		elif held_item.has_method("activate"):
			held_item.activate.rpc(get_path())
	else:
		interact()


func set_held_item(item:Item):
	for inv_item in inventory.get_children():
		if item == null:
			item = inv_item
			item.visible = true
		elif item != inv_item && item.get_parent() == inventory:
			inv_item.visible = false

	held_item = item


func mp_tick():
	if is_multiplayer_authority():
		mp_send_movement.rpc(desired_move)
		mp_send_position.rpc(position, rotation, head.position, head.rotation)


@rpc
func mp_send_movement(movement):
	desired_move = movement

@rpc
func mp_send_position(pos, ang, head_pos, head_ang):
	position = pos
	rotation = ang
	head.position = head_pos
	head.rotation = head_ang

@rpc
func mp_send_velocity(vel):
	velocity = vel
