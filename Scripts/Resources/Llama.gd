extends GameResource
class_name Llama

func _init() -> void:
	resource_id = "llama"
	resource_name = "Llama (羊驼)"
	resource_type = "llama"
	icon_path = "res://Sprites/llama.png"
	is_food = false
	is_transport = true
	altitude_type = "high"
	amount = 1

func get_display_name() -> String:
	return "Llama (×2 Transport Speed)"

func apply_effect_to_unit(unit: Unit) -> void:
	"""Llama increases transport speed by 2x"""
	if unit:
		unit.transport_speed_multiplier = 2.0

func apply_effect_to_village(village: VillageNode) -> void:
	"""Llama has no direct effect on village"""
	pass
