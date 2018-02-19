tool
extends Node

# Version
const VERSION = "1.0"
# Maximum size of a single tile
const MAX_SIZE = 32

# Represents a singular tile
class Tile:
	# ID of this tile
	var id = 0
	# Color of this tile
	var color = Color(0.5, 0.5, 0.5, 1)
	# Path to the scene for this tile
	var path = ""
	# Width of this tile
	var width = 1
	# Height of this tile
	var height = 1
	# Position of this tile
	var position = Vector2()

# Tiles within the map
var tile_list = []
# Maps positions to tiles
var tile_map = {}
# Width of each tile in pixels
var room_width = 1024
# Height of each tile in pixels
var room_height = 600
# Total size of this map
var total_size = Vector2()

func update_size():
	total_size = Vector2()
	for pos in tile_map:
		total_size.x = max(total_size.x, pos.x)
		total_size.y = max(total_size.y, pos.y)
	total_size.x += 1
	total_size.y += 1

func get_size():
	return total_size

# Get the tile at the given position
func get_tile(pos):
	if tile_map.has(pos):
		return tile_map[pos]
	return null

# Set the tile at the given position
func _set_tile(pos, tile):
	if tile == null:
		tile_map.erase(pos)
	else:
		tile_map[pos] = tile
	update_size()

# Put a tile into the map with regards to its width and height
func _push_tile(pos, tile):
	if tile == null:
		return
	tile.position = pos
	for ix in range(tile.position.x, tile.position.x + tile.width):
		for iy in range(tile.position.y, tile.position.y + tile.height):
			_set_tile(Vector2(ix, iy), tile)

# Remove tile from grid and return it
func _pop_tile(pos):
	var tile = get_tile(pos)
	if tile == null:
		return null
	for ix in range(tile.position.x, tile.position.x + tile.width):
		for iy in range(tile.position.y, tile.position.y + tile.height):
			var gridpos = Vector2(ix, iy)
			var t = get_tile(gridpos)
			if t == tile:
				_set_tile(pos, null)
	tile.position = null
	return tile

# Returns true if the tile at the given position can move to another location
func can_move_tile(pos_from, pos_to):
	var tile = get_tile(pos_from)
	if tile == null:
		return false
	for ix in range(pos_to.x, pos_to.x + tile.width):
		for iy in range(pos_to.y, pos_to.y + tile.height):
			var other = get_tile(Vector2(ix, iy))
			if other != null && other != tile:
				return false
	return true

# Delate the tile at the given position
func delete_tile(pos):
	var tile = _pop_tile(pos)
	if tile == null:
		return false
	tile_list.remove(tile.id)
	for i in range(tile.id, tile_list.size()):
		tile_list[i].id -= 1
	return true

# Move the given tile at the given position to another location
func move_tile(pos_from, pos_to):
	if can_move_tile(pos_from, pos_to):
		var tile = _pop_tile(pos_from)
		_push_tile(pos_to, tile)
		return true
	return false

# Create a new tile at the tiven position
func create_tile(pos, color=null, path=null):
	if get_tile(pos) != null:
		return null
	var tile = Tile.new()
	tile.id = tile_list.size()
	if color != null:
		tile.color = color
	if path != null:
		tile.path = path
	tile_list.append(tile)
	_push_tile(pos, tile)
	return tile

# Get the base position of the given tile
func get_base_position(pos):
	if pos == null:
		return null
	var tile = get_tile(pos)
	if tile == null:
		return pos
	else:
		return tile.position

# Set the width of the given tile
# Returns the new width of the tile
# If there is no tile at the given position, returns 0
func tile_set_width(pos, new_width):
	new_width = clamp(new_width, 1, MAX_SIZE)
	var tile = get_tile(pos)
	if tile == null:
		return 0
	while tile.width < new_width:
		var test_x = tile.position.x + tile.width + 1
		for iy in range(tile.position.y, tile.position.y + tile.height):
			if get_tile(Vector2(test_x, iy)) != null:
				return tile.width
		tile.width += 1
		for iy in range(tile.position.y, tile.position.y + tile.height):
			_set_tile(Vector2(test_x, iy), tile)
	while tile.width > new_width:
		for iy in range(tile.position.y, tile.position.y + tile.height):
			_set_tile(Vector2(tile.position.x + tile.width, iy), null)
		tile.width -= 1
	return tile.width

# Set the height of the given tile
# Returns the new height of the tile
# If there is no tile at the given position, returns 0
func tile_set_height(pos, new_height):
	new_height = clamp(new_height, 1, MAX_SIZE)
	var tile = get_tile(pos)
	if tile == null:
		return 0
	while tile.height < new_height:
		var test_y = tile.position.y + tile.height + 1
		for ix in range(tile.position.x, tile.position.x + tile.width):
			if get_tile(Vector2(ix, test_y)) != null:
				return tile.height
		tile.height += 1
		for ix in range(tile.position.x, tile.position.x + tile.width):
			_set_tile(Vector2(ix, test_y), tile)
	while tile.height > new_height:
		for ix in range(tile.position.x, tile.position.x + tile.width):
			_set_tile(Vector2(ix, tile.position.y + tile.height), null)
		tile.height -= 1
	return tile.height

# Save this map to the given file
func save_to(path):
	var tiledata = []
	for tile in tile_list:
		var data = {
			"x": tile.position.x,
			"y": tile.position.y,
			"color": tile.color.to_html(),
			"path": tile.path,
			"width": tile.width,
			"height": tile.height
		}
		tiledata.append(data)
	var data = {
		"tiles": tiledata,
		"version": VERSION,
		"width": room_width,
		"height": room_height
	}
	
	var outstr = JSON.print(data, "    ", true)
	var fh = File.new()
	fh.open(path, File.WRITE)
	fh.store_line(outstr)
	fh.close()

# Load for version 1.0
func load_from_v1_0(data):
	var new_tiles = []
	for tile in data.tiles:
		var pos = Vector2(tile.x, tile.y).floor()
		var v = Tile.new()
		v.color = Color(tile.color)
		v.width = int(tile.width)
		v.height = int(tile.height)
		v.path = tile.path
		v.position = pos
		new_tiles.append(v)
	room_width = data.width
	room_height = data.height
	tile_list = new_tiles
	tile_map.clear()
	for tile in tile_list:
		_push_tile(tile.position, tile)

# Load a map from the given file
func load_from(path):
	var fh = File.new()
	if not fh.file_exists(path):
		print("ERROR: file \"%s\" does not exist!" % path)
		return ERR_DOES_NOT_EXIST
	fh.open(path, File.READ)
	var text = fh.get_as_text()
	var data = parse_json(text)
	load_from_v1_0(data)
	fh.close()
	return OK