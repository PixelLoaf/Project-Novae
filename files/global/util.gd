extends Node

func angle_distance(a, b):
	var mod = fmod(b - a, PI*2);
	return fmod(2*mod, PI*2) - mod;

func angle_lerp(from, to, weight):
	return from + angle_distance(from, to)*weight;

func angle_to(from, to, amount):
	var dis = angle_distance(from, to)
	if abs(dis) <= amount:
		return to
	#var weight = amount / dis
	return from + sign(dis)*amount