extends Node
class_name EnemyUnit

# Enemy Unit basic properties
@export var unit_id: String
@export var unit_name: String

# Core attributes
var unit_type: String = "enemy"
var max_health: int = 80
var current_health: int = 80
var attack_power: int = 25
var current_node: VillageNode = null
var is_alive: bool = true

# Signals
signal unit_moved(from_node: VillageNode, to_node: VillageNode)
signal unit_damaged(damage: int, remaining_health: int)
signal unit_died

func _init() -> void:
	unit_type = "enemy"
	max_health = 80
	current_health = 80
	attack_power = 25

func _ready() -> void:
	add_to_group("enemy_units")
	if unit_name.strip_edges().is_empty():
		unit_name = UnitNamePool.draw_name()
	current_health = max_health
	# Auto-assign to parent VillageNode
	var parent = get_parent()
	if parent is VillageNode:
		assign_to_node(parent)

func get_unit_info() -> Dictionary:
	"""Return comprehensive enemy unit information"""
	return {
		"id": unit_id,
		"name": unit_name,
		"type": unit_type,
		"health": current_health,
		"max_health": max_health,
		"attack_power": attack_power,
		"is_alive": is_alive,
		"current_node": current_node.location_name if current_node else "None"
	}

func assign_to_node(node: VillageNode) -> void:
	"""Assign unit to node"""
	if current_node:
		current_node.remove_enemy_unit(self)
	current_node = node
	if node:
		node.add_enemy_unit(self)

func move_to_node(target_node: VillageNode) -> bool:
	"""Unit moves to another node"""
	if not current_node or not is_alive or not target_node:
		return false
	
	# All nodes are valid targets (no neighbor restriction)
	
	var from_node = current_node
	assign_to_node(target_node)
	unit_moved.emit(from_node, target_node)
	return true

func get_current_attack_power() -> int:
	"""Enemy unit has constant attack power of 25"""
	return attack_power

func take_damage(damage: int) -> void:
	"""Take damage (only during combat)"""
	if not is_alive:
		return
	
	current_health -= damage
	if current_health < 0:
		current_health = 0
	
	if current_health <= 0:
		die()
	else:
		unit_damaged.emit(damage, current_health)

func die() -> void:
	"""Unit dies"""
	if not is_alive:
		return
	
	is_alive = false
	if current_node:
		current_node.remove_enemy_unit(self)
	MessageLog.add_message("Enemy unit died: %s" % unit_name, "error")
	unit_died.emit()
