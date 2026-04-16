extends Unit
class_name FemaleCorps

# Female Corps specific properties - initialized at class level
func _init() -> void:
	unit_id = "female_corps_" + str(randi())
	unit_name = "Female Corps"
	unit_type = "female_corps"
	max_satiety = 100
	current_satiety = 100
	max_health = 80
	current_health = 80
	attack_power = 20
	base_satiety_consumption = 10
	moving_satiety_consumption = 15
	
	# Initialize all multipliers to 1.0
	combat_multiplier = 1.0
	movement_speed_multiplier = 1.0
	transport_speed_multiplier = 1.0
	
	is_special = false

func _ready() -> void:
	super._ready()

func get_current_attack_power() -> int:
	"""Female Corps attack power: 20 normally, 40 when stationed"""
	if unit_state == UnitState.STATIONED:
		return attack_power * 2
	return attack_power
