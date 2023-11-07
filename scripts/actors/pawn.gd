class_name Pawn
extends PhysicsBody3D

# -- physics --
# higher air acceleration enables mid-air turns and slope surfing
@export var ground_speed = 6.5
@export var ground_accel = 5.0
@export var ground_friction = 4.0
@export var air_speed = 1.0
@export var air_accel = 20.0
@export var air_friction = 0.0
@export var jump_power = 7.0
@export var jump_midair = 1
@export var gravity = 20.0

var movement = Vector3()
var velocity = Vector3()
var on_ground = false
var jump_midair_count = 0

# head is used to track where we are looking
@onready var head = $Head
# inventory is used to store items
@onready var inventory = $Head/Inventory
var active_item:Item
var held_item:Item


func _ready():
	Game.mp_tick.connect("timeout", mp_tick)


func _physics_process(delta):
	if is_multiplayer_authority():
		# look where our controller is looking
		var controller = get_parent()
		if controller.has_method("get_aim_target"):
			head.look_at(controller.get_aim_target().position)

		# accelerate velocity based on desired movement and ground state
		if on_ground:
			ground_accelerate(movement.normalized(), movement.length(), delta)
		else:
			air_accelerate(movement.normalized(), movement.length(), delta)
		# do move based on our new velocity
		move(delta)

	# reset movement vector
	movement = Vector3()


func move(delta, max_slides = 6):
	on_ground = false
	var motion = (velocity * delta) / max_slides
	while max_slides:
		max_slides -= 1
		# move and check for collision
		var collision = move_and_collide(motion, false, 0.001, true)
		if !collision:
			continue
		# if we hit something and it's not too steep then we consider it ground
		if rad_to_deg(collision.get_angle()) < 45:
			on_ground = true
			jump_midair_count = 0
		# slide along the normal vector of the colliding body
		var collision_norm = collision.get_normal()
		motion = motion.slide(collision_norm)
		velocity = velocity.slide(collision_norm)


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

	# apply friction
	apply_friction(ground_friction, delta)


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

	# apply gravity
	velocity.y -= gravity * delta
	# apply friction
	apply_friction(air_friction, delta)


func apply_friction(friction, delta):
	var current_speed = velocity.length()
	if current_speed == 0.0:
		return

	var drop = max(current_speed, friction) * friction * delta
	velocity.x *= max(current_speed - drop, 0.0) / current_speed
	velocity.z *= max(current_speed - drop, 0.0) / current_speed


func get_aim_target(distance = 32768.0, exclude = [self]):
	var ray_start = head.global_position
	var ray_end = head.global_position - head.global_transform.basis.z * distance
	var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	query.exclude = exclude

	var collision = get_world_3d().direct_space_state.intersect_ray(query)
	if !collision:
		collision.position = ray_end
		collision.collider = null

	return collision


func jump(midair = true):
	if on_ground:
		on_ground = false # no longer on ground
		velocity.y = jump_power
		jump_midair_count = 0
	elif midair && jump_midair_count < jump_midair:
		velocity.y = jump_power
		jump_midair_count += 1


@rpc("any_peer", "call_local", "reliable")
func interact():
	var target
	if active_item && active_item.get_parent() != inventory:
		target = active_item
	else:
		target = get_aim_target(2.0).collider
	if target && target.has_method("activate"):
		target.activate(self)


@rpc("any_peer", "call_local", "reliable")
func action():
	var item = held_item if held_item else active_item
	if item:
		if item.has_method("action"):
			item.action()
		elif item.has_method("activate"):
			item.activate(self)
	else:
		interact()


func mp_tick():
	if is_multiplayer_authority():
		mp_update_pos.rpc(global_position, global_rotation, head.global_position, head.global_rotation)


@rpc
func mp_update_pos(pos, ang, head_pos, head_ang):
	global_position = pos
	global_rotation = ang
	head.global_position = head_pos
	head.global_rotation = head_ang
