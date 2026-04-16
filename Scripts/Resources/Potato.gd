extends GameResource
class_name Potato

func _init() -> void:
	resource_id = "potato"
	resource_name = "Potato (土豆)"
	resource_type = "potato"
	icon_path = "res://Sprites/potato.png"
	is_food = true
	is_transport = false
	altitude_type = "high"
	amount = 1

func get_display_name() -> String:
	return "Potato (+50 Satiety)"

func apply_effect_to_unit(unit: Unit) -> void:
	"""Potato restores 50 satiety"""
	if unit and unit.is_alive:
		unit.restore_satiety(50)

func apply_effect_to_village(village: VillageNode) -> void:
	"""Potato has no direct effect on village production"""
	pass
