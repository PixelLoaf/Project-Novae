tool
extends Node

const VERSION = "1.0"

class Tile:
	var color = Color(0.5, 0.5, 0.5, 1)
	var path = ""
	var width = 1
	var height = 1

var tiles = {}
var room_width = 1024
var room_height = 600

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