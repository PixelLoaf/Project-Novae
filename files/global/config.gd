extends Node

# Path to the user's configuration file
const CONFIG_FILE = "user://configuration.cfg"
# Handle to the user's configuration file
onready var config = ConfigFile.new();

# Section name for the player's keybinds
const SECTION_KEYS = "keybinds"
# Section name for the player's volume
const SECTION_VOLUME = "volume"
# All configurable keys
const SECTION_KEY_ELEMENTS = [
	"move_up",
	"move_down",
	"move_left",
	"move_right",
	"action_jump",
]
# All configurable volumes
const SECTION_VOLUME_ELEMENTS = [
	"Sound",
	"Music",
	"Master",
]
# Real names for inputs
const INPUT_REALNAMES = {
	"move_up": "Move Up",
	"move_down": "Move Down",
	"move_left": "Move Left",
	"move_right": "Move Right",
	"action_jump": "Jump",
	"hide_debug": "Hide Debug Menu",
}

# Get the real name for a given action
func get_action_name(name):
	if INPUT_REALNAMES.has(name):
		return INPUT_REALNAMES[name]
	return "Invalid"

# Get the volume for the given volume name
func get_volume(name):
	return config.get_value(SECTION_VOLUME, name);

# Get the volume from 1 - 100
func get_volume_slider(name):
	return get_volume(name) * 100
	
# Updates the volume of the given bus to the given value
func update_volume(name):
	var volumedb = volume_to_db(get_volume(name))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(name), volumedb)

# Set the volume for the given volume name
func set_volume(name, value):
	config.set_value(SECTION_VOLUME, name, value);
	update_volume(name)
	save_config();

# Set the volume but from 1 - 100
func set_volume_slider(name, value):
	set_volume(name, value/100)

# Used to make sure config has all of the necessary settings
func check_config():
	var does_need_save = false
	for name in SECTION_KEY_ELEMENTS:
		if not config.has_section_key(SECTION_KEYS, name):
			config.set_value(SECTION_KEYS, name, InputMap.get_action_list(name)[0]);
			does_need_save = true
	for name in SECTION_VOLUME_ELEMENTS:
		if not config.has_section_key(SECTION_VOLUME, name):
			config.set_value(SECTION_VOLUME, name, 0.5);
			does_need_save = true
	if does_need_save:
		save_config()

func _ready():
	# Make sure that the config file exists
	var file = File.new();
	if not file.file_exists(CONFIG_FILE):
		file.open(CONFIG_FILE, file.WRITE)
		file.close();
		save_config();
	load_config();

# Update all events in map to match settings
func update_events():
	for name in SECTION_KEY_ELEMENTS:
		var events = config.get_value(SECTION_KEYS, name);
		InputMap.erase_action(name);
		InputMap.add_action(name);
		if typeof(events) == TYPE_ARRAY:
			for event in events:
				InputMap.action_add_event(name, event);
		else:
			InputMap.action_add_event(name, events);

# Converts the given volume to DB.
# 0 becomes -60db and 1 becomes -0db
func volume_to_db(value):
	return pow(1 - value, 2) * -60

func update_volumes():
	for name in SECTION_VOLUME_ELEMENTS:
		update_volume(name)

# Load configuration
func load_config():
	var err = config.load(CONFIG_FILE);
	if err != OK:
		print("Error loading user configuration: ", err);
	# After loading, check configuration
	# to make sure it is valid
	check_config();
	# And update InputMap to match
	update_events();
	return err

# Save configuration to file
func save_config():
	var err = config.save(CONFIG_FILE);
	if err != OK:
		print("Error saving user configuration: ", err);
	return err

# Get a keybind
func get_keybind(name):
	return config.get_value(SECTION_KEYS, name)

# Set a keybind to a given event
func set_keybind(name, event):
	config.set_value(SECTION_KEYS, name, event)
	save_config()
	InputMap.erase_action(name);
	InputMap.add_action(name);
	InputMap.action_add_event(name, event);

# Check if an event is really a valid event
# Returns null if not valid, returns event if is valid
func check_input_valid(event):
	if event is InputEventKey:
		if event.pressed and not event.echo:
			event.control = false
			event.shift = false
			event.meta = false
			event.alt = false
			event.command = false
			return event
	if event is InputEventMouseButton:
		if event.pressed and not event.doubleclick:
			event.control = false
			event.shift = false
			event.meta = false
			event.alt = false
			event.command = false
			return event
	if event is InputEventJoypadButton:
		if event.pressed:
			return event
	return null

# Get name of an event
func get_event_name(event):
	if event is InputEventKey:
		return OS.get_scancode_string(event.scancode)
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			return "Left click"
		if event.button_index == BUTTON_RIGHT:
			return "Right click"
		if event.button_index == BUTTON_MIDDLE:
			return "Middle click"
		if event.button_index == BUTTON_WHEEL_DOWN:
			return "Mouse wheel down"
		if event.button_index == BUTTON_WHEEL_UP:
			return "Mouse wheel down"
		if event.button_index == BUTTON_WHEEL_LEFT:
			return "Mouse wheel left"
		if event.button_index == BUTTON_WHEEL_RIGHT:
			return "Mouse wheel right"
		return "Mouse button " + str(event.button_index)
	if event is InputEventJoypadButton:
		return "Button " + str(event.button_index)
	return "Invalid"