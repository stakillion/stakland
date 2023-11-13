extends PhysicsBody3D


@export var speed = 25.0
@export var impulse = 3.0

@onready var weapon = get_parent()
@onready var user = weapon.user


func _ready():
	add_collision_exception_with(weapon)
	add_collision_exception_with(user)


func _physics_process(delta):
	var new_pos = position - transform.basis.z * speed * delta
	var collision = move_and_collide(new_pos - position)
	if collision:
		explode(collision.get_position())


func explode(pos):
	var radius = $ExplosionArea/CollisionShape3D.shape.radius
	for object in $ExplosionArea.get_overlapping_bodies():
		if "linear_velocity" in object:
			var dir = (pos - object.global_position).normalized()
			var power = radius / pos.distance_to(object.global_position)
			object.linear_velocity -= dir * power * impulse
		elif "velocity" in object:
			var dir = (object.global_position - pos).normalized()
			var power = radius / pos.distance_to(object.global_position)
			object.velocity += dir * power * impulse

	queue_free()


func _on_timer_timeout():
	queue_free()
