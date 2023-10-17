extends Node2D


func _physics_process(_delta):
	# info display
	var fps = Performance.get_monitor(Performance.TIME_FPS)
	var speed = $/root/World/Pawn.velocity
	speed.y = 0.0
	$Info.text = "FPS:%d\nH.Speed:%f" % [fps, speed.length()]

	# crosshair
	var aim_pos = $/root/World/Pawn.get_aim_target().position
	$Crosshair.visible = !Player.camera.is_position_behind(aim_pos)
	$Crosshair.position = Player.camera.unproject_position(aim_pos)
