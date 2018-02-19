tool
extends Control

const TILE_SIZE_ARRAY = [8, 12, 16, 24, 32, 48, 64]
var tile_size_i = TILE_SIZE_ARRAY.find(32)

# Size of a tile
var TILE_SIZE = 32
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
# List of selected tiles
var selected_tiles = []
# Currently selected position
var selected_pos = Vector2()
# File load dialog
var dialog
# Output path of the dialog
var dialog_path
# Last selected color
var last_color = Color(0.5, 0.5, 0.5)
# Whether the active tile is being dragged
var is_dragging = false
# Offset of the tile being dragged
var drag_offset = Vector2(0, 0)
# Position of drag start
var drag_start_pos = Vector2(0, 0)
# True if the window is being scrolled
var is_scrolling = false
# Scroll amount
var scroll_amount = Vector2()

# Reference to the panel node
onready var canvas = $HSplitContainer/ScrollContainer/Panel
# Reference to the properties node
onready var properties = $HSplitContainer/Properties

# Get the currently selected tile. Will return null if no tile is selected
#func get_active_tile():
#	if active_tile_key == null:
#		return null
#	return vaniamap.get_tile(active_tile_key)

# Make sure that the dialog node exists
func check_dialog():
	if dialog == null:
		dialog = EditorFileDialog.new()
		dialog.set_access(EditorFileDialog.ACCESS_RESOURCES)
		dialog.set_display_mode(EditorFileDialog.DISPLAY_LIST)
		dialog.set_mode(EditorFileDialog.MODE_OPEN_FILE)
		dialog.connect("file_selected", self, "_on_EditorFileDialog_selected")
		dialog.connect("popup_hide", self, "_on_EditorFileDialog_hide")
		dialog.add_filter("*.tscn, *.scn; Scene")
		add_child(dialog)

# Called when a path is selected via the dialog
func _on_EditorFileDialog_selected(path):
	dialog_path = path
	
func _on_EditorFileDialog_hide():
	emit_signal("dialog_wait")

# Add an active tile
func add_active_tile(pos, reset=false):
	selected_pos = pos
	var tile = vaniamap.get_tile(pos)
	if pos == null:
		$PosLabel.text = ""
	else:
		$PosLabel.text = "%d, %d" % [pos.x, pos.y]
	if tile != null and tile in selected_tiles:
		return
	if reset:
		selected_tiles.clear()
	if tile != null:
		selected_tiles.append(tile)
		properties.show()
		$HSplitContainer/Properties/Color.color = tile.color
		$HSplitContainer/Properties/Path.text = tile.path
		$HSplitContainer/Properties/Width.value = tile.width
		$HSplitContainer/Properties/Height.value = tile.height
	else:
		properties.hide()
	if selected_tiles.size() > 1:
		$HSplitContainer/Properties/Path.hide()
		$HSplitContainer/Properties/Width.hide()
		$HSplitContainer/Properties/Height.hide()
		$HSplitContainer/Properties/LabelPath.hide()
		$HSplitContainer/Properties/PathButton.hide()
		$HSplitContainer/Properties/LabelWidth.hide()
		$HSplitContainer/Properties/LabelHeight.hide()
	else:
		$HSplitContainer/Properties/Path.show()
		$HSplitContainer/Properties/Width.show()
		$HSplitContainer/Properties/Height.show()
		$HSplitContainer/Properties/LabelPath.show()
		$HSplitContainer/Properties/PathButton.show()
		$HSplitContainer/Properties/LabelWidth.show()
		$HSplitContainer/Properties/LabelHeight.show()
	canvas.update()

# Convert a position to a valid key for a Vaniamap
func pos_to_key(pos):
	return ((pos - scroll_amount) / TILE_SIZE).floor()

# Attempt to move a tile from prev_pos to target_pos
func try_move_tile(prev_pos, target_pos):
	return vaniamap.move_tile(prev_pos, target_pos)

# When this editor is created
func _init():
	vaniamap = preload("VaniaMap.gd").new()
	add_child(vaniamap)
	check_dialog()

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
	var rect = Rect2(pos * TILE_SIZE + scroll_amount, size * TILE_SIZE)
	rect = rect.grow(-TILE_PAD)
	var outline = TILE_OUTLINE
	if tile == null or tile in selected_tiles:
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
	for tile in vaniamap.tile_list:
		if not tile in selected_tiles:
			var pos = tile.position
			tile_draw(pos, tile)
	if not selected_tiles.empty():
		for tile in selected_tiles:
			tile_draw(tile.position, tile)
	else:
		tile_draw(selected_pos, null)

# Scroll the view by 'amount' increments
func scroll(amount, pos):
	var pos_before = (pos - scroll_amount) / TILE_SIZE
	tile_size_i = clamp(tile_size_i + amount, 0, TILE_SIZE_ARRAY.size()-1)
	TILE_SIZE = TILE_SIZE_ARRAY[tile_size_i]
	var pos_after = (pos - scroll_amount) / TILE_SIZE
	scroll_amount += (pos_after - pos_before) * TILE_SIZE
	canvas.update()

# Delete the currently selected tile
func delete_selected():
	for tile in selected_tiles:
		vaniamap.delete_tile(tile.position)
		canvas.update()
	selected_tiles.clear()

# Begin dragging active tile
func begin_drag(pos):
	if not selected_tiles.empty():
		drag_offset = Vector2(0, 0)
		is_dragging = true
		drag_start_pos = pos_to_key(pos)

# Place active tile
func end_drag(pos):
	if is_dragging:
		is_dragging = false
		var to_pos = pos_to_key(pos)
		var offset = to_pos - drag_start_pos
		if vaniamap.move_tiles(selected_tiles, offset):
			add_active_tile(to_pos, false)
		else:
			add_active_tile(selected_pos, false)
		canvas.update()

# When the canvas receives an input
func _on_Panel_gui_input(event):
	if event is InputEventMouseMotion:
		if is_dragging:
			drag_offset += event.relative
			canvas.update()
			var pos = pos_to_key(event.position)
			$PosLabel.text = "%d, %d" % [pos.x, pos.y]
		if is_scrolling:
			scroll_amount += event.relative
			canvas.update()
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			if is_scrolling:
				return
			if event.pressed:
				var pos = pos_to_key(event.position)
				add_active_tile(pos, not event.shift)
				begin_drag(event.position)
			else:
				end_drag(event.position)
			accept_event()
		if event.button_index == BUTTON_MIDDLE:
			if is_dragging:
				return
			is_scrolling = event.pressed
		if event.button_index == BUTTON_RIGHT and event.pressed:
			var pos = pos_to_key(event.position)
			add_active_tile(pos, true)
			show_popup(event.global_position)
			accept_event()
		if event.button_index == BUTTON_WHEEL_UP and event.pressed:
			scroll(1, event.position)
			accept_event()
		if event.button_index == BUTTON_WHEEL_DOWN and event.pressed:
			scroll(-1, event.position)
			accept_event()
	if event is InputEventKey:
		if event.scancode == KEY_DELETE:
			delete_selected()
			accept_event()

# When a color is selected
func _on_Color_color_changed(color):
	for tile in selected_tiles:
		tile.color = color
	canvas.update()

# When the path changes
func _on_Path_text_changed(new_text):
	for tile in selected_tiles:
		tile.path = new_text

# When the change path button is pressed
func _on_PathButton_pressed():
	if selected_tiles.size() != 1:
		return
	var tile = selected_tiles[0]
	dialog.current_file = tile.path.get_file()
	dialog.current_dir = tile.path.get_base_dir()
	dialog.current_path = tile.path
	dialog.popup_centered()
	yield(self, "dialog_wait")
	$HSplitContainer/Properties/Path.text = dialog_path

const POPUP_NEW = 0
const POPUP_DELETE = 1
# When a popup menu's button is pressed
func _on_PopupMenu_id_pressed( ID ):
	if ID == POPUP_NEW:
		dialog.current_file = ""
		dialog.popup_centered()
		yield(self, "dialog_wait")
		var tile = vaniamap.create_tile(selected_pos, last_color, dialog_path)
		if tile != null:
			add_active_tile(tile.position)
		canvas.update()
	elif ID == POPUP_DELETE:
		delete_selected()

# Show the context menu
func show_popup(pos):
	var tile = vaniamap.get_tile(selected_pos)
	if tile == null:
		$PopupMenu.set_item_disabled($PopupMenu.get_item_index(POPUP_NEW), false)
	else:
		$PopupMenu.set_item_disabled($PopupMenu.get_item_index(POPUP_NEW), true)
	if selected_tiles.empty():
		$PopupMenu.set_item_disabled($PopupMenu.get_item_index(POPUP_DELETE), true)
	else:
		$PopupMenu.set_item_disabled($PopupMenu.get_item_index(POPUP_DELETE), false)
	$PopupMenu.rect_position = pos
	$PopupMenu.popup()

func _on_Width_value_changed(value):
	if selected_tiles.size() != 1:
		return
	value = vaniamap.tile_set_width(selected_tiles[0].position, value)
	$HSplitContainer/Properties/Width.value = value
	canvas.update()

func _on_Height_value_changed(value):
	if selected_tiles.size() != 1:
		return
	value = vaniamap.tile_set_height(selected_tiles[0].position, value)
	$HSplitContainer/Properties/Height.value = value
	canvas.update()
