tool
extends Control

# Size of a tile
const TILE_SIZE = 32
# Padding between tiles
const TILE_PAD = 0
# Width of a tile's border
const TILE_BORDER = 2
# Color of a tile's outline
const TILE_OUTLINE = Color(0, 0, 0)
# Color of a tile's outline when it is selected
const TILE_OUTLINE_SELECTED = Color(1, 1, 1)

# Signal that is called when a file is chosen
signal dialog_wait

# File name for this editor
var file_name = "";
# Reference to the VaniaMap node
var vaniamap
# Position of the actively selected tile. Null if none selected
var active_tile_key
# File load dialog
var dialog
# Output path of the dialog
var dialog_path
# Whether the active tile is being dragged
var is_dragging = false
# Offset of the tile being dragged
var drag_offset = Vector2(0, 0)

# Reference to the panel node
onready var canvas = $HSplitContainer/ScrollContainer/Panel
# Reference to the properties node
onready var properties = $HSplitContainer/Properties

# Get the currently selected tile. Will return null if no tile is selected
func get_active_tile():
	if active_tile_key == null:
		return null
	return vaniamap.get_tile(active_tile_key)

# Make sure that the dialog node exists
func check_dialog():
	if dialog == null:
		dialog = EditorFileDialog.new()
		dialog.set_access(EditorFileDialog.ACCESS_RESOURCES)
		dialog.set_display_mode(EditorFileDialog.DISPLAY_LIST)
		dialog.set_mode(EditorFileDialog.MODE_OPEN_FILE)
		dialog.connect("file_selected", self, "_on_EditorFileDialog_selected")
		dialog.add_filter("*.tscn, *.scn; Scene")
		add_child(dialog)

# Called when a path is selected via the dialog
func _on_EditorFileDialog_selected(path):
	dialog_path = path
	emit_signal("dialog_wait")

# Set the active tile
func set_active_tile(pos):
	active_tile_key = pos
	var tile = get_active_tile()
	if tile != null:
		properties.show()
		$HSplitContainer/Properties/Color.color = tile.color
		$HSplitContainer/Properties/Path.text = tile.path
	else:
		properties.hide()
	canvas.update()

# Convert a position to a valid key for a Vaniamap
func pos_to_key(pos):
	return (pos / TILE_SIZE).floor()

# Attempt to move a tile from prev_pos to target_pos
func try_move_tile(prev_pos, target_pos):
	return vaniamap.swap_tiles(prev_pos, target_pos)

# When this editor is created
func _init():
	vaniamap = preload("VaniaMap.gd").new()
	add_child(vaniamap)
	check_dialog()

# Whent his editor is ready
func _ready():
	set_active_tile(null)

# When this editor leaves the tree
func _exit_tree():
	vaniamap.free()

# Get this editor's title
func get_title():
	return file_name.get_file()

# Close this editor
func file_close():
	queue_free()

# Set this editor's file name
func set_file(name):
	file_name = name

# Save the map as a different file
func file_save_as(path):
	vaniamap.save_to(path)

# Save the map
func file_save():
	file_save_as(file_name)

# Load data from the map
func file_load():
	vaniamap.load_from(file_name)

# Draw a tile
func tile_draw(pos, tile):
	var size = Vector2(1, 1)
	if tile != null:
		size = Vector2(tile.width, tile.height)
	var rect = Rect2(pos * TILE_SIZE, size * TILE_SIZE)
	rect = rect.grow(-TILE_PAD)
	var outline = TILE_OUTLINE
	if pos == active_tile_key:
		outline = TILE_OUTLINE_SELECTED
		if is_dragging:
			rect.position += drag_offset
	if tile != null:
		canvas.draw_rect(rect, outline, true)
	else:
		canvas.draw_rect(rect, outline, false)
	rect = rect.grow(-TILE_BORDER)
	if tile != null:
		canvas.draw_rect(rect, tile.color, true)

# When the canvas draws
func _on_Panel_draw():
	for pos in vaniamap.tiles:
		var tile = vaniamap.tiles[pos]
		if pos != active_tile_key:
			tile_draw(pos, tile)
	if active_tile_key != null:
		var tile = get_active_tile()
		tile_draw(active_tile_key, tile)


# When the canvas receives an input
func _on_Panel_gui_input(event):
	if event is InputEventMouseMotion:
		if is_dragging:
			drag_offset += event.relative
			canvas.update()
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			if event.pressed:
				var pos = pos_to_key(event.position)
				set_active_tile(pos)
				drag_offset = Vector2(0, 0)
				is_dragging = true
			else:
				is_dragging = false
				var from_pos = active_tile_key
				var to_pos = pos_to_key(event.position)
				if try_move_tile(from_pos, to_pos):
					set_active_tile(to_pos)
				canvas.update()
			accept_event()
	if event is InputEventKey:
		if event.scancode == KEY_DELETE:
			pass
			# delete tile

# When a color is selected
func _on_Color_color_changed(color):
	var tile = get_active_tile()
	if tile == null:
		return
	tile.color = color
	canvas.update()

# When the path changes
func _on_Path_text_changed(new_text):
	var tile = get_active_tile()
	if tile == null:
		return
	tile.path = new_text

# When the change path button is pressed
func _on_PathButton_pressed():
	var tile = get_active_tile()
	if tile == null:
		return
	dialog.current_file = tile.path.get_file()
	dialog.current_dir = tile.path.get_base_dir()
	dialog.current_path = tile.path
	dialog.popup_centered()
	yield(self, "dialog_wait")
	if get_active_tile() == null:
		print("No active tile!")
	$HSplitContainer/Properties/Path.text = dialog_path
