extends Control

@onready var pawn: = get_parent() as Pawn


func _process(_delta:float) -> void:
	visible = pawn.is_player

	# crosshair
	var camera: = get_viewport().get_camera_3d()
	var aim_pos:Vector3 = pawn.get_aim().position
	$Crosshair.visible = !camera.is_position_behind(aim_pos)
	$Crosshair.position = camera.unproject_position(aim_pos)

	# health
	$Health.text = "+%d" % [pawn.health]


func _on_timer_timeout() -> void:
	# info display
	var fps: = Performance.get_monitor(Performance.TIME_FPS)
	$Info.text = "FPS:%d\nPOS:%v\nANG:%v\nVEL:%v\nSpeed:%f\nIn Air:%s\nCrouching:%s" % [fps, pawn.global_position, pawn.head.global_rotation, pawn.velocity, pawn.velocity.length(), pawn.in_air, pawn.crouching]
