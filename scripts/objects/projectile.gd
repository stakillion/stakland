extends PhysicsBody3D


@export var speed = 20.0

@onready var weapon = get_parent()
@onready var user = weapon.user


func _ready():
	add_collision_exception_with(weapon)
	add_collision_exception_with(user)


func _physics_process(delta):
	var new_pos = position - transform.basis.z * speed * delta
	var collision = move_and_collide(new_pos - position)
	if collision:
		# TODO - explode!
		queue_free()


func _on_timer_timeout():
	queue_free()
