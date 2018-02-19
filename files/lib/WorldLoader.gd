extends Node

onready var map = $VaniaMap
export(String, FILE, "*.vmap") var map_file;

func _ready():
	map.load_from(map_file)
	for tile in map.tile_list:
		var x = tile.position.x * map.room_width
		var y = tile.position.y * map.room_height
		var room = load(tile.path).instance()
		room.position = Vector2(x, y)
		map.add_child(room)
		print(room.position)
	add_to_group("map")

func get_room_size():
	return Vector2(map.room_width, map.room_height)

func pos_to_key(pos):
	pos.x /= map.room_width
	pos.y /= map.room_height
	pos = pos.floor()
	return pos

func key_to_pos(pos):
	pos.x *= map.room_width
	pos.y *= map.room_height
	return pos

func get_room(pos):
	return map.get_tile(pos_to_key(pos))

func get_bounds(pos):
	var room = get_room(pos)
	if room == null:
		var start = pos_to_key(pos)
		return Rect2(key_to_pos(start), get_room_size())
	else:
		var start = key_to_pos(room.position)
		var size = Vector2(room.width * map.room_width, room.height * map.room_height)
		return Rect2(start, size)