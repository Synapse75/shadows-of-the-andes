extends Node
class_name GameResource

# Base Resource class for all in-game resources
# Resources are items that can be stored, transported, and consumed

@export var resource_id: String = ""
@export var resource_name: String = ""
@export var resource_type: String = ""  # "potato", "llama", "corn", "quinoa", "coca"
@export var icon_path: String = ""
@export var amount: int = 1

# Resource classification
var is_food: bool = false  # Can be consumed by units or villages
var is_transport: bool = false  # Affects transport speed
var altitude_type: String = ""  # "high", "middle", "low"

func _ready() -> void:
	add_to_group("resources")

func get_resource_info() -> Dictionary:
	"""Return comprehensive resource information"""
	return {
		"id": resource_id,
		"name": resource_name,
		"type": resource_type,
		"amount": amount,
		"is_food": is_food,
		"is_transport": is_transport,
		"altitude_type": altitude_type,
		"icon_path": icon_path
	}

func get_display_name() -> String:
	"""Get localized display name"""
	return resource_name

func get_icon() -> Texture2D:
	"""Get resource icon texture"""
	if icon_path and ResourceLoader.exists(icon_path):
		return ResourceLoader.load(icon_path)
	return null

func can_be_consumed_by_village() -> bool:
	"""Check if village can consume this resource"""
	return is_food

func can_be_consumed_by_unit() -> bool:
	"""Check if unit can consume this resource"""
	return is_food

func apply_effect_to_unit(unit: Unit) -> void:
	"""Apply resource effect to unit"""
	pass

func apply_effect_to_village(village: VillageNode) -> void:
	"""Apply resource effect to village"""
	pass

func duplicate_resource(new_amount: int = 1) -> GameResource:
	"""Create a duplicate of this resource with specified amount"""
	var new_resource = duplicate()
	new_resource.amount = new_amount
	return new_resource
