extends GameResource
class_name Quinoa

# Quinoa effect duration
var effect_duration: int = 3  # 3 turns
var remaining_turns: int = 0

func _init() -> void:
	resource_id = "quinoa"
	resource_name = "Quinoa (藜麦)"
	resource_type = "quinoa"
	icon_path = "res://Sprites/quinoa.png"
	is_food = true
	is_transport = false
	altitude_type = "middle"
	amount = 1

func get_display_name() -> String:
	return "Quinoa (+20 Satiety, +20 Healing, ×1.2 Speed, 3 turns)"

func apply_effect_to_unit(unit: Unit) -> void:
	"""Quinoa restores 20 satiety, 20 healing, and provides 1.2x speed for 3 turns"""
	if unit and unit.is_alive:
		unit.restore_satiety(20)
		unit.heal(20)
		unit.movement_speed_multiplier = 1.2
		# Note: Duration tracking would need to be implemented in Unit class
		remaining_turns = effect_duration

func apply_effect_to_village(village: VillageNode) -> void:
	"""Quinoa increases village production speed by 1.2x for 3 turns"""
	if village:
		# Store original multiplier if not already stored
		if not village.has_meta("original_production_multiplier"):
			village.set_meta("original_production_multiplier", village.resource_generation_multiplier)
		
		village.resource_generation_multiplier = 1.2
		remaining_turns = effect_duration
