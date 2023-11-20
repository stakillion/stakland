extends Control

@onready var pawn = get_parent()


func _process(_delta):
	visible = (pawn == Game.player.pawn)

	# crosshair
	var camera = get_viewport().get_camera_3d()
	var aim_pos = pawn.get_aim().position
	$Crosshair.visible = !camera.is_position_behind(aim_pos)
	$Crosshair.position = camera.unproject_position(aim_pos)


func _on_timer_timeout():
	# info display
	var fps = Performance.get_monitor(Performance.TIME_FPS)
	var speed = pawn.velocity
	speed.y = 0.0
	$Info.text = "FPS:%d\nH.Speed:%f" % [fps, speed.length()]
