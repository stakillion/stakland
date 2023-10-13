extends Node2D


func _physics_process(_delta):
	# info display
	var fps = Performance.get_monitor(Performance.TIME_FPS)
	var speed = Player.pawn.velocity
	speed.y = 0.0
	$Info.text = "FPS: %d     H.Speed: %f" % [fps, speed.length()]

	# crosshair
	var aim_pos = Player.pawn.get_aim_target().position
	$Crosshair.visible = !Player.camera.is_position_behind(aim_pos)
	$Crosshair.position = Player.camera.unproject_position(aim_pos)
