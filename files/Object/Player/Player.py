from godot import exposed, export
from godot.bindings import *
from godot.globals import *
from lib.char import *

# Time after pressing the jump button that the player can still jump for
PLAYER_TIME_JUMP_WITHOLD = 0.2
# If the player is not moving, stop the player if they are moving slower than this
PLAYER_INERT_STOP_SPEED = 5.0
# If the player is moving, stop the player if they are moving slower than this
PLAYER_MOVING_STOP_SPEED = 0.0
# If the player is moving downhill, this is the maximum that their velocity can be multiplied by
PLAYER_DOWNHILL_MULT_MAX = 1.5
# If the chatacter is moving uphill, this is the minimum that their velocity can be multiplied by
PLAYER_UPHILL_MULT_MIN = 0.5
# Slipperiness while in the air
PLAYER_SLIP_AIR = 1.5
# Maximum time after leaving a platform that a player may still jump for
PLAYER_TIME_MAX_JUMP = 0.12
# Maximum movement speed for the player
PLAYER_SPEED_RUN = 240
# Walking speed for the player
PLAYER_SPEED_WALK = 120.0

@exposed
class Player(CharacterBase):
	# member variables here, example:
	player_jump_speed = export(float, default=400.0)
	player_accel_walk = export(float, default=1200.0)
	player_accel_stop = export(float, default=2400.0)
	
	player_facing = 1
	player_time_since_jump_button = 1.0
	player_slipperiness = 1.0
	
	def player_can_jump(self):
		return self.char_time_since_floor < PLAYER_TIME_MAX_JUMP

	def get_input_dir(self):
		rot = Vector2(1, 0).rotated(self.rotation)
		keyleft_dir  = round(rot.dot(Vector2(-1, 0)))
		keyup_dir    = round(rot.dot(Vector2(0, -1)))
		keyright_dir = round(rot.dot(Vector2(1, 0)))
		keydown_dir  = round(rot.dot(Vector2(0, 1)))
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
	def _physics_process(self, delta):
		# Calculate movement
		stop_speed = PLAYER_INERT_STOP_SPEED;
		target_speed = 0
		veloc_h = self.char_get_motion_horizontal()
		dir = self.get_input_dir()
		if dir == 1:
			if veloc_h >= 0:
				self.get_node("Sprite").flip_h = False
				self.player_facing = 1
				stop_speed = PLAYER_MOVING_STOP_SPEED
		elif dir == -1:
			if veloc_h <= 0:
				self.get_node("Sprite").flip_h = True
				self.player_facing = -1
				stop_speed = PLAYER_MOVING_STOP_SPEED
		if Input.is_action_pressed("action_run"):
			target_speed = dir * PLAYER_SPEED_RUN
		else:
			target_speed = dir * PLAYER_SPEED_WALK
		# Actual movement here
		self.char_do_movement(delta, stop_speed)
		# Change player's acceleration if they are on a slope
	#	var mult_accel = 1
	#	if target_speed > veloc_h:
	#		var mult_right = char_get_normal().dot(CHAR_UP.rotated(PI/2))
	#		if mult_right > 0:
	#			mult_accel = lerp(1, PLAYER_DOWNHILL_MULT_MAX, mult_right)
	#		else:
	#			mult_accel = lerp(1, PLAYER_UPHILL_MULT_MIN, -mult_right)
	#	else:
	#		var mult_left = char_get_normal().dot(CHAR_UP.rotated(-PI/2))
	#		if mult_left > 0:
	#			mult_accel = lerp(1, PLAYER_DOWNHILL_MULT_MAX, mult_left)
	#		else:
	#			mult_accel = lerp(1, PLAYER_UPHILL_MULT_MIN, -mult_left)
		# Player is more slippery when in the air
		slip = self.player_slipperiness
		if not self.char_is_on_floor():
			slip = PLAYER_SLIP_AIR
		# Change the player's horizontal movement according to the player's input
		veloc_h = self.char_get_motion_horizontal()
		walk_accel = self.player_accel_walk
		if self.char_is_on_floor() and ((veloc_h < 0) != (target_speed < 0) and
				veloc_h != 0 or target_speed == 0):
			walk_accel = self.player_accel_stop
#		walk_accel = clamp(delta * walk_accel / slip, 0,
#				abs(target_speed - veloc_h)) * sign(target_speed - veloc_h)
		walk_accel = max(0, min(delta*walk_accel/slip, abs(target_speed - veloc_h)))
		if target_speed - veloc_h < 0:
			walk_accel *= -1
		veloc_h += walk_accel
		self.char_set_motion_horizontal(veloc_h)
		# Jump. The purpose of doing it this way is so that the player can press the
		# jump button slightly before hitting the ground and still jump.
		self.player_time_since_jump_button += delta
		if self.player_can_jump() and self.player_time_since_jump_button < PLAYER_TIME_JUMP_WITHOLD:
			self.char_jump(self.player_jump_speed)
			self.player_time_since_jump_button = 1.0
		if not Input.is_action_pressed("action_jump") and not self.char_is_on_floor():
			veloc_v = self.char_get_motion_vertical()
			if veloc_v < -CHAR_GRAVITY / 10:
				veloc_v = -CHAR_GRAVITY / 10
				self.char_set_motion_vertical(veloc_v)

	# On input received
	def _input(self, event):
		if event.is_action_pressed("action_jump"):
			self.player_time_since_jump_button = 0.0

	# Player is ready
	def _ready(self):
		super()._ready()
		self.get_node("AnimationPlayer").play("idle")
		self.char_velocity_rotation_method = CharRotationMethod.ROT_NORMAL