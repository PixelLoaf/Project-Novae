extends Sprite

func _ready():
	_on_Face_frame_changed()

func _on_Face_frame_changed():
	for node in get_tree().get_nodes_in_group("weird-face"):
		node.frame = frame