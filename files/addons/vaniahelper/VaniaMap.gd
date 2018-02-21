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
	# Calculate nearby tiles
	# Returns an array of tiles that are next to this tile
	func calculate_nearby(map):
		var ret = []
		var pos = Vector2(self.position.x, self.position.y - 1)
		while pos.x < self.position.x + self.width:
			var tile = map.get_tile(pos)
			if tile != null:
				ret.append(tile)
				pos.x += tile.width
			else:
				pos.x += 1
		pos = Vector2(self.position.x, self.position.y + self.height)
		while pos.x < self.position.x + self.width:
			var tile = map.get_tile(pos)
			if tile != null:
				ret.append(tile)
				pos.x += tile.width
			else:
				pos.x += 1
		pos = Vector2(self.position.x - 1, self.position.y)
		while pos.y < self.position.y + self.height:
			var tile = map.get_tile(pos)
			if tile != null:
				ret.append(tile)
				pos.y += tile.height
			else:
				pos.y += 1
		pos = Vector2(self.position.x + self.width, self.position.y)
		while pos.y < self.position.y + self.height:
			var tile = map.get_tile(pos)
			if tile != null:
				ret.append(tile)
				pos.y += tile.height
			else:
				pos.y += 1
		return ret

# Tiles within the map
var tile_list = []
# Maps positions to tiles
var tile_map = {}
# Width of each tile in pixels
var room_width = 1024
# Height of each tile in pixels
var room_height = 600
# Rooms which have been loaded
var loaded_rooms = {}

# Load a room into this map
func load_room(tile):
	if not tile in loaded_rooms:
		var x = tile.position.x * room_width
		var y = tile.position.y * room_height
		var room = load(tile.path).instance()
		room.position = Vector2(x, y)
		add_child(room)
		loaded_rooms[tile] = room

# Unload a room from this maps
func unload_room(tile):
	if tile in loaded_rooms:
		loaded_rooms[tile].queue_free()
		loaded_rooms.erase(tile)

# Convert a position to a valid key for a Vaniamap
func pos_to_tilepos(pos):
	pos.x /= room_width
	pos.y /= room_height
	return pos.floor()

# Inverse of pos_to_key
func tilepos_to_pos(pos):
	pos.x *= room_width
	pos.y *= room_height
	return pos

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
				_set_tile(gridpos, null)
	return tile

# Returns true if the tile at the given position can move to another location
func can_move_tile(pos_from, pos_to, exceptions=null):
	var tile = get_tile(pos_from)
	if tile == null:
		return false
	for ix in range(pos_to.x, pos_to.x + tile.width):
		for iy in range(pos_to.y, pos_to.y + tile.height):
			var other = get_tile(Vector2(ix, iy))
			if other != null && other != tile:
				if exceptions == null or not other in exceptions:
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

# move the given tiles by offset
func move_tiles(tiles, offset):
	if tiles.empty() or offset == Vector2():
		return false
	for tile in tiles:
		if not can_move_tile(tile.position, tile.position + offset, tiles):
			return false
	for tile in tiles:
		_pop_tile(tile.position)
	for tile in tiles:
		_push_tile(tile.position+offset, tile)
	return true

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

# Set the width of the given tile
# Returns the new width of the tile
# If there is no tile at the given position, returns 0
func tile_set_width(pos, new_width):
	new_width = clamp(new_width, 1, MAX_SIZE)
	var tile = get_tile(pos)
	if tile == null:
		return 0
	while tile.width < new_width:
		var test_x = tile.position.x + tile.width
		for iy in range(tile.position.y, tile.position.y + tile.height):
			if get_tile(Vector2(test_x, iy)) != null:
				return tile.width
		tile.width += 1
		for iy in range(tile.position.y, tile.position.y + tile.height):
			_set_tile(Vector2(test_x, iy), tile)
	while tile.width > new_width:
		for iy in range(tile.position.y, tile.position.y + tile.height):
			_set_tile(Vector2(tile.position.x + tile.width - 1, iy), null)
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
		var test_y = tile.position.y + tile.height
		for ix in range(tile.position.x, tile.position.x + tile.width):
			if get_tile(Vector2(ix, test_y)) != null:
				return tile.height
		tile.height += 1
		for ix in range(tile.position.x, tile.position.x + tile.width):
			_set_tile(Vector2(ix, test_y), tile)
	while tile.height > new_height:
		for ix in range(tile.position.x, tile.position.x + tile.width):
			_set_tile(Vector2(ix, tile.position.y + tile.height - 1), null)
		tile.height -= 1
	return tile.height

# Get all tile connections.
# Keys are a reference to the tile
# Values are an array of tile references
func get_tile_connections():
	var ret = {}
	for tile in tile_list:
		var connections = tile.calculate_nearby(self)
		ret[tile] = connections
	return ret

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
		v.id = new_tiles.size()
		new_tiles.append(v)
	room_width = data.width
	room_height = data.height
	tile_list = new_tiles
	for tile in loaded_rooms:
		unload_room(tile)
	loaded_rooms.clear()
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