extends Node


@export var mouse_sensitivity = Vector2(10.0, 10.0)
@export var joy_sensitivity = Vector2(10.0, 7.5)

var view_script = preload("res://scripts/player_view.gd")

# character we are controlling
@onready var pawn = $"/root/World/Pawn"
var view:Node3D

# control settings
@export var auto_jump = true


func _ready():
	# give player control of pawn
	pawn.control = self

	# spawn camera and tell it to follow pawn
	view = view_script.new()
	view.name = "PlayerView"
	view.target = pawn

func _process(_delta):
	if Input.is_action_just_pressed("jump"):
		pawn.jump(true)
	elif auto_jump and Input.is_action_pressed("jump"):
		pawn.jump(false)


func _unhandled_input(event):
	if pawn == null:
		return

	if event is InputEventMouseMotion:
		# get mouse coordinates for camera rotation
		var rot = view.rotation
		rot.y -= event.relative.x * (Player.mouse_sensitivity.x / 10000)
		rot.x -= event.relative.y * (Player.mouse_sensitivity.y / 10000)
		# rotate view
		view.rotation = rot
		view.rotation.x = clamp(view.rotation.x, deg_to_rad(-89), deg_to_rad(89))
	else:
		# or use input mapping to rotate over time (e.g. joystick)
		view.rot_velocity.y = (Input.get_action_strength("look_right") - Input.get_action_strength("look_left")) * (Player.joy_sensitivity.x / 5)
		view.rot_velocity.x = (Input.get_action_strength("look_down") - Input.get_action_strength("look_up")) * (Player.joy_sensitivity.y / 5)

	# *zoom*
	if event.is_action_released("ui_page_up"):
		view.zoom = clamp(view.zoom - 0.5, 0.0, view.zoom_max) if view.zoom - 0.5 >= view.zoom_min else 0.0
	if event.is_action_released("ui_page_down"):
		view.zoom = view.zoom_min if view.zoom + 0.5 <= view.zoom_min else clamp(view.zoom + 0.5, 0.0, view.zoom_max)


func get_movement():
	var dir = Vector3()
	dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	dir.z = Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")

	var speed = dir.length()

	# rotate direction vector according to camera angle
	if pawn != null:
		dir = view.camera.global_transform.basis.get_rotation_quaternion() * dir
		dir.y = 0

	return {direction = dir.normalized(), speed = speed}
