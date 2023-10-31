extends Control


func _ready():
	enable_game_menu(false)


func _process(_delta):
	if visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _input(event):
	if event.is_action_pressed("ui_cancel"):
		visible = !visible


func enable_game_menu(enable = true):
	# disable main menu
	$MainMenu.visible = !enable
	# disable multiplayer address field
	$AddressField.visible = !enable

	# enable game menu
	$GameMenu.visible = enable
	# enable player menu
	$PlayerMenu.visible = enable
	for node in $PlayerMenu.get_children():
		if !enable: break
		var label = node.get_meta("label")
		var property = node.get_meta("property")
		var value = Game.player.pawn.get(property)
		node.value = value
		node.find_child("Label").text = "%s: %f" % [label, value]
		node.connect("value_changed", _on_physics_setting_value_changed.bind(property, label, node))


func _on_PlayButton_pressed():
	if $AddressField.text.is_empty():
		Game.host_game()
	else:
		Game.join_game($AddressField.text)

	visible = false


func _on_resume_button_pressed():
	visible = false


func _on_respawn_button_pressed():
	Game.player.pawn.global_position = Game.world.spawn_pos


func _on_disconnect_button_pressed():
	for player in Game.player_list.get_children():
		Game.remove_player(player)

	Game.mp_peer.close()


func _on_QuitButton_pressed():
	get_tree().quit()


func _on_fullscreen_button_pressed():
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _on_physics_setting_value_changed(value, property, label, node):
	Game.player.pawn.set(property, value)
	node.find_child("Label").text = "%s: %f" % [label, value]
