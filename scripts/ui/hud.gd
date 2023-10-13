extends Label


func _physics_process(_delta):
	var speed = Player.pawn.velocity
	speed.y = 0.0
	var fps = Performance.get_monitor(Performance.TIME_FPS)
	text = "FPS: %d     Speed: %f     on_floor: %s" % [fps, speed.length(), Player.pawn.on_ground]
