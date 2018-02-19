tool
extends EditorPlugin

var control

func _enter_tree():
	add_custom_type("VaniaMap", "Node", preload("VaniaMap.gd"), preload("img/icon.png"))
	control = preload("Designer.tscn").instance()
	add_control_to_bottom_panel(control, "Vania Designer")

func _exit_tree():
	remove_control_from_bottom_panel(control)
	control.free()
	remove_custom_type("VaniaMap")