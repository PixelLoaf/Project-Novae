extends Node2D

export var damage = 1.0
export var force = 10.0
export var direction = Vector2(1, -1)

var attacked_areas = []
var count = 0

signal on_attack(body, attack)

func _ready():
	$AnimationPlayer.play("Play")
	if $Area2D.collision_mask == 0:
		print("Warining: attack has no collision mask for ", filename)
	if $Area2D.collision_layer != 0:
		print("Warining: attack has non-zero collision layer for ", filename)

func set_speed(value):
	$AnimationPlayer.playback_speed = value

func set_rate(value):
	$AnimationPlayer.playback_speed = 1/value

func get_duration():
	return $AnimationPlayer.get_animation("Play").length / $AnimationPlayer.playback_speed

func get_direction():
	return (direction * scale).rotated(get_parent().global_rotation)

func _on_Area2D_area_entered(area):
	if not area in attacked_areas:
		var body = area.get_parent()
		attacked_areas.append(area)
		count += 1
		emit_signal("on_attack", body, self)
		var dir = get_direction().rotated(-body.global_rotation).normalized()
		body.char_velocity = dir * force
		body.char_on_ground = false
		body.char_do_damage(damage)

func attack_reset():
	var old_areas = attacked_areas
	attacked_areas = []
	count = 0
	for area in old_areas:
		if $Area2D.overlaps_area(area):
			_on_Area2D_area_entered(area)