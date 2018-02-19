tool
extends Node

const VERSION = "1.0"

# Represents a singular tile
class Tile:
	# Color of this tile
	var color = Color(0.5, 0.5, 0.5, 1)
	# Path to the scene for this tile
	var path = ""
	# Width of this tile
	var width = 1
	# Height of this tile
	var height = 1

# All tiles within this map. There are no duplicates.
# Keys represent the position of the tile as an integer Vector2
# Values are instances of the Tile class
var tiles = {}
# Width of each tile in pixels
var room_width = 1024
# Height of each tile in pixels
var room_height = 600

var total_size = Vector2()

func update_size():
	total_size = Vector2()
	for pos in tiles:
		total_size.x = max(total_size.x, pos.x)
		total_size.y = max(total_size.y, pos.y)
	total_size.x += 1
	total_size.y += 1

func get_size():
	return total_size

func get_tile(pos):
	if tiles.has(pos):
		return tiles[pos]
	return null

func set_tile(pos, value):
	if value == null:
		self.tiles.erase(pos)
	else:
		self.tiles[pos] = value
	update_size()

func swap_tiles(a, b):
	if a == b:
		return
	var tile_a = get_tile(a)
	var tile_b = get_tile(b)
	if tile_a == tile_b:
		return false
	set_tile(b, tile_a)
	set_tile(a, tile_b)
	return true

# Save this map to the given file
func save_to(path):
	var tiledata = []
	for k in tiles:
		var tile = tiles[k]
		var data = {
			"x": k.x,
			"y": k.y,
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
	var new_tiles = {}
	for tile in data.tiles:
		var k = Vector2(tile.x, tile.y).snapped(Vector2(1, 1))
		var v = Tile.new()
		v.color = Color(tile.color)
		v.width = int(tile.width)
		v.height = int(tile.height)
		v.path = tile.path
		new_tiles[k] = v
	room_width = data.width
	room_height = data.height
	tiles = new_tiles

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