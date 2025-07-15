class_name PlayerInput extends PawnController


# control settings
@export var mouse_sensitivity: = Vector2(3.0, 3.0)
@export var swipe_sensitivity: = Vector2(10.0, 7.0)
@export var joy_sensitivity: = Vector2(5.0, 3.5)
@export var zoom_min: = 2.0
@export var zoom_max: = 4.5


func _physics_process(delta:float) -> void:
	if !is_multiplayer_authority():
		return
	
	var ang_velocity: = Input.get_vector("look_left", "look_right", "look_up", "look_down")
	if ang_velocity.length_squared() != 0.0:
		# rotate view based on angular velocity
		rotation.y -= ang_velocity.x * joy_sensitivity.x * delta
		rotation.x -= ang_velocity.y * joy_sensitivity.y * delta
		# clamp vertical rotation
		rotation.x = clamp(rotation.x, deg_to_rad(-89), deg_to_rad(89))

	# directional movement
	movement = Input.get_vector("move_forward", "move_back", "move_left", "move_right")
	# jumping, crouching
	action.jump = Input.is_action_pressed("jump")
	action.crouch = Input.is_action_pressed("crouch")
	# interaction
	action.primary = Input.is_action_pressed("primary")
	action.interact = Input.is_action_pressed("interact")
	# inventory management
	action.next_item = Input.is_action_pressed("next_item")
	action.prev_item = Input.is_action_pressed("prev_item")
	action.drop_item = Input.is_action_pressed("drop_item")


func _unhandled_input(event:InputEvent) -> void:
	if !is_multiplayer_authority() || Game.menu.visible:
		return

	if event is InputEventMouseMotion && Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# rotate view based on mouse coordinates
		rotation.y -= deg_to_rad(event.relative.x * mouse_sensitivity.x * 0.022)
		rotation.x -= deg_to_rad(event.relative.y * mouse_sensitivity.y * 0.022)
		rotation.x = clamp(rotation.x, deg_to_rad(-89), deg_to_rad(89))
