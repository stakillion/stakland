extends CharacterBody3D


# controls itself by default (aka does nothing)
var control = self

# physics
@export var ground_speed = 6.0
@export var ground_accel = 4.0
@export var ground_friction = 3.0
@export var air_speed = 1.0
@export var air_accel = 20.0
@export var air_friction = 0.0
@export var jump_power = 8.0
@export var jump_midair = 1

@export var head = Vector3()

@onready var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var jump_midair_count = 0


func _process(delta):

	# get movement from controller
	var move = control.get_movement()

	# on groud/in air/etc. state machine
	if is_on_floor():
		move_ground(move, delta)
	else:
		move_air(move, delta)

	# do move
	floor_block_on_wall = false
	floor_stop_on_slope = false
	move_and_slide()

	# retain velocity on slopes
	velocity = get_real_velocity()


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


func apply_friction(friction, delta):
	var current_speed = velocity.length()
	if current_speed == 0.0:
		return

	var drop = max(current_speed, friction) * friction * delta
	velocity.x *= max(current_speed - drop, 0.0) / current_speed
	velocity.z *= max(current_speed - drop, 0.0) / current_speed


func jump(midair = true):
	if is_on_floor():
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
