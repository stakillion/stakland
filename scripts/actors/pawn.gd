extends PhysicsBody3D


# controls itself by default (aka does nothing)
var control = self

# -- physics --
# ground speed should be > friction so we can go up slopes
# higher air acceleration enables mid-air turns and slope surfing
@export var ground_speed = 5.5
@export var ground_accel = 8.0
@export var ground_friction = 5.0
@export var air_speed = 1.0
@export var air_accel = 20.0
@export var air_friction = 0.0
@export var jump_power = 8.0
@export var jump_midair = 1
@onready var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@export var head = Vector3()

var velocity = Vector3()
var on_ground = false
var jump_midair_count = 0


func _physics_process(delta):

	on_ground = false

	var motion = velocity * delta
	var max_slides = 6
	while max_slides:
		# do move based on our current velocity
		var collision = move_and_collide(motion)
		if !collision:
			break
		# if we hit something and it's not too steep then we consider it ground
		if collision.get_angle() < 0.786:
			on_ground = true
			jump_midair_count = 0

		var collision_norm = collision.get_normal()
		motion = motion.slide(collision_norm)
		velocity = velocity.slide(collision_norm)

		max_slides -= 1

	# get desired movement from controller
	var move = control.get_movement()

	# on groud/in air/etc. state machine
	if on_ground:
		move_ground(move, delta)
	else:
		move_air(move, delta)


func move_ground(move, delta):
	# accelerate towards desired direction
	var speed = min(ground_speed * move.speed, ground_speed)
	accelerate(move.direction, speed, ground_accel, delta)

	# apply friction
	apply_friction(ground_friction, delta)


func move_air(move, delta):
	# accelerate towards desired direction
	var speed = min(air_speed * move.speed, air_speed)	
	accelerate(move.direction, speed, air_accel, delta)

	# apply gravity
	velocity.y -= gravity * delta
	# apply friction
	apply_friction(air_friction, delta)


func accelerate(dir, target_speed, accel, delta):
	# current speed towards desired direction
	var dirspeed = velocity.dot(dir)
	# speed we need to make up to reach our desired speed
	var addspeed = target_speed - dirspeed
	if addspeed <= 0:
		return

	var accelspeed = accel * target_speed * delta
	if accelspeed > addspeed:
		accelspeed = addspeed

	velocity += accelspeed * dir

# boring version of accelerate() without air strafing (but keeps our speed on the ground consistent)
func ground_accelerate(dir, target_speed, accel, delta):
	# current speed towards desired direction
	var dirspeed = velocity.length()
	# speed we need to make up to reach our desired speed
	var addspeed = target_speed - dirspeed
	if addspeed <= 0:
		return

	var accelspeed = accel * target_speed * delta
	if accelspeed > addspeed:
		accelspeed = addspeed

	velocity += accelspeed * dir


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
