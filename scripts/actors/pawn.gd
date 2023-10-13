extends PhysicsBody3D


# controls itself by default (aka does nothing)
var control = self

# -- physics --
# higher air acceleration enables mid-air turns and slope surfing
@export var ground_speed = 6.5
@export var ground_accel = 5.0
@export var ground_friction = 4.0
@export var air_speed = 1.0
@export var air_accel = 30.0
@export var air_friction = 0.0
@export var jump_power = 8.0
@export var jump_midair = 1
@onready var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@export var head = Vector3()

var velocity = Vector3()
var on_ground = false
var jump_midair_count = 0


func _physics_process(delta):
	# get desired movement from controller
	var movement = control.get_movement()

	# accelerate velocity based on desired movement and ground state
	if on_ground:
		ground_accelerate(movement, delta)
	else:
		air_accelerate(movement, delta)

	# do move based on our current velocity
	velocity = move(velocity, delta)


func move(vel, delta, max_slides = 6):
	on_ground = false
	var motion = (vel * delta) / max_slides
	while max_slides:
		max_slides -= 1
		# move and check for collision
		var collision = move_and_collide(motion, false, 0.001, true)
		if !collision:
			continue
		# if we hit something and it's not too steep then we consider it ground
		if collision.get_angle() < 0.786:
			on_ground = true
			jump_midair_count = 0
		# slide along the normal vector of the colliding body
		var collision_norm = collision.get_normal()
		motion = motion.slide(collision_norm)
		vel = vel.slide(collision_norm)

	return vel


func ground_accelerate(movement, delta):
	# get current speed towards desired direction
	var dirspeed = velocity.length()
	# calculate speed we need to make up to reach our desired speed
	var speed = min(ground_speed * movement.speed, ground_speed)
	var addspeed = speed - dirspeed
	if addspeed > 0:
		# calculate acceleration and cap it to our desired speed
		var accelspeed = ground_accel * speed * delta
		if accelspeed > addspeed:
			accelspeed = addspeed
		# apply acceleration to velocity
		velocity += accelspeed * movement.direction

	# apply friction
	apply_friction(ground_friction, delta)


func air_accelerate(movement, delta):
	# get current speed towards desired direction
	var dirspeed = velocity.dot(movement.direction)
	# calcuate speed we need to make up to reach our desired speed
	var speed = min(air_speed * movement.speed, air_speed)
	var addspeed = speed - dirspeed
	if addspeed > 0:
		# calculate acceleration and cap it to our desired speed
		var accelspeed = air_accel * speed * delta
		if accelspeed > addspeed:
			accelspeed = addspeed
		# apply acceleration to velocity
		velocity += accelspeed * movement.direction

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


func jump(midair = true):
	if on_ground:
		velocity.y = jump_power
		jump_midair_count = 0
		return true

	elif midair and jump_midair_count < jump_midair:
		velocity.y = jump_power
		jump_midair_count += 1
		return false

	return false


func get_movement():
	# we don't have an assigned controller, so do nothing
	return {direction = Vector3(), speed = 0.0}
