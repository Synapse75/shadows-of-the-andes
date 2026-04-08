extends Node
class_name Unit

# Unit base properties
@export var unit_id: String
@export var unit_name: String

# Unit state enum
enum UnitState {
	MOVING,      # Moving state
	ATTACKING,   # Attacking (not moving + on uncontrolled village)
	STATIONED    # Stationed (not moving + on controlled village)
}

# Core attributes (to be defined by subclasses)
var unit_type: String = ""
var max_satiety: int = 100
var current_satiety: int = 100
var max_health: int = 100
var current_health: int = 100
var attack_power: int = 30
var base_satiety_consumption: int = 10  # Per turn when not moving
var moving_satiety_consumption: int = 15  # Per turn when moving

# Current state
var unit_state: UnitState = UnitState.STATIONED
var current_node: BaseNode = null
var is_alive: bool = true
var is_special: bool = false  # Special unit flag (leader, hero, etc.)

# Unit inventory/backpack system
var inventory: Dictionary = {}  # {"resource_type": amount}
const INVENTORY_CAPACITY = 5  # Max total resources in backpack

# Signals
signal unit_moved(from_node: BaseNode, to_node: BaseNode)
signal unit_state_changed(new_state: UnitState)
signal unit_damaged(damage: int, remaining_health: int)
signal unit_hungry(remaining_satiety: int)
signal unit_died
signal inventory_changed(new_inventory: Dictionary)

func _ready() -> void:
	add_to_group("units")
	if current_health == 0:  # Only initialize if not already set
		current_health = max_health
	if current_satiety == 0:  # Only initialize if not already set
		current_satiety = max_satiety
	# Auto-assign to parent BaseNode
	var parent = get_parent()
	if parent is BaseNode:
		assign_to_node(parent)

func get_unit_info() -> Dictionary:
	"""Return comprehensive unit information"""
	return {
		"id": unit_id,
		"name": unit_name,
		"type": unit_type,
		"state": UnitState.keys()[unit_state],
		"health": current_health,
		"max_health": max_health,
		"satiety": current_satiety,
		"max_satiety": max_satiety,
		"attack_power": get_current_attack_power(),
		"is_alive": is_alive,
		"current_node": current_node.location_name if current_node else "None",
		"inventory": inventory.duplicate(),
		"inventory_count": get_inventory_count(),
		"inventory_capacity": INVENTORY_CAPACITY
	}

func get_current_attack_power() -> int:
	"""Get current attack power (Female Corps doubles when stationed)"""
	return attack_power

func assign_to_node(node: BaseNode) -> void:
	"""Assign unit to node"""
	if current_node:
		current_node.remove_unit(self)
	current_node = node
	if node:
		node.add_unit(self)
	update_state()

func move_to_node(target_node: BaseNode) -> bool:
	"""Unit moves to another node"""
	if not current_node or not is_alive:
		return false
	
	# Check if adjacent
	if target_node not in current_node.neighbors:
		print("Nodes not adjacent, cannot move")
		return false
	
	var from_node = current_node
	assign_to_node(target_node)
	set_unit_state(UnitState.MOVING)
	unit_moved.emit(from_node, target_node)
	print("%s moved from %s to %s" % [unit_name, from_node.location_name, target_node.location_name])
	return true

func set_unit_state(new_state: UnitState) -> void:
	"""Set unit state"""
	if unit_state != new_state:
		unit_state = new_state
		unit_state_changed.emit(new_state)

func update_state() -> void:
	"""Update unit state based on location"""
	if not current_node:
		return
	
	if unit_state == UnitState.MOVING:
		# Will be updated when movement ends
		return
	
	# Determine state based on node control
	if current_node.control_by_player:
		set_unit_state(UnitState.STATIONED)
	else:
		set_unit_state(UnitState.ATTACKING)

func consume_satiety() -> void:
	"""Consume satiety based on current state (called each turn)"""
	if not is_alive:
		return
	
	var consumption = base_satiety_consumption
	if unit_state == UnitState.MOVING or unit_state == UnitState.ATTACKING:
		consumption = moving_satiety_consumption
	
	current_satiety -= consumption
	if current_satiety < 0:
		current_satiety = 0
	
	if current_satiety <= 0:
		die()
	else:
		unit_hungry.emit(current_satiety)

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

func heal(amount: int) -> void:
	"""Heal unit (from resources)"""
	if not is_alive:
		return
	
	current_health = min(current_health + amount, max_health)

func restore_satiety(amount: int) -> void:
	"""Restore satiety (from resources)"""
	if not is_alive:
		return
	
	current_satiety = min(current_satiety + amount, max_satiety)

func die() -> void:
	"""Unit dies"""
	if not is_alive:
		return
	
	is_alive = false
	if current_node:
		current_node.remove_unit(self)
	unit_died.emit()
	print("%s has died" % unit_name)

# Inventory Management
func get_inventory_count() -> int:
	"""Get total number of items in inventory"""
	var total = 0
	for resource_type in inventory:
		total += inventory[resource_type]
	return total

func can_add_to_inventory(amount: int) -> bool:
	"""Check if inventory has space for more items"""
	return get_inventory_count() + amount <= INVENTORY_CAPACITY

func add_to_inventory(resource_type: String, amount: int) -> int:
	"""Add resource to inventory. Returns amount actually added (capped at capacity).
	Example: if capacity allows 2 more items, returns 2 even if requested 5."""
	var current_count = get_inventory_count()
	var space_left = INVENTORY_CAPACITY - current_count
	var added = min(amount, space_left)
	
	if added > 0:
		if resource_type not in inventory:
			inventory[resource_type] = 0
		inventory[resource_type] += added
		inventory_changed.emit(inventory)
	
	return added

func remove_from_inventory(resource_type: String, amount: int) -> bool:
	"""Remove resource from inventory. Returns true if successful."""
	if resource_type not in inventory or inventory[resource_type] < amount:
		return false
	
	inventory[resource_type] -= amount
	if inventory[resource_type] == 0:
		inventory.erase(resource_type)
	
	inventory_changed.emit(inventory)
	return true

func get_inventory_info() -> Dictionary:
	"""Get formatted inventory information"""
	return {
		"inventory": inventory.duplicate(),
		"count": get_inventory_count(),
		"capacity": INVENTORY_CAPACITY,
		"space_left": INVENTORY_CAPACITY - get_inventory_count()
	}
