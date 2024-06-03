extends Control

@onready var pawn: = get_parent() as Pawn


func _process(_delta:float) -> void:
	visible = pawn.is_player

	# crosshair
	var camera: = get_viewport().get_camera_3d()
	var aim_pos:Vector3 = pawn.get_aim().position + Player.cam_offset
	$Crosshair.visible = !camera.is_position_behind(aim_pos)
	$Crosshair.position = camera.unproject_position(aim_pos)

	# health
	$Health.text = "+%d" % [pawn.health]


func _on_timer_timeout() -> void:
	# info display
	var fps: = Performance.get_monitor(Performance.TIME_FPS)
	var h_velocity: = Vector3(pawn.velocity.x, 0.0, pawn.velocity.z)
	$Info.text = "FPS:%d\nSpeed:%f\nH.Speed:%f\nV.Speed:%f\nPOS:%v\nOn Ground:%s" % [fps, pawn.velocity.length(), h_velocity.length(), abs(pawn.velocity.y), pawn.position, pawn.on_ground]
