extends RigidBody3D


@export var speed = 20.0

@onready var weapon = get_parent()
@onready var user = weapon.user


func _ready():
	pass


func _physics_process(delta):
	position = position - transform.basis.z * speed * delta


func _on_timer_timeout():
	queue_free()
