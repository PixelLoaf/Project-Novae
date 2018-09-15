extends Control

export (String) var action_name
var previous_input

onready var button = $Change
onready var label = $Label

func update_self():
	var action = UserConfig.get_keybind(action_name)
	var text = UserConfig.get_event_name(action)
	button.set_text(text)

func update_config(event):
	previous_input = UserConfig.get_keybind(action_name);
	UserConfig.set_keybind(action_name, event);

func _input(event):
	if button.is_pressed():
		var e = UserConfig.check_input_valid(event)
		if e != null:
			update_config(e)
			update_self()
			button.set_pressed(false)
			button.accept_event()

func _physics_process(_delta):
	button.set_disabled(button.is_pressed())

func _ready():
	update_self();
	label.set_text(UserConfig.get_action_name(action_name))
	previous_input = UserConfig.get_keybind(action_name);

func _on_ChangeButton_released():
	button.set_disabled(false)
	update_self()

func _on_Change_pressed():
	button.set_disabled(true)
	button.set_text("...")
