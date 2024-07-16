extends Control


func _ready() -> void:
	$MainMenu/PlayButton.grab_focus()
	update_settings()

	connect("visibility_changed", _on_visibility_changed)


func _input(event:InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		visible = !visible


#func _notification(what:int) -> void:
#	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
#		visible = true


func update_settings() -> void:
	if Player.pawn:
		for node in $PlayerMenu/PhysicsSettings.get_children():
			var label: = node.get_meta("label") as String
			var property: = node.get_meta("property") as String
			var value: = Player.pawn.physics.get(property) as float
			if value != null:
				node.value = value
				node.find_child("Label").text = "%s: %f" % [label, value]
			if !node.is_connected("value_changed", _on_physics_setting_value_changed.bind(property, label, node)):
				node.connect("value_changed", _on_physics_setting_value_changed.bind(property, label, node))
		$PlayerMenu.visible = true
	else:
		$PlayerMenu.visible = false


func _on_visibility_changed() -> void:
	if visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		$MainMenu/PlayButton.grab_focus()
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _on_PlayButton_pressed() -> void:
	if !Player.pawn:
		Player.spawn.rpc()
	visible = false


func _on_respawn_button_pressed() -> void:
	Player.spawn.rpc()


func _on_connect_button_pressed() -> void:
	if $MultiplayerMenu/AddressField.text.is_empty():
		Game.host_game()
	else:
		Game.join_game($MultiplayerMenu/AddressField.text)


func _on_QuitButton_pressed() -> void:
	get_tree().quit()


func _on_fullscreen_button_pressed() -> void:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _on_physics_setting_value_changed(value:float, property:String, label:String, node:Node) -> void:
	Player.set_physics_parameter.rpc(property, value)
	node.find_child("Label").text = "%s: %f" % [label, value]


func _on_address_field_text_changed() -> void:
	if $MultiplayerMenu/AddressField.text.is_empty():
		$MultiplayerMenu/ConnectButton.text = "Host"
	else:
		$MultiplayerMenu/ConnectButton.text = "Connect"
