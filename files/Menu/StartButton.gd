extends Button
export(String, FILE, "*.tscn") var target_scene;

func _ready():
	var err = connect("pressed", self, "on_pressed")
	if err != OK:
		Util.print_error(err, "Could not connect signal")
	
func on_pressed():
	var err = get_tree().change_scene_to(load(target_scene))
	if err != OK:
		Util.print_error(err, "could not load scene")
