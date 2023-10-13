extends Node

# control settings
@export var mouse_sensitivity = Vector2(10.0, 10.0)
@export var joy_sensitivity = Vector2(10.0, 7.5)
@export var zoom_min = 2.0
@export var zoom_max = 4.5
@export var auto_jump = true

# character we are controlling
@onready var pawn = $"/root/World/Pawn"

# camera
var camera:Camera3D
var zoom = zoom_min


func _ready():
	# give player control of pawn
	pawn._ready()
	pawn.control = self

	# spawn camera
	camera = Camera3D.new()
	camera.name = "Camera"
	pawn.head.add_child(camera)


func _physics_process(delta):
	if Input.is_action_just_pressed("jump"):
		pawn.jump(true)
	elif auto_jump and Input.is_action_pressed("jump"):
		pawn.jump(false)

	# smoothly move camera in/out based on zoom level
	camera.position = lerp(camera.position, Vector3(0.0, 0.0, zoom), 5 * delta)
	#var current_zoom = camera.position.length()
	#position = lerp(position, pivot, clamp(1 - current_zoom, 0.15, 1))


func _unhandled_input(event):
	if pawn == null:
		return

	if event is InputEventMouseMotion:
		# get mouse coordinates for camera rotation
		var rot = pawn.head.rotation
		rot.y -= event.relative.x * (Player.mouse_sensitivity.x / 10000)
		rot.x -= event.relative.y * (Player.mouse_sensitivity.y / 10000)
		# rotate view
		pawn.head.rotation = rot
		pawn.head.rotation.x = clamp(pawn.head.rotation.x, deg_to_rad(-89), deg_to_rad(89))
	else:
		# or use input mapping to rotate over time (e.g. joystick)
		pawn.ang_velocity.y = (Input.get_action_strength("look_right") - Input.get_action_strength("look_left")) * (Player.joy_sensitivity.x / 5)
		pawn.ang_velocity.x = (Input.get_action_strength("look_down") - Input.get_action_strength("look_up")) * (Player.joy_sensitivity.y / 5)

	# *zoom*
	if event.is_action_released("ui_page_up"):
		zoom = clamp(zoom - 0.5, 0.0, zoom_max) if zoom - 0.5 >= zoom_min else 0.0
	if event.is_action_released("ui_page_down"):
		zoom = zoom_min if zoom + 0.5 <= zoom_min else clamp(zoom + 0.5, 0.0, zoom_max)


func get_movement():
	var movement = Vector3()
	# get direction and speed from input
	movement.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	movement.z = Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")

	return movement
