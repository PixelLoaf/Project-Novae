extends KinematicBody2D

export var char_disabled = false setget _char_disable_set;
func _char_disable_set(value):
	set_process_input(not value and has_method("_input"))
	set_process(not value and has_method("_process"))
	set_physics_process(not value and has_method("_physics_process"))
	char_disabled = value

# Health
export var char_maximum_health = 25
var char_health = char_maximum_health
# Gravity
const CHAR_GRAVITY = 960.0
# Up direction
onready var CHAR_UP = Vector2(0, -1).rotated(get_rotation())
# Maximum velocity
const CHAR_TERMINAL_VELOCITY = 640.0
# Maximum floor angle
const CHAR_MAX_FLOOR_ANGLE = 0.8

# The character's velocity
onready var char_velocity = -CHAR_UP
# Normal vector of the floor that the character is touching
onready var char_floor_normal = CHAR_UP
# True if the character is on the ground
var char_on_ground = true
# Time since character has been on ground
var char_time_since_floor = 0.0
# How the character handles velocity rotation
enum CharRotationMethod {ROT_NONE, ROT_CHARUP, ROT_NORMAL}
var char_velocity_rotation_method = ROT_NORMAL
# Amount of time to ignore gravity
var char_ignore_gravity_timer = 0.0

# Deal damage to this character
func char_do_damage(damage):
	char_health = clamp(char_health - damage, 0, char_health)
	emit_signal("char_on_damage_taken", damage)
	if char_health == 0:
		queue_free()
signal char_on_damage_taken(amount)

# Add the given velocity to this character
func char_apply_force(amount):
	char_velocity += amount

# Get this character's normal vector
func char_get_normal():
	if char_is_on_floor():
		return char_floor_normal
	else:
		return CHAR_UP

# Get the character's movement perpendicular to its normal
func char_get_motion_horizontal():
	return char_velocity.x

# Set the character's movement perpendicular to its normal
func char_set_motion_horizontal(value):
	char_velocity.x = value

# Get the character's movement parallel to its normal
func char_get_motion_vertical():
	return char_velocity.y
	
# Set the character's movement parallel to its normal
func char_set_motion_vertical(value):
	char_velocity.y = value

# Return true if the character is on the ground
func char_is_on_floor():
	return char_on_ground

# Project the character onto the given axis
var _char_cast_param = Physics2DShapeQueryParameters.new();
func char_project_self(vec):
	var space = get_world_2d().get_direct_space_state()
	_char_cast_param.transform = get_node("CollisionShape2D").get_global_transform()
	_char_cast_param.motion = vec
	var result = space.cast_motion(_char_cast_param)
	return result

# Project the character so that it moves by 'vec'
func char_project_movement(vec):
	var result = char_project_self(vec)
	if not result.empty() and result[1] != 1:
		var _ignore = move_and_collide(vec * result[1])
	return result

# Recalculate the character's normal vector
func char_calc_normal():
	if is_on_floor():
		char_on_ground = true
	if get_slide_count() == 0:
		return
	char_floor_normal = Vector2()
	for i in range(get_slide_count()):
		var col = get_slide_collision(i)
		var adiff = acos(col.normal.dot(CHAR_UP))
		if adiff < CHAR_MAX_FLOOR_ANGLE:
			char_floor_normal += col.normal
			char_on_ground = true
	if char_floor_normal == Vector2():
		char_floor_normal = CHAR_UP
	else:
		char_floor_normal = char_floor_normal.normalized()

# Function that does character movement. Should be called once per frame
func char_do_movement(delta, stop_speed):
	CHAR_UP = Vector2(0, -1).rotated(get_rotation())
	char_time_since_floor += delta
	if char_ignore_gravity_timer <= 0.0:
		char_velocity += CHAR_GRAVITY * Vector2(0, 1) * delta
	else:
		char_velocity += CHAR_GRAVITY * Vector2(0, 1) * delta * 0.25
		char_ignore_gravity_timer -= delta
#	var prev_on_ground = char_on_ground
	# Movement
	var rot = 0;
	if char_velocity_rotation_method == ROT_CHARUP:
		rot = CHAR_UP.angle() + PI/2
	elif char_velocity_rotation_method == ROT_NORMAL:
		rot = char_get_normal().angle() + PI/2
	if char_on_ground:
		char_velocity = move_and_slide_with_snap(char_velocity.rotated(rot),
				Vector2(0, 6), CHAR_UP, true, false, 4, 0.8).rotated(-rot)
	else:
		char_velocity = move_and_slide(char_velocity.rotated(rot), CHAR_UP, 
				true, false, 4, 0.8).rotated(-rot)
#	char_velocity = move_and_slide(char_velocity.rotated(rot), CHAR_UP, true, stop_speed, 4, 0.8).rotated(-rot)
	# Calculate ground
	char_on_ground = false
	char_calc_normal()
	# Make sure player is on the ground
#	if (char_on_ground or prev_on_ground) and char_time_since_floor < 0.5:
#		var result = char_project_movement(CHAR_UP * -8)
#		if result.empty() or result[1] != 1:
#			var _ignore = move_and_slide(-CHAR_UP, CHAR_UP, true, 0, 4, 0.8)
#			char_calc_normal()
#			char_on_ground = true
	# Check if on ground
	if char_on_ground:
		char_time_since_floor = 0.0
	# Enforce terminal velocity
	var veloc_v = char_get_motion_vertical()
	if abs(veloc_v) > CHAR_TERMINAL_VELOCITY:
		char_set_motion_vertical(sign(veloc_v) * CHAR_TERMINAL_VELOCITY)

# Jump up in the air
func char_jump(speed):
	char_set_motion_vertical(-speed)
	char_on_ground = false
	char_time_since_floor = 1.0

# Character is ready
func _ready():
	_char_cast_param.collision_layer = self.collision_mask
	_char_cast_param.margin = 0.05
	if Physics2DServer.body_get_shape_count(self.get_rid()) > 0:
		var shape = Physics2DServer.body_get_shape(self.get_rid(), 0)
		_char_cast_param.shape_rid = shape
	add_to_group("character", true)
	_char_disable_set(char_disabled)