tool
extends VBoxContainer

var dialog
onready var layout = preload("Layout.tscn")
var should_change_path = false
var create_new_editor = false
var overwrite_file = false
var should_save = false

func check_dialog():
	if dialog == null:
		dialog = EditorFileDialog.new()
		dialog.set_access(EditorFileDialog.ACCESS_RESOURCES)
		dialog.set_display_mode(EditorFileDialog.DISPLAY_LIST)
		dialog.connect("file_selected", self, "_on_EditorFileDialog_selected")
		dialog.add_filter("*.vmap; Vania Map")
		add_child(dialog)

func enable_dialog(mode, base_dir):
	if mode == EditorFileDialog.MODE_SAVE_FILE:
		dialog.disable_overwrite_warning = false
	else:
		dialog.disable_overwrite_warning = true
	dialog.set_mode(mode)
	dialog.current_dir = ""
	dialog.current_file = ""
	dialog.current_path = base_dir
	dialog.popup_centered()
	
func get_current_editor():
	if $TabContainer.get_tab_count() == 0:
		return null
	return $TabContainer.get_current_tab_control()

func _enter_tree():
	check_dialog()
	
func _on_EditorFileDialog_selected(path):
	print(path)
	var fh = File.new()
	var do_load_file = false
	if fh.file_exists(path):
		if overwrite_file:
			pass # TODO: WARN ABOUT OVERWRITING FILE
		else:
			do_load_file = true
	else:
		if not overwrite_file:
			print("File \"%s\" is to be loaded, but it does not exist!" % path)
			return
	var editor
	if create_new_editor:
		editor = layout.instance()
	else:
		editor = get_current_editor()
		if editor == null:
			print("No existing editor!")
			return
	if should_change_path:
		editor.set_file(path)
	if should_save:
		editor.file_save_as(path)
	if do_load_file:
		editor.file_load()
	if create_new_editor:
		$TabContainer.add_child(editor)
		$TabContainer.current_tab = $TabContainer.get_tab_count() - 1
		editor.set_owner($TabContainer)
	$TabContainer.set_tab_title($TabContainer.current_tab, editor.get_title())

func _on_ButtonNew_pressed():
	should_change_path = true
	create_new_editor = true
	overwrite_file = true
	should_save = false
	enable_dialog(EditorFileDialog.MODE_SAVE_FILE, "res://")

func _on_ButtonLoad_pressed():
	should_change_path = true
	create_new_editor = true
	overwrite_file = false
	should_save = false
	enable_dialog(EditorFileDialog.MODE_OPEN_FILE, "res://")

func _on_ButtonSave_pressed():
	var node = get_current_editor()
	if node == null:
		return
	node.file_save()

func _on_ButtonSaveAs_pressed():
	should_change_path = true
	create_new_editor = false
	overwrite_file = true
	should_save = true
	var node = get_current_editor()
	if node == null:
		return
	enable_dialog(EditorFileDialog.MODE_SAVE_FILE, "res://")

func _on_ButtonSaveACopy_pressed():
	should_change_path = false
	create_new_editor = false
	overwrite_file = true
	should_save = true
	var node = get_current_editor()
	if node == null:
		return
	enable_dialog(EditorFileDialog.MODE_SAVE_FILE, "res://")

func _on_ButtonClose_pressed():
	var node = get_current_editor()
	if node == null:
		return
	node.file_close()
