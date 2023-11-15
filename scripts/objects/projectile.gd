extends Node3D


@export var speed = 25.0
@export var impulse = 5.0

@onready var weapon = get_parent()
@onready var user = weapon.user

var timer = Timer.new()
var exploded = false


func _ready():
	# clean up timer
	add_child(timer)
	timer.connect("timeout", _on_timer_timeout)
	timer.start(60)

	$RayCast.add_exception(weapon)
	$RayCast.add_exception(user)


func _physics_process(delta):
	if !exploded:
		position -= transform.basis.z * speed * delta
		if $RayCast.get_collider():
			explode($RayCast.get_collision_point())


func explode(pos):
	exploded = true
	timer.start(1.0)

	var radius = $ExplosionArea/CollisionShape3D.shape.radius
	$ExplosionArea.global_position = pos
	for object in $ExplosionArea.get_overlapping_bodies():
		if object == self:
			continue
		var dir = (object.global_position - pos).normalized()
		var power = radius / exp(pos.distance_to(object.global_position))
		# apply force to players and objects within radius
		if "linear_velocity" in object:
			object.linear_velocity += impulse * power * dir
		elif "velocity" in object:
			object.velocity += impulse * power * dir

	# clean up
	$Mesh.queue_free()
	$RayCast.queue_free()
	$ExplosionArea.queue_free()
	$ParticleTrail.emitting = false


func _on_timer_timeout():
	if !exploded:
		explode(global_position)
	else:
		# clean up remaining nodes
		queue_free()
