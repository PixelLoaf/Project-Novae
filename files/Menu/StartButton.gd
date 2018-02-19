extends Button
export(String, FILE, "*.tscn") var target_scene;

func _ready():
	connect("pressed", self, "on_pressed")
	
func on_pressed():
	get_tree().change_scene_to(load(target_scene));
