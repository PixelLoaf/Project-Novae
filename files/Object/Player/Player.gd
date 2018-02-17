extends "res://lib/char.gd"

# Time after pressing the jump button that the player can still jump for
const PLAYER_TIME_JUMP_WITHOLD = 0.2
# If the player is not moving, stop the player if they are moving slower than this
const PLAYER_INERT_STOP_SPEED = 5
# If the player is moving, stop the player if they are moving slower than this
const PLAYER_MOVING_STOP_SPEED = 0
# If the player is moving downhill, this is the maximum that their velocity can be multiplied by
const PLAYER_DOWNHILL_MULT_MAX = 1.5
# If the chatacter is moving uphill, this is the minimum that their velocity can be multiplied by
const PLAYER_UPHILL_MULT_MIN = 0.5
# Slipperiness while in the air
const PLAYER_SLIP_AIR = 1.0
# Maximum time after leaving a platform that a player may still jump for
const PLAYER_TIME_MAX_JUMP = 0.12
# Maximum movement speed for the player
const PLAYER_SPEED_RUN = 300
# Walking speed for the player
const PLAYER_SPEED_WALK = 180

# Jumping speed for the player
export var player_jump_speed = 500
# Walking acceleration
export var player_accel_walk = 1200
# Acceleration when stopping on the ground
export var player_accel_stop = 2400

# Time since pressing the jump button
var player_time_since_jump_button = 1.0
# Slipperiness of the ground. 
# The higher this is, the less control the player has.
var player_slipperiness = 1.0

func player_can_jump():
	return char_time_since_floor < PLAYER_TIME_MAX_JUMP

func get_input_dir():
	var rot = Vector2(1, 0).rotated(self.rotation)
	var keyleft_dir  = round(rot.dot(Vector2(-1, 0)))
	var keyup_dir    = round(rot.dot(Vector2(0, -1)))
	var keyright_dir = round(rot.dot(Vector2(1, 0)))
	var keydown_dir  = round(rot.dot(Vector2(0, 1)))
	if Input.is_action_pressed("move_left") and keyleft_dir != 0:
		return keyleft_dir
	if Input.is_action_pressed("move_up") and keyup_dir != 0:
		return keyup_dir
	if Input.is_action_pressed("move_right") and keyright_dir != 0:
		return keyright_dir
	if Input.is_action_pressed("move_down") and keydown_dir != 0:
		return keydown_dir
	return 0

# Every frame
func _physics_process(delta):
	# Calculate movement
	var stop_speed = PLAYER_INERT_STOP_SPEED;
	var target_speed = 0
	var veloc_h = char_get_motion_horizontal(char_get_normal())
	var dir = get_input_dir()
	if dir == 1:
		if veloc_h >= 0:
			$Sprite.flip_h = false
			stop_speed = PLAYER_MOVING_STOP_SPEED
	elif dir == -1:
		if veloc_h <= 0:
			$Sprite.flip_h = true
			stop_speed = PLAYER_MOVING_STOP_SPEED
	if Input.is_action_pressed("action_run"):
		target_speed = dir * PLAYER_SPEED_RUN
	else:
		target_speed = dir * PLAYER_SPEED_WALK
	# Actual movement here
	char_do_movement(delta, stop_speed)
	# Change player's acceleration if they are on a slope
	var mult_accel = 1
	if target_speed > veloc_h:
		var mult_right = char_get_normal().dot(CHAR_UP.rotated(PI/2))
		if mult_right > 0:
			mult_accel = lerp(1, PLAYER_DOWNHILL_MULT_MAX, mult_right)
		else:
			mult_accel = lerp(1, PLAYER_UPHILL_MULT_MIN, -mult_right)
	else:
		var mult_left = char_get_normal().dot(CHAR_UP.rotated(-PI/2))
		if mult_left > 0:
			mult_accel = lerp(1, PLAYER_DOWNHILL_MULT_MAX, mult_left)
		else:
			mult_accel = lerp(1, PLAYER_UPHILL_MULT_MIN, -mult_left)
	# Player is more slippery when in the air
	var slip = player_slipperiness
	if not char_is_on_floor():
		slip = PLAYER_SLIP_AIR
	# Change the player's horizontal movement according to the player's input
	veloc_h = char_get_motion_horizontal(char_get_normal())
	var walk_accel = player_accel_walk
	if char_is_on_floor() and ((veloc_h < 0) != (target_speed < 0) and veloc_h != 0 or target_speed == 0):
		walk_accel = player_accel_stop
	walk_accel = clamp(delta * walk_accel / slip, 0, abs(target_speed - veloc_h))
	if veloc_h < target_speed:
		veloc_h += walk_accel
	elif veloc_h > target_speed:
		veloc_h -= walk_accel
	char_set_motion_horizontal(char_get_normal(), veloc_h)
	# Jump. The purpose of doing it this way is so that the player can press the
	# jump button slightly before hitting the ground and still jump.
	player_time_since_jump_button += delta
	print(char_time_since_floor, " ")
	if player_can_jump() and player_time_since_jump_button < PLAYER_TIME_JUMP_WITHOLD:
		char_jump(player_jump_speed)
		player_time_since_jump_button = 1.0

# On input received
func _input(event):
	if event.is_action_pressed("action_jump"):
		player_time_since_jump_button = 0.0
	if event.is_action_released("action_jump") and not char_is_on_floor():
		var veloc_v = char_get_motion_vertical(CHAR_UP)
		if veloc_v > CHAR_GRAVITY / 10:
			veloc_v = CHAR_GRAVITY / 10
			char_set_motion_vertical(CHAR_UP, veloc_v)

# Player is ready
func _ready():
	$AnimationPlayer.play("idle")