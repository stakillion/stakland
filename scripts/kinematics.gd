class_name KinematicBody extends PhysicsBody3D

@export var run_speed: = 8.0
@export var run_accel: = 10.0
@export var run_friction: = 8.0
@export var air_speed: = 1.0
@export var air_accel: = 15.0
@export var air_friction: = 0.0
@export var gravity: = 20.0
@export var max_speed: = 200.0
@export var max_step_height: = 0.5

var velocity: = Vector3()
var in_air: = false
var on_ledge: = false


func _physics_process(delta) -> void:
	apply_kinematics(delta)


func apply_kinematics(delta:float, dir: = Vector3.ZERO) -> void:
	if !in_air || on_ledge:
		# apply friction
		apply_friction(run_friction, delta)
		# apply acceleration
		accelerate(dir, run_speed, run_accel, delta, true)
		# step up stairs/ledges
		try_step_up(delta)
	else:
		# apply gravity
		velocity.y -= gravity * delta
		# apply friction
		apply_friction(air_friction, delta)
		# apply acceleration
		accelerate(dir, air_speed, air_accel, delta)

	if max_speed > 0:
		# enforce speed limit
		apply_max_speed(max_speed)

	move(delta)


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
		# slide along the normal vector of the colliding body
		var collision_norm: = collision.get_normal()
		motion = motion.slide(collision_norm)
		if !on_ledge:
			velocity = velocity.slide(collision_norm)


func accelerate(dir:Vector3, speed:float, accel:float, delta:float, flat: = false) -> void:
	# get current speed towards desired direction
	var current_speed: = velocity.length() if flat else velocity.dot(dir)
	# calculate speed we need to make up to reach our desired speed
	var add_speed: = speed - current_speed
	if add_speed > 0:
		# cap acceleration to our desired speed and apply towards our desired direction
		velocity += minf(accel * speed * delta, add_speed) * dir


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


func try_step_up(delta:float) -> void:
	on_ledge = false
	var forward: = Vector3(velocity.x, 0.0, velocity.z) * delta
	var motion: = Vector3(0.0, max_step_height, 0.0)
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
		if "head_offset" in self:
			self.head_offset -= motion
