extends Node3D

@export var speed = 25
@export var knockback = 6
@export var damage = 20
@export var radius = 5

var weapon = null
var exploded = false


func _ready():
	if weapon: $RayCast.add_exception(weapon)
	if "pawn" in owner: $RayCast.add_exception(owner.pawn)

	# automatically explode after 60 seconds
	await get_tree().create_timer(60).timeout
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
	for body in $ExplosionArea.get_overlapping_bodies():
		if body == self:
			continue
		var dir = body.global_position - pos
		if dir.length() > radius:
			continue

		var power = radius / exp(dir.length())
		dir = dir.normalized()
		# apply force to players and objects within radius
		if "linear_velocity" in body:
			body.linear_velocity += knockback * power * dir
		elif "velocity" in body:
			body.velocity += knockback * power * dir
		# apply damage
		if body.is_multiplayer_authority() && body.has_method("set_health"):
			if "pawn" not in owner || body != owner.pawn:
				body.set_health.rpc(body.health - damage * power)
			#else: # deal less damage to self
				#body.set_health.rpc(body.health - damage * power / 4)

	# hide the projectile
	$Mesh.visible = false
	$ParticleTrail.emitting = false
	# explosion effect
	$ExplosionEffect.emitting = true
	# dispose of ourself after delay
	await get_tree().create_timer(1).timeout
	queue_free()


func _on_mp_sync_frame():
	if is_multiplayer_authority():
		mp_send_position.rpc(position, rotation)

@rpc("unreliable_ordered")
func mp_send_position(pos, ang):
	position = pos
	rotation = ang
