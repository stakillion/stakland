extends Control


func _ready():
	$MainMenu/PlayButton.grab_focus()
	toggle_player_menu()


func _process(_delta):
	if visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _input(event):
	if event.is_action_pressed("ui_cancel"):
		visible = !visible
		$MainMenu/PlayButton.grab_focus()


func toggle_player_menu():
	if !Player.pawn:
		$PlayerMenu.visible = false
		return

	$PlayerMenu.visible = true
	for node in $PlayerMenu/PhysicsSettings.get_children():
		var label = node.get_meta("label")
		var property = node.get_meta("property")
		var value = Player.pawn.physics.get(property)
		if value != null:
			node.value = value
			node.find_child("Label").text = "%s: %f" % [label, value]
		if !node.is_connected("value_changed", _on_physics_setting_value_changed.bind(property, label, node)):
			node.connect("value_changed", _on_physics_setting_value_changed.bind(property, label, node))


func _on_PlayButton_pressed():
	if !Player.pawn:
		Player.spawn.rpc()
	visible = false


func _on_respawn_button_pressed():
	Player.spawn.rpc()


func _on_connect_button_pressed():
	if $MultiplayerMenu/AddressField.text.is_empty():
		Game.host_game()
	else:
		Game.join_game($MultiplayerMenu/AddressField.text)


func _on_QuitButton_pressed():
	get_tree().quit()


func _on_fullscreen_button_pressed():
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _on_physics_setting_value_changed(value, property, label, node):
	Player.set_physics_parameter.rpc(property, value)
	node.find_child("Label").text = "%s: %f" % [label, value]


func _on_address_field_text_changed():
	if $MultiplayerMenu/AddressField.text.is_empty():
		$MultiplayerMenu/ConnectButton.text = "Host"
	else:
		$MultiplayerMenu/ConnectButton.text = "Connect"
