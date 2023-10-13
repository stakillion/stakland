extends Node3D


# spatial node we should orbit around
@export var target:Node3D : set = set_target
# the camera we are using
var camera:Camera3D

var rot_velocity = Vector3()
var zoom_min = 2.0
var zoom_max = 4.5
var zoom = zoom_min


func _ready():
	camera = Camera3D.new()
	#camera.process_mode = ClippedCamera.CLIP_PROCESS_IDLE
	camera.name = "Camera"
	add_child(camera)


func _process(delta):

	# rotate camera by velocity
	if rot_velocity.length_squared() != 0.0:
		rotation -= rot_velocity * delta
		rotation.x = clamp(rotation.x, deg_to_rad(-89), deg_to_rad(89))

	var pivot = target.position + Vector3(0.0, 0.75, 0.0)
	#var dir = camera.transform.basis.get_rotation_quat() * Vector3.FORWARD

	# smoothly move camera in/out based on zoom level
	camera.position = lerp(camera.position, Vector3(0.0, 0.0, zoom), 5 * delta)
	var current_zoom = camera.position.length()

	# move view to target
	position = lerp(position, pivot, clamp(1 - current_zoom, 0.15, 1))


func set_target(new_target):
	if target != null:
		camera.remove_exception(target)

	target = new_target
	#camera.add_exception(target)

	# add ourself as a child of our view target
	var parent = get_parent()
	if (parent): parent.remove_child(self)
	target.add_child(self)
	set_as_top_level(true)
