extends Node2D

var num_bodies = 0
var is_disabled = false

signal on_dialog_over(state);

func _ready():
	check_num_bodies()

func _input(event):
	if event.is_action_pressed("action_interact"):
		emit_signal("on_dialog_over", 0)

func check_num_bodies():
	if num_bodies > 0 and not is_disabled:
		set_process_input(true)
		$Icon.show()
	else:
		set_process_input(false)
		$Icon.hide()

func set_disabled(value):
	is_disabled = value
	check_num_bodies()

func _on_Area2D_body_entered(_body):
	num_bodies += 1
	check_num_bodies()

func _on_Area2D_body_exited(_body):
	num_bodies -= 1
	check_num_bodies()