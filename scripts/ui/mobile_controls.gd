extends Node2D

var swipe_move_index: = -1
var swipe_move_start: = Vector2()


func _ready() -> void:
	var bounds: = get_viewport().get_visible_rect().size
	$TopRightAnchor.position.x = bounds.x
	$TopRightAnchor.position.y = 0
	$BottomRightAnchor.position.x = bounds.x
	$BottomRightAnchor.position.y = bounds.y

	for button in find_children("*", "TouchScreenButton"):
		button.pressed.connect(_on_button_pressed.bind(button))
		button.released.connect(_on_button_released.bind(button))


func _unhandled_input(event) -> void:
	if event is InputEventScreenTouch:
		if event.is_pressed() && event.position.x < get_viewport().get_visible_rect().size.x / 2:
			swipe_move_index = event.index
			swipe_move_start = event.position
		elif event.index == swipe_move_index:
			swipe_move_index = -1
			Input.action_press("move_forward", 0.0)
			Input.action_press("move_back", 0.0)
			Input.action_press("move_left", 0.0)
			Input.action_press("move_right", 0.0)
	elif event is InputEventScreenDrag:
		if event.index != swipe_move_index:
			# rotate view based on touchscreen swipe
			Player.camera.rotation.y -= deg_to_rad(event.relative.x * Player.swipe_sensitivity.x * 0.022)
			Player.camera.rotation.x -= deg_to_rad(event.relative.y * Player.swipe_sensitivity.y * 0.022)
			Player.camera.rotation.x = clamp(Player.camera.rotation.x, deg_to_rad(-89), deg_to_rad(89))
		else:
			var swipe_vector:Vector2 = (event.position - swipe_move_start) / 128
			Input.action_press("move_forward", swipe_vector.dot(Vector2.UP))
			Input.action_press("move_back", swipe_vector.dot(Vector2.DOWN))
			Input.action_press("move_left", swipe_vector.dot(Vector2.LEFT))
			Input.action_press("move_right", swipe_vector.dot(Vector2.RIGHT))


func _on_button_pressed(button:TouchScreenButton) -> void:
	button.self_modulate = Color(2, 2, 2)

func _on_button_released(button:TouchScreenButton) -> void:
	button.self_modulate = Color(1, 1, 1)
