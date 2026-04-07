extends Unit
class_name RebelArmy

# Rebel Army specific properties
func _ready() -> void:
	unit_type = "rebel_army"
	max_satiety = 100
	current_satiety = 100
	max_health = 100
	current_health = 100
	attack_power = 30
	base_satiety_consumption = 10
	moving_satiety_consumption = 15
	
	super._ready()

func get_current_attack_power() -> int:
	"""Rebel Army has constant attack power of 30"""
	return 30
