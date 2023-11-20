extends Node3D

@export var speed = 25.0
@export var impulse = 6.0

@onready var weapon = get_parent()
@onready var user = weapon.user

var timer = Timer.new()
var exploded = false


func _ready():
	#$RayCast.add_exception(weapon)
	$RayCast.add_exception(user)

	# automatically explode after 60 seconds
	await get_tree().create_timer(60.0).timeout
	explode(global_position)


func _physics_process(delta):
	if !exploded:
		# move projectile forward
		position -= transform.basis.z * speed * delta
		# check for collision
		if $RayCast.get_collider():
			$ExplosionEffect.direction = $RayCast.get_collision_normal()
			explode($RayCast.get_collision_point())
			return

		# optimization: only show trails that are near the player
		var view_pos = get_viewport().get_camera_3d().global_position
		if view_pos.distance_squared_to(global_position) > 1024:
			$ParticleTrail.emitting = false
		else:
			$ParticleTrail.emitting = true


func explode(pos):
	exploded = true
	var radius = $ExplosionArea/Collision.shape.radius
	$ExplosionArea.global_position = pos
	for object in $ExplosionArea.get_overlapping_bodies():
		if object == self:
			continue
		var dir = object.global_position - pos
		var power = radius / exp(dir.length())
		dir = dir.normalized()
		# apply force to players and objects within radius
		if "linear_velocity" in object:
			object.linear_velocity += impulse * power * dir
		elif "velocity" in object:
			object.velocity += impulse * power * dir

	# hide the projectile
	$Mesh.visible = false
	$ParticleTrail.emitting = false
	# explosion effect
	$ExplosionEffect.emitting = true
	# dispose of ourself after delay
	await get_tree().create_timer(1.0).timeout
	queue_free()
