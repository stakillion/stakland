extends Control


func _ready():
	visible = false

	for node in $PhysicsSettings.get_children():
		var label = node.get_meta("label")
		var property = node.get_meta("property")
		var value = Player.pawn.get(property)
		node.value = value
		node.find_child("Label").text = "%s: %f" % [label, value]
		node.connect("value_changed", _on_physics_setting_value_changed.bind(property, label, node))


func _process(_delta):
	if visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _input(event):
	if event.is_action_pressed("ui_cancel"):
		visible = !visible


func _on_PlayButton_pressed():
	visible = false


func _on_respawn_button_pressed():
	Player.pawn.position = Vector3(0, 2, 0)


func _on_QuitButton_pressed():
	get_tree().quit()


func _on_fullscreen_button_pressed():
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _on_physics_setting_value_changed(value, property, label, node):
	Player.pawn.set(property, value)
	node.find_child("Label").text = "%s: %f" % [label, value]
