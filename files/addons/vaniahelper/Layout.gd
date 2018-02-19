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

# File name for this editor
var file_name = "";
# Reference to the VaniaMap node
var vaniamap
# Position of the actively selected tile. Null if none selected
var active_tile_key
# File load dialog
var dialog
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
	if vaniamap.tiles.has(active_tile_key):
		return vaniamap.tiles[active_tile_key]
	return null

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

# Called when 
func _on_EditorFileDialog_selected(path):
	if get_active_tile() == null:
		print("No active tile!")
	$HSplitContainer/Properties/Path.text = path

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

func pos_to_key(pos):
	return (pos / TILE_SIZE).floor()

func try_move_tile(prev_pos, target_pos):
	if prev_pos == target_pos:
		return
	if not vaniamap.tiles.has(prev_pos):
		return false
	if vaniamap.tiles.has(target_pos):
		var tile_a = vaniamap.tiles[prev_pos]
		var tile_b = vaniamap.tiles[target_pos]
		vaniamap.tiles[prev_pos] = tile_b
		vaniamap.tiles[target_pos] = tile_a
		return true
	else:
		vaniamap.tiles[target_pos] = vaniamap.tiles[prev_pos]
		vaniamap.tiles.erase(prev_pos)
		return true

func _init():
	vaniamap = preload("VaniaMap.gd").new()
	add_child(vaniamap)
	check_dialog()

func _ready():
	set_active_tile(null)

func _exit_tree():
	vaniamap.free()

func get_title():
	return file_name.get_file()

func file_close():
	queue_free()

func set_file(name):
	file_name = name

func file_save_as(path):
	vaniamap.save_to(path)
	
func file_save():
	file_save_as(file_name)

func file_load():
	vaniamap.load_from(file_name)

func _on_Panel_draw():
	for pos in vaniamap.tiles:
		var tile = vaniamap.tiles[pos]
		var size = Vector2(tile.width, tile.height)
		var rect = Rect2(pos * TILE_SIZE, size * TILE_SIZE)
		rect = rect.grow(-TILE_PAD)
		var outline = TILE_OUTLINE
		if pos == active_tile_key:
			outline = TILE_OUTLINE_SELECTED
			if is_dragging:
				rect.position += drag_offset
		canvas.draw_rect(rect, outline, true)
		rect = rect.grow(-TILE_BORDER)
		canvas.draw_rect(rect, tile.color, true)

func _on_Panel_gui_input(event):
	if event is InputEventMouseMotion:
		if is_dragging:
			drag_offset += event.relative
			canvas.update()
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			if event.pressed:
				var pos = pos_to_key(event.position)
				print(pos)
				if vaniamap.tiles.has(pos):
					set_active_tile(pos)
				else:
					set_active_tile(null)
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

func _on_Color_color_changed(color):
	var tile = get_active_tile()
	if tile == null:
		return
	tile.color = color
	canvas.update()

func _on_Path_text_changed(new_text):
	var tile = get_active_tile()
	if tile == null:
		return
	tile.path = new_text

func _on_PathButton_pressed():
	var tile = get_active_tile()
	if tile == null:
		return
	dialog.current_file = tile.path.get_file()
	dialog.current_dir = tile.path.get_base_dir()
	dialog.current_path = tile.path
	dialog.popup_centered()
