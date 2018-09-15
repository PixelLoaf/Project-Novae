extends Node

# If a local variable begins with this it becomes a global variable
const GLOBALVAR = "@"
# Save directory
const SAVEDIR = "user://saves/"

# Data that applies globally
var global_data = {}
# Default values for global data, should be set by default
var default_data = {}
# Data that only applies for the current room
var local_data = {}

# Signal that is called before saving
signal finalize();

###### GENERAL MANAGEMENT ######

func get_file_path(name):
	return SAVEDIR + name + ".save"

func reset():
	global_data.clear()
	local_data.clear()

func save_file(name):
	emit_signal("finalize")
	var data = {
		global = global_data,
		local = local_data,
		scene = get_tree().current_scene.filename
	}
	var json = to_json(data)
	var path = get_file_path(name)
	var fh = File.new()
	var err = fh.open_compressed(path, File.WRITE, File.COMPRESSION_ZSTD)
	if err != OK:
		printerr("Could not open file ", path, " for writing ", err)
		return err
	fh.store_string(json)
	fh.store_line("")
	fh.close()
	return OK

func load_file(name):
	var path = get_file_path(name)
	var fh = File.new()
	var err = fh.open_compressed(path, File.READ, File.COMPRESSION_ZSTD)
	if err != OK:
		printerr("Could not open file ", path, " for reading")
		return err
	var s = fh.get_as_text()
	fh.close()
	var data = JSON.parse(s)
	if data.error:
		printerr("Error on line ", data.error_line, " with code ", data.error, ": ", data.error_string)
		print(s)
		return data.error
	if typeof(data.result) != TYPE_DICTIONARY:
		printerr("JSON data is not an object")
		return ERR_PARSE_ERROR
	if not "global" in data.result:
		printerr("JSON data does not have global tag")
		return ERR_INVALID_DATA
	if not "local" in data.result:
		printerr("JSON data does not have local tag")
		return ERR_INVALID_DATA
	if not "scene" in data.result:
		printerr("JSON data does not contain a scene")
		return ERR_INVALID_DATA
	global_data = data.result["global"]
	local_data = data.result["local"]
	err = get_tree().change_scene(data.result["scene"])
	if err != OK:
		Util.print_error(err, "could not load scene")
	return OK

###### GLOBAL DATA ######

# Set the value with the given key
func set_data(key, value):
	global_data[key] = value

# Set the default value for a given key
func set_data_default(key, value):
	assert(not key in default_data or default_data[key] == value)
	default_data[key] = value

# Get the data at the given key
func get_data(key):
	if key in global_data:
		return global_data[key]
	if key in default_data:
		return default_data[key]
	return null

###### LOCAL DATA ######

# Set local data
func set_data_local(key, value):
	if key.begins_with(GLOBALVAR):
		set_data(key.right(1), value)
	else:
		local_data[key] = value

# Get local data
func get_data_local(key):
	if key.begins_with(GLOBALVAR):
		return get_data(key.right(1))
	else:
		return local_data[key]

# Reset local data
func reset_local_data():
	local_data.clear()

func _ready():
	var dir = Directory.new()
	if not dir.dir_exists(SAVEDIR):
		dir.make_dir(SAVEDIR)

func _input(event):
	if event is InputEventKey:
		if event.pressed:
			if event.scancode == KEY_KP_1:
				save_file("test")
			elif event.scancode == KEY_KP_2:
				load_file("test")