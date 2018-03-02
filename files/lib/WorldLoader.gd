extends Node

onready var map = $VaniaMap
export(String, FILE, "*.vmap") var map_file;

var connections;
var load_position;
var active_node;

func _on_room_load(room, tile):
	room.set_process(false)
	room.set_process_internal(false)

func _on_room_unload(room, tile):
	if room == active_node:
		active_node = null

func get_room_nearby(tile, depth=1, data=null):
	if data == null:
		data = {}
		data[tile] = 0
	for t in connections[tile]:
		if not t in data:
			data[t] = depth
	if depth > 1:
		for t in data:
			if data[t] == depth:
				get_room_nearby(t, depth-1, data)
	return data

func _ready():
	map.load_from(map_file)
	connections = map.get_tile_connections()
	add_to_group("map")
	map.connect("room_loaded", self, "_on_room_load")

func set_load_position(pos):
	pos = map.pos_to_tilepos(pos)
	if pos != load_position:
		load_position = pos
		var tile = map.get_tile(pos)
		if tile != null:
			var connections = get_room_nearby(tile, 2)
			for unloadtile in map.loaded_rooms:
				if not unloadtile in connections:
					map.unload_room(unloadtile)
			for loadtile in connections:
				if connections[loadtile] <= 1:
					map.load_room(loadtile)
				if connections[loadtile] == 0:
					var node = map.loaded_rooms[loadtile]
					if node != active_node:
						if active_node != null:
							remove_child(active_node)
						active_node = node
						add_child(active_node)

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