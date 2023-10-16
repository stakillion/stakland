extends Control


func _ready():
	visible = false

	$PhysicsSettings/GroundSpeedLabel.text = "Ground Speed: %f" % [Player.pawn.ground_speed]
	$PhysicsSettings/GroundSpeedSlider.value = Player.pawn.ground_speed
	$PhysicsSettings/GroundAccelLabel.text = "Ground Accel: %f" % [Player.pawn.ground_accel]
	$PhysicsSettings/GroundAccelSlider.value = Player.pawn.ground_accel
	$PhysicsSettings/GroundFrictionLabel.text = "Ground Friction: %f" % [Player.pawn.ground_friction]
	$PhysicsSettings/GroundFrictionSlider.value = Player.pawn.ground_friction

	$PhysicsSettings/AirSpeedLabel.text = "Air Speed: %f" % [Player.pawn.air_speed]
	$PhysicsSettings/AirSpeedSlider.value = Player.pawn.air_speed
	$PhysicsSettings/AirAccelLabel.text = "Air Accel: %f" % [Player.pawn.air_accel]
	$PhysicsSettings/AirAccelSlider.value = Player.pawn.air_accel
	$PhysicsSettings/AirFrictionLabel.text = "Air Friction: %f" % [Player.pawn.air_friction]
	$PhysicsSettings/AirFrictionSlider.value = Player.pawn.air_friction

	$PhysicsSettings/JumpPowerLabel.text = "Jump Power: %f" % [Player.pawn.jump_power]
	$PhysicsSettings/JumpPowerSlider.value = Player.pawn.jump_power
	$PhysicsSettings/JumpMidairLabel.text = "Mid Air Jumps: %f" % [Player.pawn.jump_midair]
	$PhysicsSettings/JumpMidairSlider.value = Player.pawn.jump_midair
	$PhysicsSettings/GravityLabel.text = "Gravity: %f" % [Player.pawn.gravity]
	$PhysicsSettings/GravitySlider.value = Player.pawn.gravity


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


func _on_ground_speed_slider_value_changed(value):
	Player.pawn.ground_speed = $PhysicsSettings/GroundSpeedSlider.value
	$PhysicsSettings/GroundSpeedLabel.text = "Ground Speed: %f" % [Player.pawn.ground_speed]


func _on_ground_accel_slider_value_changed(value):
	Player.pawn.ground_accel = $PhysicsSettings/GroundAccelSlider.value
	$PhysicsSettings/GroundAccelLabel.text = "Ground Accel: %f" % [Player.pawn.ground_accel]


func _on_ground_friction_slider_value_changed(value):
	Player.pawn.ground_friction = $PhysicsSettings/GroundFrictionSlider.value
	$PhysicsSettings/GroundFrictionLabel.text = "Ground Friction: %f" % [Player.pawn.ground_friction]


func _on_air_speed_slider_value_changed(value):
	Player.pawn.air_speed = $PhysicsSettings/AirSpeedSlider.value
	$PhysicsSettings/AirSpeedLabel.text = "Air Speed: %f" % [Player.pawn.air_speed]


func _on_air_accel_slider_value_changed(value):
	Player.pawn.air_accel = $PhysicsSettings/AirAccelSlider.value
	$PhysicsSettings/AirAccelLabel.text = "Air Accel: %f" % [Player.pawn.air_accel]


func _on_air_friction_slider_value_changed(value):
	Player.pawn.air_friction = $PhysicsSettings/AirFrictionSlider.value
	$PhysicsSettings/AirFrictionLabel.text = "Air Friction: %f" % [Player.pawn.air_friction]


func _on_jump_power_slider_value_changed(value):
	Player.pawn.jump_power = $PhysicsSettings/JumpPowerSlider.value
	$PhysicsSettings/JumpPowerLabel.text = "Jump Power: %f" % [Player.pawn.jump_power]


func _on_jump_midair_slider_value_changed(value):
	Player.pawn.jump_midair = $PhysicsSettings/JumpMidairSlider.value
	$PhysicsSettings/JumpMidairLabel.text = "Mid Air Jumps: %d" % [Player.pawn.jump_midair]


func _on_gravity_slider_value_changed(value):
	Player.pawn.gravity = $PhysicsSettings/GravitySlider.value
	$PhysicsSettings/GravityLabel.text = "Gravity: %f" % [Player.pawn.gravity]
