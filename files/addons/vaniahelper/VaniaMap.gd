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

# All tiles within this map.
# Keys represent the position of the tile as an integer Vector2
# Values are instances of the Tile class
var tiles = {}
# Width of each tile in pixels
var room_width = 1024
# Height of each tile in pixels
var room_height = 600

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
		"version": VERSION
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