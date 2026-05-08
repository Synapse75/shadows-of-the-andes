extends GameResource
class_name Corn

func _init() -> void:
	resource_id = "corn"
	resource_name = "Corn (玉米)"
	resource_type = "corn"
	icon_path = "res://Sprites/corn.png"
	is_food = true
	is_transport = false
	altitude_type = "middle"
	amount = 1

func get_display_name() -> String:
	return "Corn (+30 Satiety, ×1.2 Combat)"

func apply_effect_to_unit(unit: Unit) -> void:
	"""Corn restores 30 satiety and provides 1.2x combat multiplier for 1 turn"""
	if unit and unit.is_alive:
		unit.restore_satiety(30)
		unit.combat_multiplier = 1.2
		unit.combat_multiplier_turns = 1

func apply_effect_to_village(village: VillageNode) -> void:
	"""Corn has no direct effect on village production"""
	pass
