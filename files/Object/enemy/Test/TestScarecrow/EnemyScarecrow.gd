extends "res://lib/char.gd"

func _ready():
	connect("char_on_damage_taken", self, "_on_damage_taken")

func _physics_process(delta):
	char_do_movement(delta, 5)

func _on_damage_taken(damage):
	$AnimationPlayer.play("Hurt")