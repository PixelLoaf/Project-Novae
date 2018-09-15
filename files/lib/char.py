from godot import exposed, export
from godot.bindings import *
from godot.globals import *

@exposed
class char(KinematicBody2D):
#	_char_disabled = False
#
#	@property
#	def char_disabled(self):
#		return _char_disabled
#
#	@char_disabled.setter
#	def char_disabled(self, value):
#		_char_disabled = value
#		self.set_process_input(not value and self.has_method("_input"))
#		self.set_process(not value and self.has_method("_process"))
#		self.set_physics_process(not value and self.has_method("_physics_process"))
	
	def _ready(self):
		pass
