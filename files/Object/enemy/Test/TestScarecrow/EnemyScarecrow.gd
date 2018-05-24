extends "res://lib/char.gd"

func _ready():
	connect("char_on_damage_taken", self, "_on_damage_taken")

func _physics_process(delta):
	char_do_movement(delta, 5)
	var speed = char_get_motion_horizontal()
#	speed = lerp(speed, 0, clamp(delta*(0.1+abs(speed)), 0, 1))
	var friction
	if char_is_on_floor():
		friction = 800
	else:
		friction = 100
	if speed > 0:
		speed = clamp(speed - delta * friction, 0, speed)
	if speed < 0:
		speed = clamp(speed + delta * friction, speed, 0)
	char_set_motion_horizontal(speed)

func _on_damage_taken(damage):
	$AnimationPlayer.play("Hurt")