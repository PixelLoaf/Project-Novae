extends Node2D

func _on_attack(body, attack):
	if attack.count > 1:
		return
	if not get_parent().char_is_on_floor():
		get_parent().char_velocity = Vector2(0, -50)
		get_parent().char_ignore_gravity_timer = attack.length
	else:
		get_parent().char_velocity = Vector2()
	if get_parent().player_attack_current != null:
		get_parent().player_attack_combo = (get_parent().player_attack_combo + 1) % get_parent().player_attack_current.scenes.size()