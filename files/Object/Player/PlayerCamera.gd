extends Camera2D

onready var player = get_parent()

const DRAG_MARGIN_AIR_TOP = 0.75
const DRAG_MARGIN_AIR_BOTTOM = 0.25
const DRAG_MARGIN_FLOOR_TOP = -0.1
const DRAG_MARGIN_FLOOR_BOTTOM = 0.1
const DRAG_MARGIN_FACING_AWAY = 1.0
const DRAG_MARGIN_FACING_TOWARD = -0.2
const PLAYER_TEST_OFFSET = 150

var target_drag_margin_top
var target_drag_margin_left
var target_drag_margin_right
var target_drag_margin_bottom

func lerp_abs(from, to, speed):
	if from == to:
		return from
	speed = clamp(speed * (0.01 + abs(to-from)), 0, abs(to - from))
	if from < to:
		from += speed
	else:
		from -= speed
	return from

func _physics_process(delta):
	if not player.char_is_on_floor():
		target_drag_margin_bottom = DRAG_MARGIN_AIR_BOTTOM
		target_drag_margin_top = DRAG_MARGIN_AIR_TOP
	else:
		target_drag_margin_bottom = DRAG_MARGIN_FLOOR_BOTTOM
		target_drag_margin_top = DRAG_MARGIN_FLOOR_TOP
	var player_x = player.global_position.x
	var player_y = player.global_position.y
	var camera_x = get_camera_screen_center().x
	var camera_y = get_camera_screen_center().y
	if player_x - PLAYER_TEST_OFFSET > camera_x:
		target_drag_margin_left = DRAG_MARGIN_FACING_AWAY
		target_drag_margin_right = DRAG_MARGIN_FACING_TOWARD
	elif player_x + PLAYER_TEST_OFFSET < camera_x:
		target_drag_margin_left = DRAG_MARGIN_FACING_TOWARD
		target_drag_margin_right = DRAG_MARGIN_FACING_AWAY
	var window_size = get_viewport().get_size_override()
	if (window_size == Vector2()):
		window_size = get_viewport().size
	var player_rel_right = (player_x - camera_x) / (window_size.x / 2)
	var player_rel_bottom = (player_y - camera_y) / (window_size.y / 2)
	var player_rel_top = -player_rel_bottom
	var player_rel_left = -player_rel_right
	
	if player_rel_left > drag_margin_left:
		drag_margin_left = max(drag_margin_left, min(player_rel_left, target_drag_margin_left))
	if player_rel_top > drag_margin_top:
		drag_margin_top = max(drag_margin_top, min(player_rel_top, target_drag_margin_top))
	if player_rel_right < drag_margin_right:
		drag_margin_right = min(drag_margin_right, max(player_rel_right, target_drag_margin_right))
	if player_rel_bottom < drag_margin_bottom:
		drag_margin_bottom = min(drag_margin_bottom, max(player_rel_bottom, target_drag_margin_bottom))
	
	drag_margin_top = lerp_abs(drag_margin_top, target_drag_margin_top, delta * 6)
	drag_margin_left = lerp_abs(drag_margin_left, target_drag_margin_left, delta * 2)
	drag_margin_right = lerp_abs(drag_margin_right, target_drag_margin_right, delta * 2)
	drag_margin_bottom = lerp_abs(drag_margin_bottom, target_drag_margin_bottom, delta * 6)
	
	var maps = get_tree().get_nodes_in_group("map")
	if not maps.empty():
		var bounds = maps[0].get_bounds(global_position)
		limit_left = bounds.position.x
		limit_top = bounds.position.y
		limit_right = bounds.end.x
		limit_bottom = bounds.end.y
		maps[0].set_load_position(global_position)

func _ready():
	target_drag_margin_top = drag_margin_top
	target_drag_margin_left = drag_margin_left
	target_drag_margin_right = drag_margin_right
	target_drag_margin_bottom = drag_margin_bottom