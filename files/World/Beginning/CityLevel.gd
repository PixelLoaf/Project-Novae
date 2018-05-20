extends Node2D

var succ = false
var player = null

func _on_Area2D_body_entered(body):
	if not $AnimationPlayer.is_playing():
		$AnimationPlayer.play("Anim")
		var player = body.get_parent();
		player.char_disabled = true

func begin_succ():
	succ = true
	player = get_tree().get_nodes_in_group("player")[0]

func _physics_process(delta):
	if succ:
		player.position += Vector2(0, -1)*delta*40

func next_level():
	get_tree().change_scene_to(load("res://World/WorldTest/World.tscn"));