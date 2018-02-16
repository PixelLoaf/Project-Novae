extends KinematicBody2D

# Gravity
const CHAR_GRAVITY = 1200
# Up direction
var CHAR_UP = Vector2(0, -1)
# Maximum velocity
const CHAR_TERMINAL_VELOCITY = 1024
# Maximum amount of time after leaving a floor where the player can still snap to the floor
const CHAR_TIME_MAX_SNAP = 0.12

# The character's velocity
var char_velocity = Vector2()
# Normal vector of the floor that the character is touching
var char_floor_normal = CHAR_UP
# True if the character is on the ground
var char_on_ground = false
# Time since character has been on ground
var char_time_since_floor = 0.0

# Get this character's normal vector
func char_get_normal():
	if char_is_on_floor():
		return char_floor_normal
	else:
		return CHAR_UP

# Get the character's movement perpendicular to its normal
func char_get_motion_horizontal(normal):
	return normal.rotated(PI/2).dot(char_velocity)

# Set the character's movement perpendicular to its normal
func char_set_motion_horizontal(normal, value):
	char_velocity = char_velocity.slide(normal.rotated(PI/2))
	char_velocity += value * normal.rotated(PI/2)

# Get the character's movement parallel to its normal
func char_get_motion_vertical(normal):
	return normal.dot(char_velocity)
	
# Set the character's movement parallel to its normal
func char_set_motion_vertical(normal, value):
	char_velocity = char_velocity.slide(normal)
	char_velocity += value * normal

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
		move_and_collide(vec * result[1])
	return result

# Recalculate the character's normal vector
func char_calc_normal():
	if get_slide_count() > 0:
		char_floor_normal = Vector2();
		for i in range(get_slide_count()):
			var col = get_slide_collision(i);
			if abs(col.normal.dot(CHAR_UP)) > 0.2:
				char_floor_normal += col.normal
		if char_floor_normal == Vector2():
			char_floor_normal = CHAR_UP;
		else:
			char_floor_normal = char_floor_normal.normalized()

# Determine if the character can snap to the floor
#func char_can_snap():
#	return char_time_since_floor < CHAR_TIME_MAX_SNAP

# Do character movement. Should be called once per physics process
func char_do_movement(delta, stop_speed):
	CHAR_UP = Vector2(0, -1).rotated(get_rotation())
	# Apply gravity
	char_velocity += CHAR_GRAVITY * -char_get_normal() * delta
	# Actual movement
	var prev_normal = char_get_normal()
	var prev_veloc = char_velocity
	var prev_transform = transform
	char_velocity = move_and_slide(char_velocity, CHAR_UP, 0, 4, 0.8)
	char_calc_normal()
	if not char_is_on_floor() and is_on_floor():
		# If the character was in the air, but is now on a floor, we need to do some
		# stuff so that the character stops on the slope. First, we return the 
		# character to their original position.
		transform = prev_transform
		# Project the character using the previously used velocity so that they don't
		# go 'up' the slope when they should stay in place.
		char_project_movement(prev_veloc);
		# Rotate the character's velocity to match the new surface's normal
		char_velocity = prev_veloc.rotated(char_floor_normal.angle() - prev_normal.angle())
		# Remove character's vertical velocity component
		char_set_motion_vertical(char_floor_normal, -CHAR_GRAVITY/60)
		# Redo the whole movement process
		char_velocity = move_and_slide(char_velocity, CHAR_UP, stop_speed, 4, 0.8)
		char_calc_normal()
	# Floor timer
	char_time_since_floor += delta
	if is_on_floor():
		char_time_since_floor = 0.0
	# Detect if the character is touching a floor
	char_on_ground = char_time_since_floor < CHAR_TIME_MAX_SNAP
	# Keep character on the ground
	if char_is_on_floor():
		var result = char_project_movement(CHAR_UP * -4);
		if not result.empty() and result[1] == 1:
			char_on_ground = false
	# Enforce terminal velocity
	var veloc_v = char_get_motion_vertical(CHAR_UP)
	if abs(veloc_v) > CHAR_TERMINAL_VELOCITY:
		char_set_motion_vertical(CHAR_UP, sign(veloc_v) * CHAR_TERMINAL_VELOCITY)

# Jump up in the air
func char_jump(speed):
	char_set_motion_vertical(CHAR_UP, speed)

# Character is ready
func _ready():
	_char_cast_param.collision_layer = self.collision_mask
	_char_cast_param.margin = 0.01
	_char_cast_param.set_shape(get_node("CollisionShape2D").shape)