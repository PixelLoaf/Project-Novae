extends Node

onready var obj = get_parent()
export var air_friction = 100
export var ground_friction = 800

func _physics_process(delta):
	var speed = obj.char_get_motion_horizontal()
#	speed = lerp(speed, 0, clamp(delta*(0.1+abs(speed)), 0, 1))
	var friction
	if obj.char_is_on_floor():
		friction = ground_friction
	else:
		friction = air_friction
	if speed > 0:
		speed = clamp(speed - delta * friction, 0, speed)
	if speed < 0:
		speed = clamp(speed + delta * friction, speed, 0)
	obj.char_set_motion_horizontal(speed)