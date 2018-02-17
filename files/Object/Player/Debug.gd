extends Node2D

onready var player = get_parent();
onready var panel = $CanvasLayer/PlayerInfo

const VELOC_BASE = 0.05
const VELOC_SCALE = 0.05

func _input(event):
	if event.is_action_pressed("hide_debug"):
		if visible:
			hide()
			panel.hide()
		else:
			show()
			panel.show()

func _physics_process(delta):
	if not visible:
		return
	var offset_angle = player.rotation
	$Normal.rotation = player.char_get_normal().angle() + PI/2 - offset_angle
	var scale = VELOC_BASE * player.char_velocity.length() * VELOC_SCALE
	if scale == 0:
		$Velocity.hide()
	else:
		$Velocity.show()
		$Velocity.scale = Vector2(scale, 0.25)
		$Velocity.rotation = player.char_velocity.angle() - offset_angle
	panel.get_node("XPos").text = "%.2f" % player.position.x
	panel.get_node("YPos").text = "%.2f" % player.position.y
	panel.get_node("XVel").text = "%.2f" % player.char_velocity.x
	panel.get_node("YVel").text = "%.2f" % player.char_velocity.y

func _on_Button_pressed():
	player.rotation += PI/2
	$CanvasLayer/PlayerInfo/ButtonRotate.release_focus()
