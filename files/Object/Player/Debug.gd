extends Node2D

onready var player = get_parent().get_parent();
onready var panel = $Panel;
onready var label_xpos = panel.get_node("XPos")
onready var label_ypos = panel.get_node("YPos")
onready var label_xvel = panel.get_node("XVel")
onready var label_yvel = panel.get_node("YVel")

const VELOC_BASE = 0.05
const VELOC_SCALE = 0.05

func _input(event):
	if event.is_action_pressed("hide_debug"):
		if visible:
			hide()
		else:
			show()

func _physics_process(delta):
	if not visible:
		return
	panel.show_on_top = true
	$Normal.rotation = player.char_get_normal().angle() + PI/2
	label_xpos.text = "%.2f" % player.position.x
	label_ypos.text = "%.2f" % player.position.y
	label_xvel.text = "%.2f" % player.char_velocity.x
	label_yvel.text = "%.2f" % player.char_velocity.y
	var scale = VELOC_BASE * player.char_velocity.length() * VELOC_SCALE
	if scale == 0:
		$Velocity.hide()
	else:
		$Velocity.show()
		$Velocity.scale = Vector2(scale, 0.25)
		$Velocity.rotation = player.char_velocity.angle()
