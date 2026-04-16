extends GameResource
class_name Coca

func _init() -> void:
	resource_id = "coca"
	resource_name = "Coca (古柯)"
	resource_type = "coca"
	icon_path = "res://Sprites/coca.png"
	is_food = false
	is_transport = false
	altitude_type = "low"
	amount = 1

func get_display_name() -> String:
	return "Coca (+50 Healing)"

func apply_effect_to_unit(unit: Unit) -> void:
	"""Coca restores 50 health"""
	if unit and unit.is_alive:
		unit.heal(50)

func apply_effect_to_village(village: VillageNode) -> void:
	"""Coca has no direct effect on village"""
	pass
