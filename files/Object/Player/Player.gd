extends KinematicBody2D

# Gravity
const CHAR_GRAVITY = 2000
# Up direction
var CHAR_UP = Vector2(0, -1)
# Maximum time after leaving a platform that a player may still jump for
const CHAR_TIME_MAX_JUMP = 0.12
# Time after pressing the jump button that the player can still jump for
const CHAR_TIME_JUMP_WITHOLD = 0.2
# If the player is not moving, stop the player if they are moving slower than this
const CHAR_INERT_STOP_SPEED = 160
# If the player is moving, stop the player if they are moving slower than this
const CHAR_MOVING_STOP_SPEED = 5
# Momentum and inertia hinge around this
var CHAR_SLIPPERINESS = 10 	

# Maximum movement speed for the player
export var char_speed_max = 400
# Jumping speed for the player
export var char_jump_speed = 800

# The player's velocity
var char_velocity = Vector2()
# The amount of time since the player has touched a floor
var char_time_since_floor = 1.0
# Normal vector of the floor that the player is touching
var char_floor_normal = CHAR_UP
# Time since pressing the jump button
var char_time_since_jump_button = 1.0

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
func char_get_motion_vertical(normal, value):
	return normal.dot(char_velocity)

# Set the character's movement parallel to its normal
func char_set_motion_vertical(normal, value):
	char_velocity = char_velocity.slide(normal)
	char_velocity += value * normal

# Return true if the player is on the ground
func char_is_on_floor():
	return char_time_since_floor < CHAR_TIME_MAX_JUMP

func _input(event):
	if event.is_action_pressed("jump"):
		char_time_since_jump_button = 0.0

func _physics_process(delta):
	CHAR_UP = Vector2(0, -1).rotated(get_rotation())
	# Calculate movement
	var stop_speed = CHAR_INERT_STOP_SPEED;
	var target_speed = 0
	var veloc_h = char_get_motion_horizontal(char_get_normal())
	if Input.is_action_pressed("left"):
		if veloc_h <= 0:
			stop_speed = CHAR_MOVING_STOP_SPEED
		target_speed = -char_speed_max
	elif Input.is_action_pressed("right"):
		if veloc_h >= 0:
			stop_speed = CHAR_MOVING_STOP_SPEED
		target_speed = char_speed_max
	# Increment variables
	char_velocity += CHAR_GRAVITY * -CHAR_UP * delta
	char_time_since_jump_button += delta
	char_time_since_floor += delta
	# Jump. The purpose of doing it this way is so that the player can press the
	# jump button slightly before hitting the ground and still jump.
	if char_is_on_floor() and char_time_since_jump_button < CHAR_TIME_JUMP_WITHOLD:
		char_time_since_jump_button = 1.0
		char_set_motion_vertical(CHAR_UP, char_jump_speed)
		char_time_since_floor = 1.0
	# Actual movement here
	char_velocity = move_and_slide(char_velocity, CHAR_UP, stop_speed, 4, 0.8)
	# Detect if the player is touching a floor
	if is_on_floor():
		char_time_since_floor = 0.0
	# Calculate the player's normal if they are on the ground
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
		print("NEW FLOOR")
	# Change the player's horizontal movement according to the player's input
	veloc_h = char_get_motion_horizontal(char_get_normal())
	#veloc_h = lerp(veloc_h, target_speed, pow(delta, 1.0/2.0))
	veloc_h += (target_speed - veloc_h) / CHAR_SLIPPERINESS
	char_set_motion_horizontal(char_get_normal(), veloc_h)
