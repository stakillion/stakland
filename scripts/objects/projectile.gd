extends PhysicsBody3D

@export var speed: = 25.0
@export var launch_velocity: = Vector3.ZERO
@export var knockback: = 6.0
@export var damage: = 20.0
@export var radius: = 5.0
@export var lifetime: = 60.0
@export_flags_3d_physics var trigger_on_contact

@export var trigger_effect:Effect
@export var trail_effect:Effect

@onready var effect_area: = find_children("*", "Area3D")[0] as Area3D

var weapon:Item = null
var triggered: = false


func _ready() -> void:
	if weapon: add_collision_exception_with(weapon)
	if weapon.user: add_collision_exception_with(weapon.user)

	if "linear_velocity" in self:
		self.linear_velocity += basis * launch_velocity

	# automatically explode after x seconds
	await get_tree().create_timer(lifetime).timeout
	trigger()


func _physics_process(delta:float) -> void:
	if !triggered:
		# move projectile forward, check for collision
		var collision: = move_and_collide(-basis.z * speed * delta, false, 0.001, true)
		if collision:
			var normal: = collision.get_normal()
			if "linear_velocity" in self:
				self.linear_velocity = self.linear_velocity.slide(normal)
			var layer: = PhysicsServer3D.body_get_collision_layer(collision.get_collider_rid())
			if trigger_on_contact & layer == 0:
				return
			if trigger_effect:
				trigger_effect.set_direction(normal)
			trigger()


func trigger() -> void:
	triggered = true

	for body in effect_area.get_overlapping_bodies():
		if body == self:
			continue
		var dir:Vector3 = body.global_position - global_position
		if dir.length() > radius:
			continue
		var power: = radius / exp(dir.length())
		dir = dir.normalized()
		# apply force to players and objects within radius
		if "linear_velocity" in body:
			body.linear_velocity += knockback * power * dir
		elif "velocity" in body:
			body.velocity += knockback * power * dir
		# apply damage
		if body.is_multiplayer_authority() && body.has_method("set_health"):
			if body != weapon.user:
				body.set_health.rpc(body.health - damage * power)
			#else: # deal less damage to self
				#body.set_health.rpc(body.health - damage * power / 4)

	# hide the projectile
	$Mesh.visible = false
	if trail_effect: trail_effect.active = false
	# explosion effect
	if trigger_effect: trigger_effect.active = true
	# clean up
	queue_free()


func _on_mp_sync_frame() -> void:
	if is_multiplayer_authority():
		mp_send_position.rpc(position, rotation)

@rpc("unreliable_ordered")
func mp_send_position(pos:Vector3, ang:Vector3) -> void:
	position = pos
	rotation = ang
