extends Area2D

var bodies = []
onready var radius = $CollisionShape2D.shape.radius

func _physics_process(delta):
	var max_distance = radius * 2
	for body in bodies:
		var push_direction = (body.global_position - global_position).normalized()
		var difference = (global_position - body.global_position).length()
		var push_amount = max_distance - difference + radius
		body.char_apply_force(push_direction * push_amount * delta * 80)

func _on_Push_area_entered(area):
	var body = area.get_parent()
	bodies.append(body)

func _on_Push_area_exited(area):
	var body = area.get_parent()
	bodies.erase(body)
