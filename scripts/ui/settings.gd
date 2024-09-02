extends Window


func _ready():
	update_settings()


func _on_color_picker_color_changed(color):
	Player.set_player_color.rpc(color)


func update_settings() -> void:
	if !is_instance_valid(Player):
		return

	for node in $TabContainer/Controls.get_children():
		var property: = node.get_meta("property") as String
		var value: = 0.0
		if property.contains("_sensitivity"):
			value = Player[property].x
		else:
			value = Player[property]
		if value != null:
			node.value = value
		if !node.value_changed.is_connected(_on_setting_value_changed.bind(property)):
			node.value_changed.connect(_on_setting_value_changed.bind(property))


func _on_setting_value_changed(value:float, property:String) -> void:
	if property.contains("_sensitivity"):
		Player[property].x = value
		Player[property].y = value
	else:
		Player[property] = value


func _on_fullscreen_toggled(toggled_on):
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
