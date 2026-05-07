extends Unit
class_name RebelArmy

# Rebel Army specific properties
func _init() -> void:
	unit_id = "rebel_army_" + str(randi())
	unit_type = "rebel_army"
	max_satiety = 100
	current_satiety = 100
	max_health = 100
	current_health = 100
	attack_power = 30
	base_satiety_consumption = 10
	moving_satiety_consumption = 15
	
	# Initialize all multipliers to 1.0 (no modifiers by default)
	combat_multiplier = 1.0
	movement_speed_multiplier = 1.0
	transport_speed_multiplier = 1.0
	
	is_special = false

func _ready() -> void:
	super._ready()

func get_current_attack_power() -> int:
	"""Rebel Army has constant attack power of 30"""
	return 30
