extends KinematicBody2D

# Gravity
const CHAR_GRAVITY = 1200
# Up direction
onready var CHAR_UP = Vector2(0, -1).rotated(get_rotation())
# Maximum velocity
const CHAR_TERMINAL_VELOCITY = 640
# Maximum amount of time after leaving a floor where the player can still snap to the floor
const CHAR_TIME_MAX_SNAP = 0.12
# Gravity multiplier on the ground
const CHAR_GRAVITY_MULT_GROUND = 16
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

# Determine if the character can snap to the floor
func char_apply_velocity(veloc, stop_speed):
	var ret = move_and_slide(veloc, CHAR_UP, stop_speed, 4, CHAR_MAX_FLOOR_ANGLE)
	char_calc_normal()
	return ret

# Do character movement. Should be called once per physics process.
func char_do_movement(delta, stop_speed):
	CHAR_UP = Vector2(0, -1).rotated(get_rotation())
	# Increment timer
	char_time_since_floor += delta
	# Apply gravity
	if char_is_on_floor():
		# Sometimes the character doesn't update their normal normally when on the
		# ground, so applying extra downward velocity helps.
		char_velocity += CHAR_GRAVITY * -char_get_normal() * delta * CHAR_GRAVITY_MULT_GROUND
	else:
		char_velocity += CHAR_GRAVITY * -char_get_normal() * delta
	# Keep track of previous values, they are important
	var prev_veloc = char_velocity
	var prev_on_ground = char_on_ground
	var prev_normal = char_get_normal()
	var prev_transform = transform
	char_on_ground = false
	# Movement
	char_velocity = move_and_slide(char_velocity, CHAR_UP, stop_speed, 4, 0.8)
	char_calc_normal()
	# If the character was in the air, but is now on a floor, we need to do some
	# stuff so that the character doesn't slide down slopes.
	if char_is_on_floor() and not prev_on_ground:
		#First, return the character to their original position.
		transform = prev_transform
		# Project the character using the previously used velocity so that they don't
		# go 'up' the slope when they should stay in place.
		char_project_movement(prev_veloc);
		# Rotate the character's velocity to match the new surface's normal
		char_velocity = prev_veloc.rotated(char_get_normal().angle() - prev_normal.angle())
		# Remove character's vertical velocity component
		char_set_motion_vertical(char_get_normal(), -CHAR_GRAVITY/60)
		# Redo the whole movement process
		char_velocity = char_apply_velocity(char_velocity, stop_speed)
	# If a character is on the ground and their normal changes, then adjust accordingly.
	elif abs(char_get_normal().angle() - prev_normal.angle()) > 1e-5 and char_is_on_floor():
		transform = prev_transform
		char_velocity = prev_veloc.rotated(char_get_normal().angle() - prev_normal.angle())
		char_velocity = char_apply_velocity(char_velocity, stop_speed)
	# If the character was on the ground but no longer is, 
	# try and put the character back onto the ground.
	elif not char_is_on_floor() and prev_on_ground:
		var result = char_project_movement(CHAR_UP * -8)
		if result.empty() or result[1] != 1:
			char_on_ground = true
		else:
			# However, if the character could not be placed on the ground, then assume
			# it walked off of a cliff. In this case, since gravity is increased when on
			# the ground, the vertical velocity has to be reset.
			char_set_motion_vertical(char_get_normal(), 0)
			transform = prev_transform
			char_velocity = char_apply_velocity(char_velocity, stop_speed)
	# Reset vertical velocity
	if char_on_ground:
		char_set_motion_vertical(char_get_normal(), 0)
		char_time_since_floor = 0.0
#	position = position.snapped(Vector2(1, 1))
	# Enforce terminal velocity
	var veloc_v = char_get_motion_vertical(CHAR_UP)
	if abs(veloc_v) > CHAR_TERMINAL_VELOCITY:
		char_set_motion_vertical(CHAR_UP, sign(veloc_v) * CHAR_TERMINAL_VELOCITY)

# Jump up in the air
func char_jump(speed):
	char_set_motion_vertical(CHAR_UP, speed)
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