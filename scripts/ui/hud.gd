extends Control


@onready var player = get_parent()


func _physics_process(_delta):
	# info display
	var fps = Performance.get_monitor(Performance.TIME_FPS)
	var speed = player.pawn.velocity
	speed.y = 0.0
	$Info.text = "FPS:%d\nH.Speed:%f" % [fps, speed.length()]

	# crosshair
	var camera = get_viewport().get_camera_3d()
	var aim_pos = player.pawn.get_aim_target().position
	$Crosshair.visible = !camera.is_position_behind(aim_pos)
	$Crosshair.position = camera.unproject_position(aim_pos)
