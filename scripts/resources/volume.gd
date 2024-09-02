class_name KinematicVolume extends Resource


@export var friction: = 0.0
@export_file("*.tscn") var effect_path:String
var effect:Resource


func _setup_local_to_scene() -> void:
	if effect_path.is_empty():
		return
	if !is_instance_valid(effect):
		effect = load(effect_path)


func play_effect(pos:Vector3) -> void:
	if effect_path.is_empty():
		return
	if !is_instance_valid(effect):
		effect = load(effect_path)
	if !effect.can_instantiate():
		return

	var effect_instance: = effect.instantiate() as Effect
	effect_instance.position = pos
	Game.effects.add_child(effect_instance, true)
	effect_instance.destroy_on_timeout = true
	effect_instance.activate()
