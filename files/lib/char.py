from godot import exposed, export, signal
from godot.bindings import *
from godot.globals import *
from enum import Enum
import math

# Gravity
CHAR_GRAVITY = 960.0
# Maximum velocity
CHAR_TERMINAL_VELOCITY = 640.0
# Maximum floor angle
CHAR_MAX_FLOOR_ANGLE = 0.8

# Method of rotation
class CharRotationMethod(Enum):
	ROT_NONE   = 0
	ROT_CHARUP = 1
	ROT_NORMAL = 2

@exposed
class CharacterBase(KinematicBody2D):
	_char_disabled = export(bool, default=False)
	char_maximum_health = export(float, default=25)
	char_on_ground = True
	char_ignore_gravity_timer = 0.0
	char_time_since_floor = 0.0
	char_velocity_rotation_method = CharRotationMethod.ROT_NORMAL
	char_on_damage_taken = signal("char_on_damage_taken")

	@property
	def char_disabled(self):
		return self._char_disabled

	@char_disabled.setter
	def char_disabled(self, value):
		self._char_disabled = value
		self.set_process_input(not value and self.has_method("_input"))
		self.set_process(not value and self.has_method("_process"))
		self.set_physics_process(not value and self.has_method("_physics_process"))
	
	def _ready(self):
		self.CHAR_UP = Vector2(0, -1).rotated(self.get_rotation())
		self.char_health = self.char_maximum_health
		self.char_velocity = -self.CHAR_UP
		self.char_floor_normal = self.CHAR_UP
		self.add_to_group("character", True)
		self.char_disabled = self.char_disabled

	def char_do_damage(self, damage):
		self.char_health = clamp(self.char_health - damage, 0, self.char_health)
		self.emit_signal("char_on_damage_taken", damage)
		if self.char_health <= 0:
			self.queue_free()

	def char_apply_force(self, amount):
		self.char_velocity += amount
	
	def char_get_normal(self):
		if self.char_is_on_floor():
			return self.char_floor_normal
		else:
			return self.CHAR_UP
	
	# Get the character's movement perpendicular to its normal
	def char_get_motion_horizontal(self):
		return self.char_velocity.x
	
	# Set the character's movement perpendicular to its normal
	def char_set_motion_horizontal(self, value):
		self.char_velocity.x = value
	
	# Get the character's movement parallel to its normal
	def char_get_motion_vertical(self):
		return self.char_velocity.y
		
	# Set the character's movement parallel to its normal
	def char_set_motion_vertical(self, value):
		self.char_velocity.y = value
	
	# Return true if the character is on the ground
	def char_is_on_floor(self):
		return self.char_on_ground

	# Recalculate the character's normal vector
	def char_calc_normal(self):
		if self.is_on_floor():
			self.char_on_ground = True
		if self.get_slide_count() == 0:
			return
		self.char_floor_normal = Vector2()
		for i in range(self.get_slide_count()):
			col = self.get_slide_collision(i)
			# The 0.99999 is just in case a value such as 1.0000000002 appears,
			# which is outside of acos' domain.
			adiff = math.acos(col.normal.dot(self.CHAR_UP)*0.99999)
			if adiff < CHAR_MAX_FLOOR_ANGLE:
				self.char_floor_normal += col.normal
				self.char_on_ground = True
		if self.char_floor_normal == Vector2():
			self.char_floor_normal = self.CHAR_UP
		else:
			self.char_floor_normal = self.char_floor_normal.normalized()

	# Function that does character movement. Should be called once per frame
	def char_do_movement(self, delta, stop_speed):
		self.CHAR_UP = Vector2(0, -1).rotated(self.get_rotation())
		self.char_time_since_floor += delta
		if self.char_ignore_gravity_timer <= 0.0:
			self.char_velocity +=  Vector2(0, CHAR_GRAVITY*delta)
		else:
			self.char_velocity += Vector2(0, CHAR_GRAVITY*delta*0.25)
			self.char_ignore_gravity_timer -= delta
		# Movement
		rot = 0;
		if self.char_velocity_rotation_method == CharRotationMethod.ROT_CHARUP:
			rot = self.CHAR_UP.angle() + math.pi/2
		elif self.char_velocity_rotation_method == CharRotationMethod.ROT_NORMAL:
			rot = self.char_get_normal().angle() + math.pi/2
		if self.char_on_ground:
			self.char_velocity = self.move_and_slide_with_snap(
					self.char_velocity.rotated(rot), Vector2(0, 6), self.CHAR_UP, 
					True, False, 4, 0.8).rotated(-rot)
		else:
			self.char_velocity = self.move_and_slide(
					self.char_velocity.rotated(rot), self.CHAR_UP, True, False,
					4, 0.8).rotated(-rot)
		# Calculate ground
		self.char_on_ground = False
		self.char_calc_normal()
		# Check if on ground
		if self.char_on_ground:
			self.char_time_since_floor = 0.0
		# Enforce terminal velocity
		veloc_v = self.char_get_motion_vertical()
		if abs(veloc_v) > CHAR_TERMINAL_VELOCITY:
			self.char_set_motion_vertical(sign(veloc_v) * CHAR_TERMINAL_VELOCITY)

	# Jump up in the air
	def char_jump(self, speed):
		self.char_set_motion_vertical(-speed)
		self.char_on_ground = False
		self.char_time_since_floor = 1.0