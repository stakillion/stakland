extends Control


func _process(_delta):
	if visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _input(event):
	if event.is_action_pressed("ui_cancel"):
		visible = !visible


func enable_game_menu(enable = true):
	# enable menu physics settings
	$PhysicsSettings.visible = enable
	for node in $PhysicsSettings.get_children():
		if !enable: break
		var label = node.get_meta("label")
		var property = node.get_meta("property")
		var value = Player.pawn.get(property)
		node.value = value
		node.find_child("Label").text = "%s: %f" % [label, value]
		node.connect("value_changed", Game.menu._on_physics_setting_value_changed.bind(property, label, node))
	# enable respawn button
	$Main/RespawnButton.visible = enable
	# disable address field
	$AddressField.visible = !enable


func _on_PlayButton_pressed():
	if multiplayer.multiplayer_peer != Game.peer:
		if $AddressField.text.is_empty():
			Game.host_game()
		else:
			Game.join_game($AddressField.text)

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
