extends Label


func _physics_process(_delta):
	var speed = Player.pawn.velocity
	#speed.y = 0.0
	var fps = Performance.get_monitor(Performance.TIME_FPS)
	text = "FPS: %d     Speed: %f" % [fps, speed.length()]
