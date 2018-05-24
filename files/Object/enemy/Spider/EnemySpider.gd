extends "res://lib/char.gd"

const SPEED = 120
const WALK_SPEED = 60
const MIN_DISTANCE = 24
const CHANGE_DIR_TIME = 1.0
const JUMP = 440

enum SpiderState {PATROL, CHASING}

var state = PATROL

export var player_notice_delay = 0.3;
export var player_ignore_delay = 2.0;

var time_since_player_entered = 0.0
var time_since_player_left = 0.0
var patrol_wait = 1.0
var patrol_dir = -1
var players = []
var target = null

func get_target():
	if players.empty():
		return null
	else:
		return players.front()

func get_cast_length(ray):
	return (ray.get_collision_point() - ray.global_position).length()

func can_move_left():
	if $Hitbox/RayWallLeft.is_colliding():
		return false
	if $Hitbox/RayGroundLeft.is_colliding():
		var n = $Hitbox/RayGroundLeft.get_collision_normal()
		var l = get_cast_length($Hitbox/RayGroundLeft)
		var adiff = acos(n.dot(CHAR_UP))
		if adiff < CHAR_MAX_FLOOR_ANGLE or l < 20:
			return true
	return false

func can_move_right():
	if $Hitbox/RayWallRight.is_colliding():
		return false
	if $Hitbox/RayGroundRight.is_colliding():
		var n = $Hitbox/RayGroundRight.get_collision_normal()
		var l = get_cast_length($Hitbox/RayGroundRight)
		var adiff = acos(n.dot(CHAR_UP))
		if adiff < CHAR_MAX_FLOOR_ANGLE or l < 20:
			return true
	return false

func _physics_process(delta):
	var target_speed = null
	if get_target() == null:
		time_since_player_left += delta
		time_since_player_entered = 0.0
	else:
		target = get_target()
		time_since_player_entered += delta
		time_since_player_left = 0.0
	if time_since_player_entered > player_notice_delay and state == PATROL:
		state = CHASING
	if time_since_player_left > player_ignore_delay and state != PATROL:
		state = PATROL
		patrol_wait = CHANGE_DIR_TIME
	match state:
		PATROL:
			if patrol_wait > 0:
				patrol_wait -= delta
				if char_is_on_floor():
					target_speed = 0
			else:
				if patrol_dir < 0 and not can_move_left():
					patrol_dir = 1
					patrol_wait = CHANGE_DIR_TIME
					target_speed = 0
				elif patrol_dir > 0 and not can_move_right():
					patrol_dir = -1
					patrol_wait = CHANGE_DIR_TIME
					target_speed = 0
				else:
					target_speed = patrol_dir * WALK_SPEED
		CHASING:
			var dir = target.global_position - global_position
			dir = char_get_normal().rotated(PI/2).dot(dir)
			if abs(dir) < MIN_DISTANCE:
				dir = 0
			else:
				dir = sign(dir)
			if dir != 0:
				patrol_dir = -dir
			if char_is_on_floor():
				if dir < 0:
					if not can_move_left():
						char_jump(JUMP)
						set_rotation(0)
				elif dir > 0:
					if not can_move_right():
						char_jump(JUMP)
						set_rotation(0)
			if char_is_on_floor() or dir != 0:
				target_speed = dir * SPEED
	if target_speed != null:
		var veloc_h = char_get_motion_horizontal()
		var walk_accel = 200
		if char_is_on_floor():
			walk_accel = 400
#		walk_accel = clamp(delta * walk_accel / slip, 0, abs(target_speed - veloc_h))
		if veloc_h < target_speed:
			veloc_h += walk_accel*delta#clamp(veloc_h + walk_accel, walk_accel, INF)
		elif veloc_h > target_speed:
			veloc_h -= walk_accel*delta#clamp(veloc_h - walk_accel, 0, walk_accel)
		char_set_motion_horizontal(veloc_h)
#		char_set_motion_horizontal(speed)
		if target_speed > 0:
			$Sprite.flip_h = true
		elif target_speed < 0:
			$Sprite.flip_h = false
	char_do_movement(delta, 5)
	var target_rot = -CHAR_UP.angle() - PI/2
	if char_is_on_floor():
		target_rot += char_get_normal().angle() + PI/2
	$Sprite.rotation = Util.angle_to($Sprite.rotation, target_rot, delta * PI * 2)

func _on_NoticeArea_body_entered(body):
	# Get parent of body because body is the hitbox of the player, 
	# not the player itself
	var player = body.get_parent()
	players.append(player)

func _on_NoticeArea_body_exited(body):
	var player = body.get_parent()
	players.erase(player)
