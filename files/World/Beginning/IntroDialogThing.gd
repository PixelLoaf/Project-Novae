extends Sprite

var screenshake = 0
var do_screenshake = false
onready var camera = $"../Camera2D"

func _ready():
	var err = $Dialog.connect("on_dialog_over", self, "_on_dialog_over")
	if err != OK:
		Util.print_error(err, "Could not connect signal")
	
func _process(delta):
	if do_screenshake:
		screenshake += delta * 10
	var rand_angle = rand_range(0, PI*2)
	camera.offset = Vector2(0, rand_range(0, 1)).rotated(rand_angle) * screenshake

func _on_dialog_over(_state):
	$Dialog.set_disabled(true)
	$"../AnimationPlayer".play("Anim")
	do_screenshake = true

func change_level():
	var err = get_tree().change_scene_to(load("res://World/Beginning/World.tscn"));
	if err != OK:
		Util.print_error(err, "Could not connect signal")