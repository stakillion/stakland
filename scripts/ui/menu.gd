extends Control


func _ready():
	visible = false


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


func _on_QuitButton_pressed():
	get_tree().quit()
