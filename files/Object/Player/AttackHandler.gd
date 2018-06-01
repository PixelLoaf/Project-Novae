extends Node2D

# The state that the player must have in order to use an attack
enum PlayerAttackState {
	PASTATE_ANY, PASTATE_AIR, PASTATE_GROUND
}

# Represents a potential attack that the player can perform
class PlayerAttack:
	var button
	var scenes
	var state
	func _init(button, state, scenes):
		self.button = button
		self.state = state
		self.scenes = scenes

var PLAYER_ATTACKS = [
	PlayerAttack.new(null, PASTATE_ANY, [
		preload("res://Object/Player/Attack/Attack1.tscn"),
		preload("res://Object/Player/Attack/Attack2.tscn"),
		preload("res://Object/Player/Attack/AttackFinish.tscn")]),
	PlayerAttack.new("move_down", PASTATE_AIR, [
		preload("res://Object/Player/Attack/AttackAirDown.tscn")]),
];

var player_attack_current = 0
var player_attack_combo = 0
var player_attack_timer = 0
const PLAYER_ATTACK_TIME_RESET = 0.4

func player_get_next_attack():
	for attack in PLAYER_ATTACKS:
		if attack.button == null or Input.is_action_pressed(attack.button):
			if attack.state == PASTATE_ANY\
			or (get_parent().char_is_on_floor() and attack.state == PASTATE_GROUND)\
			or (not get_parent().char_is_on_floor() and attack.state == PASTATE_AIR):
				return attack

func _on_attack(body, attack):
	if attack.count > 1:
		return
	if not get_parent().char_is_on_floor():
		get_parent().char_velocity = Vector2(0, -50)
		get_parent().char_ignore_gravity_timer = attack.length
	else:
		get_parent().char_velocity = Vector2()
	if player_attack_current != null:
		player_attack_combo = (player_attack_combo + 1) % player_attack_current.scenes.size()

func _physics_process(delta):
	if player_attack_timer > -PLAYER_ATTACK_TIME_RESET:
		player_attack_timer -= delta
		if player_attack_timer <= -PLAYER_ATTACK_TIME_RESET:
			player_attack_current = null
			player_attack_combo = 0

func _input(event):
	if player_attack_timer <= 0.0 and event.is_action_pressed("action_attack"):
		var next_attack = player_get_next_attack()
		if next_attack != player_attack_current:
			player_attack_current = next_attack
			player_attack_combo = 0
		var node = next_attack.scenes[player_attack_combo].instance()
		node.scale.x *= get_parent().player_facing
		add_child(node)
		node.connect("on_attack", self, "_on_attack")
		player_attack_timer = node.get_duration()

class PlayerAttackSorter:
	static func sort(a, b):
		assert(a.button != b.button or a.state != b.state)
		if a.button == null and b.button != null:
			return false
		if b.button == null and a.button != null:
			return true
		if a.state != b.state:
			return a.state > b.state
		return a.get_instance_id() < b.get_instance_id()

func _ready():
	PLAYER_ATTACKS.sort_custom(PlayerAttackSorter, "sort")