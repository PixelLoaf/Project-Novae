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
const CHAR_INERT_STOP_SPEED = 5
# If the player is moving, stop the player if they are moving slower than this
const CHAR_MOVING_STOP_SPEED = 0
# If the player is moving downhill, this is the maximum that their velocity can be multiplied by
const CHAR_DOWNHILL_MULT_MAX = 1.5
# If the player is moving uphill, this is the minimum that their velocity can be multiplied by
const CHAR_UPHILL_MULT_MIN = 0.5
# Slipperiness while in the air
const CHAR_SLIP_AIR = 0.4

# Maximum movement speed for the player
export var char_speed_max = 320
# Jumping speed for the player
export var char_jump_speed = 640

# The player's velocity
var char_velocity = Vector2()
# The amount of time since the player has touched a floor
var char_time_since_floor = 1.0
# Normal vector of the floor that the player is touching
var char_floor_normal = CHAR_UP
# Time since pressing the jump button
var char_time_since_jump_button = 1.0
# Momentum and inertia hinge around this
var char_slipperiness = 0.2

# Get this character's normal vector
func char_get_normal():
	if char_is_on_floor():
		return char_floor_normal
	else:
		return CHAR_UP

# Get the character's movement perpendicular to its normal
func char_get_motion_horizontal(normal):
	return normal.rotated(PI/2).dot(char_velocity)
	
# Get horizontal motion as a vector2
func char_get_motion_horizontal_vec(normal):
	return char_get_motion_horizontal(normal) * normal.rotated(PI/2)

# Set the character's movement perpendicular to its normal
func char_set_motion_horizontal(normal, value):
	char_velocity = char_velocity.slide(normal.rotated(PI/2))
	char_velocity += value * normal.rotated(PI/2)

# Get the character's movement parallel to its normal
func char_get_motion_vertical(normal):
	return normal.dot(char_velocity)
	
# Get horizontal motion as a vector2
func char_get_motion_vertical_vec(normal):
	return char_get_motion_vertical(normal) * normal
	
# Set the character's movement parallel to its normal
func char_set_motion_vertical(normal, value):
	char_velocity = char_velocity.slide(normal)
	char_velocity += value * normal

# Return true if the player is on the ground
func char_is_on_floor():
	return char_time_since_floor < CHAR_TIME_MAX_JUMP

# Project the player so that it moves by 'vec'
func char_project_self(space, param, vec):
	param.transform = get_node("CollisionShape2D").get_global_transform()
	param.motion = vec
	var result = space.cast_motion(param)
	if not result.empty() and result[1] != 1:
		move_and_collide(vec * result[1])

# Recalculate the player's normal vector
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

# Do character movement. Should be called once per physics process
var _char_cast_param = Physics2DShapeQueryParameters.new();
func char_do_movement(stop_speed):
	var prev_normal = char_get_normal()
	var prev_veloc = char_velocity
	var prev_transform = transform
	char_velocity = move_and_slide(char_velocity, CHAR_UP, stop_speed, 4, 0.8)
	char_calc_normal()
	if char_is_on_floor():
		var space_state = get_world_2d().get_direct_space_state()
		char_project_self(space_state, _char_cast_param, CHAR_UP * -4);
	elif is_on_floor():
		# If the player was in the air, but is now on a floor, we need to do some
		# stuff so that the player stops on the slope. First, we return the player to
		# their original position.
		transform = prev_transform
		# Rotate the player's velocity to match the new surface's normal
		char_velocity = prev_veloc.rotated(char_floor_normal.angle() - prev_normal.angle())
		# Redo the whole movement process
		char_velocity = move_and_slide(char_velocity, CHAR_UP, stop_speed, 4, 0.8)
		char_calc_normal()
	# Detect if the player is touching a floor
	if is_on_floor():
		char_time_since_floor = 0.0

# Every frame
func _physics_process(delta):
	CHAR_UP = Vector2(0, -1).rotated(get_rotation())
	# Calculate movement
	var stop_speed = CHAR_INERT_STOP_SPEED;
	var target_speed = 0
	var veloc_h = char_get_motion_horizontal(char_get_normal())
	if Input.is_action_pressed("move_left"):
		if veloc_h <= 0:
			$Sprite.flip_h = true
			stop_speed = CHAR_MOVING_STOP_SPEED
		target_speed = -char_speed_max
	elif Input.is_action_pressed("move_right"):
		if veloc_h >= 0:
			$Sprite.flip_h = false
			stop_speed = CHAR_MOVING_STOP_SPEED
		target_speed = char_speed_max
	# Increment variables
	char_velocity += CHAR_GRAVITY * -char_get_normal() * delta
	char_time_since_jump_button += delta
	char_time_since_floor += delta
	# Jump. The purpose of doing it this way is so that the player can press the
	# jump button slightly before hitting the ground and still jump.
	if char_is_on_floor() and char_time_since_jump_button < CHAR_TIME_JUMP_WITHOLD:
		char_time_since_jump_button = 1.0
		char_velocity.y = -char_jump_speed
		char_time_since_floor = 1.0
	# Actual movement here
	char_do_movement(stop_speed)
	# Change player's acceleration if they are on a slope
	var mult_accel = 1
	if target_speed > veloc_h:
		var mult_right = char_get_normal().dot(CHAR_UP.rotated(PI/2))
		if mult_right > 0:
			mult_accel = lerp(1, CHAR_DOWNHILL_MULT_MAX, mult_right)
		else:
			mult_accel = lerp(1, CHAR_UPHILL_MULT_MIN, -mult_right)
	else:
		var mult_left = char_get_normal().dot(CHAR_UP.rotated(-PI/2))
		if mult_left > 0:
			mult_accel = lerp(1, CHAR_DOWNHILL_MULT_MAX, mult_left)
		else:
			mult_accel = lerp(1, CHAR_UPHILL_MULT_MIN, -mult_left)
	# Player is more slippery when in the air
	var slip = char_slipperiness
	if not char_is_on_floor():
		slip = CHAR_SLIP_AIR
	# Change the player's horizontal movement according to the player's input
	veloc_h = char_get_motion_horizontal(char_get_normal())
	veloc_h += mult_accel * delta * (target_speed - veloc_h) / slip
	char_set_motion_horizontal(char_get_normal(), veloc_h)

# On input received
func _input(event):
	if event.is_action_pressed("action_jump"):
		char_time_since_jump_button = 0.0

# Character is ready
func _ready():
	$AnimationPlayer.play("idle")
	_char_cast_param.collision_layer = self.collision_mask
	_char_cast_param.margin = 0.08
	_char_cast_param.set_shape(get_node("CollisionShape2D").shape)