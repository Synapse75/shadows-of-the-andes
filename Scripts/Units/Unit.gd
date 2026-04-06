extends Node
class_name Unit

# Unit basic properties
@export var unit_id: String
@export var unit_name: String  # "Rebel", "Condemayta's Guard"
@export var unit_type: String  # "rebel" or "leader"
@export var strength: int = 10  # Base combat strength
@export var morale: float = 1.0  # Morale coefficient (0.6 ~ 1.2)
@export var is_special: bool = false

# Belonging node
var current_node: BaseNode = null

signal unit_moved(from_node: BaseNode, to_node: BaseNode)

func _ready() -> void:
	add_to_group("units")
	# Auto-assign to parent BaseNode
	var parent = get_parent()
	if parent is BaseNode:
		assign_to_node(parent)

func get_unit_info() -> Dictionary:
	"""Return unit information"""
	return {
		"id": unit_id,
		"name": unit_name,
		"type": unit_type,
		"strength": strength,
		"morale": morale,
		"is_special": is_special,
		"current_node": current_node.location_name if current_node else "None"
	}

func calculate_combat_power() -> float:
	"""Calculate combat power (considering morale)"""
	return strength * morale

func set_morale(new_morale: float) -> void:
	"""Set morale"""
	morale = clamp(new_morale, 0.6, 1.2)

func assign_to_node(node: BaseNode) -> void:
	"""Assign unit to node"""
	if current_node:
		current_node.remove_unit(self)
	current_node = node
	if node:
		node.add_unit(self)

func move_to_node(target_node: BaseNode) -> bool:
	"""Unit moves to another node"""
	if not current_node:
		return false
	
	# Check if adjacent
	if target_node not in current_node.neighbors:
		print("Nodes not adjacent, cannot move")
		return false
	
	var from_node = current_node
	assign_to_node(target_node)
	unit_moved.emit(from_node, target_node)
	print("%s 从 %s 移动到 %s" % [unit_name, from_node.location_name, target_node.location_name])
	return true
