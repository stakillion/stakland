class_name GamePlayer extends Node

# networked player data
var data: = {
	pawn_scene = "res://scenes/characters/pawn.tscn",
	color = Color(1, 1, 1)
}

# character we are controlling
var pawn:Pawn = null

# camera
var camera:Camera3D
var cam_area:Area3D
var cam_follow_node:NodePath = ""
var cam_zoom: = 0.0
var aim_position:Vector3

# effects
@export var spawn_effect = preload("res://scenes/effects/player_spawn.tscn")


func _init() -> void:
	# create the camera
	camera = Camera3D.new()
	camera.name = "Camera"
	add_child(camera, true)
	# create the area containing the camera for collision detection
	cam_area = Area3D.new()
	camera.add_child(cam_area, true)
	var cam_collision: = CollisionShape3D.new()
	cam_collision.shape = SphereShape3D.new()
	cam_collision.shape.radius = 0.01
	cam_area.add_child(cam_collision, true)


func _process(delta:float) -> void:
	var cam_follow:Node3D
	if !cam_follow_node.is_empty():
		cam_follow = get_node_or_null(cam_follow_node)
		if !cam_follow:
			# find a player to spectate
			for player in Game.players.get_children():
				if player.pawn:
					cam_follow = player.pawn
					cam_activate(player.pawn)
		if !cam_follow: cam_activate(null)
	if is_instance_valid(cam_follow):
		var follow_pos:Vector3 = cam_follow.head.global_position if cam_follow is Pawn else cam_follow.global_position
		# distance the camera from the follow position by our zoom level
		#cam_zoom = lerp(cam_zoom, input.desired_zoom, 3 * delta)
		var zoom_vec: = camera.basis.z * cam_zoom
		if cam_zoom > 0.1: zoom_vec *= cam_cast_motion(follow_pos, zoom_vec)[0]
		# update camera position
		camera.position = follow_pos + zoom_vec


@rpc("call_local", "reliable")
func spawn() -> void:
	remove_pawn()
	# create pawn
	pawn = load(data.pawn_scene).instantiate()
	add_child(pawn)
	# teleport our pawn to spawn
	var spawn_point:Node3D = Game.world.find_player_spawn()
	pawn.set_origin(spawn_point.position)
	pawn.set_angle(spawn_point.rotation)
	# have the camera follow our pawn
	cam_activate(pawn, 5.0)
	if Player == self:
		# update menu
		Game.menu.update_main_menu()
		Game.menu.update_settings()
	# spawn effect
	if is_instance_valid(spawn_effect) && spawn_effect.can_instantiate():
		var effect: = spawn_effect.instantiate()
		effect.position = pawn.position
		add_child(effect, true)
	# color
	for mesh in pawn.find_children("*", "MeshInstance3D"):
		mesh.set_instance_shader_parameter("custom_color", data.color)


func remove_pawn() -> void:
	if is_instance_valid(pawn):
		pawn.queue_free()
		pawn.name += "_"
		pawn = null
	if Player == self:
		Game.menu.update_settings()


@rpc("call_local", "reliable")
func set_player_color(color:Color) -> void:
	data.color = color
	if is_instance_valid(pawn): for mesh in pawn.find_children("*", "MeshInstance3D"):
		mesh.set_instance_shader_parameter("custom_color", color)


@rpc("call_local", "reliable")
func set_physics_parameter(property, value) -> void:
	pawn[property] = value


func cam_activate(follow:Node3D = null, zoom: = 0.0) -> void:
	if is_instance_valid(follow):
		cam_follow_node = follow.get_path()
		if "collision_layer" in follow:
			cam_area.collision_layer = follow.collision_layer
		camera.rotation.y = follow.rotation.y
		camera.rotation.x = follow.head.rotation.x if follow is Pawn else follow.rotation.x
		if Player == self:
			camera.make_current()
		cam_zoom = zoom
	else:
		cam_follow_node = ""
		camera.current = false


func cam_cast_motion(start:Vector3, motion:Vector3) -> PackedFloat32Array:
	var cam_follow: = get_node_or_null(cam_follow_node)
	var query: = PhysicsShapeQueryParameters3D.new()
	query.transform.origin = start
	query.shape = SphereShape3D.new()
	query.shape.radius = 0.1
	query.motion = motion
	query.exclude = [cam_follow] + cam_follow.find_children("*") if cam_follow else []
	return camera.get_world_3d().direct_space_state.cast_motion(query)
