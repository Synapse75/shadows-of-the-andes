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
var current_node: VillageNode = null
var origin_village: VillageNode = null  # The village this unit belongs to
var is_alive: bool = true
var is_special: bool = false  # Special unit flag (leader, hero, etc.)
var has_mount: bool = false  # Whether unit has a llama mount equipped

# Combat and multiplier attributes (all default to 1.0)
var combat_multiplier: float = 1.0  # Combat power multiplier (e.g., from Corn)
var movement_speed_multiplier: float = 1.0  # Movement speed multiplier (e.g., from Quinoa)
var transport_speed_multiplier: float = 1.0  # Transport speed multiplier (e.g., from Llama)
var combat_multiplier_turns: int = 0  # Turns remaining for combat bonus
var movement_speed_turns: int = 0  # Turns remaining for speed bonus

# Unit inventory/backpack system
var inventory: Dictionary = {}  # {"resource_type": amount}
const INVENTORY_CAPACITY = 9999  # No limit

# Movement system (GDD 5.2.1 & 4.3)
var target_node: VillageNode = null  # Target node for movement
var movement_time_remaining: int = 0  # Turns remaining for current movement
var is_locked: bool = false  # Locked during movement (cannot be reassigned)
var game_map: GameMap = null  # Cached GameMap reference

# Signals
signal unit_moved(from_node: VillageNode, to_node: VillageNode)
signal unit_state_changed(new_state: UnitState)
signal unit_damaged(damage: int, remaining_health: int)
signal unit_hungry(remaining_satiety: int)
signal unit_died
signal inventory_changed(new_inventory: Dictionary)
signal movement_started(target: VillageNode, duration: int)
signal movement_completed

func _ready() -> void:
	add_to_group("units")
	if unit_name.strip_edges().is_empty():
		unit_name = UnitNamePool.draw_name()
	if current_health == 0:  # Only initialize if not already set
		current_health = max_health
	if current_satiety == 0:  # Only initialize if not already set
		current_satiety = max_satiety
	# Cache GameMap reference
	game_map = get_tree().root.get_node_or_null("Main/SubViewportContainer/SubViewport/Map") as GameMap
	# Auto-assign to parent VillageNode
	var parent = get_parent()
	if parent is VillageNode:
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

func get_current_satiety_consumption() -> int:
	"""Get current satiety consumption based on unit state
	- Stationed: -10 per turn
	- Moving/Attacking: -15 per turn
	"""
	if unit_state == UnitState.STATIONED:
		return -10
	else:  # MOVING or ATTACKING
		return -15

func assign_to_node(node: VillageNode) -> void:
	"""Assign unit to node"""
	if current_node:
		current_node.remove_unit(self)
	current_node = node
	if node:
		node.add_unit(self)
	update_state()

func move_to_node(destination_node: VillageNode) -> bool:
	"""Unit moves to another node"""
	if not current_node or not is_alive or not destination_node:
		return false
	
	# All nodes are valid targets (no neighbor restriction)
	
	var from_node = current_node
	assign_to_node(destination_node)
	set_unit_state(UnitState.MOVING)
	unit_moved.emit(from_node, destination_node)
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
		if current_satiety < 50:
			_auto_consume_food()
		if current_health < 50:
			_auto_consume_healing()

func update_bonus_turns() -> void:
	"""Update bonus effect duration each turn"""
	if combat_multiplier_turns > 0:
		combat_multiplier_turns -= 1
		if combat_multiplier_turns == 0:
			combat_multiplier = 1.0
	
	if movement_speed_turns > 0:
		movement_speed_turns -= 1
		if movement_speed_turns == 0:
			if has_mount:
				movement_speed_multiplier = 2.0
			else:
				movement_speed_multiplier = 1.0

func _auto_consume_food() -> void:
	"""Auto consume food when satiety < 50. Priority: controlled village -> inventory"""
	if current_satiety >= 50:
		return
	
	var food_types = ["potato", "corn", "quinoa"]
	var restored = 0
	
	for food in food_types:
		if current_satiety >= 50:
			break
		restored = _try_consume_food(food)
		current_satiety += restored
		current_satiety = min(current_satiety, max_satiety)

func _auto_consume_healing() -> void:
	"""Auto consume resources when health < 50. Priority: coca -> quinoa"""
	if current_health >= 50:
		return
	
	var heal_types = ["coca", "quinoa"]
	var restored = 0
	
	for heal_type in heal_types:
		if current_health >= 50:
			break
		restored = _try_consume_healing(heal_type)
		current_health += restored
		current_health = min(current_health, max_health)

func _try_consume_food(food_type: String) -> int:
	"""Try to consume food from village or inventory. Returns amount restored."""
	var restore_amount = 0
	match food_type:
		"potato":
			restore_amount = 50
		"corn":
			restore_amount = 30
		"quinoa":
			restore_amount = 20
	
	if current_node and current_node.control_by_player:
		if current_node.resources.get(food_type, 0) > 0:
			current_node.remove_resource(food_type, 1)
			return restore_amount
	
	if inventory.get(food_type, 0) > 0:
		remove_from_inventory(food_type, 1)
		return restore_amount
	
	return 0

func _try_consume_healing(heal_type: String) -> int:
	"""Try to consume healing resource from village or inventory. Returns amount healed."""
	var heal_amount = 0
	match heal_type:
		"coca":
			heal_amount = 50
		"quinoa":
			heal_amount = 20
	
	if current_node and current_node.control_by_player:
		if current_node.resources.get(heal_type, 0) > 0:
			current_node.remove_resource(heal_type, 1)
			return heal_amount
	
	if inventory.get(heal_type, 0) > 0:
		remove_from_inventory(heal_type, 1)
		return heal_amount
	
	return 0

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

func set_attack_power(amount: int) -> void:
	"""Set attack power"""
	attack_power = max(0, amount)

func set_movement_speed_multiplier(multiplier: float) -> void:
	"""Set movement speed multiplier"""
	movement_speed_multiplier = max(0.0, multiplier)

func die() -> void:
	"""Unit dies"""
	if not is_alive:
		return
	
	is_alive = false
	inventory.clear()
	has_mount = false
	inventory_changed.emit(inventory)
	
	if current_node:
		current_node.remove_unit(self)
	MessageLog.add_message("Your unit died: %s" % unit_name, "error")
	unit_died.emit()

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
	# Special handling for llama (mount) - stored in has_mount, not in inventory dict
	if resource_type == "llama":
		if has_mount:
			return 0  # Already has mount
		has_mount = true
		movement_speed_multiplier = 2.0  # Llama doubles base speed
		inventory_changed.emit(inventory)
		return 1
	
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

# Movement system (GDD 5.2.1 & 4.3)
var movement_lock_overlay: CanvasLayer = null  # Visual lock overlay

func calculate_movement_time(from_node: VillageNode, to_node: VillageNode) -> int:
	"""Calculate movement time between two nodes in turns (GDD 4.3 revised)
	- Same camera: 2 turns
	- Each camera crossing: +4 turns
	Applies movement speed multiplier (llama mount x2, quinoa x1.2).
	"""
	if from_node == to_node:
		return 0
	
	if game_map:
		var base_time = game_map.get_movement_time_to_node(from_node, to_node)
		return max(1, int(base_time / movement_speed_multiplier))
	else:
		# Fallback if GameMap not found
		return 2

func start_movement(target: VillageNode) -> bool:
	"""Start movement to target node. Validates adjacency via neighbors array.
	Returns true if movement started successfully."""
	
	# Check if already moving
	if unit_state == UnitState.MOVING:
		push_error("Unit %s is already moving" % unit_name)
		return false
	
	# Calculate movement time
	var movement_time = calculate_movement_time(current_node, target)
	if movement_time == 0:
		return false
	
	# Update state
	target_node = target
	movement_time_remaining = movement_time
	is_locked = true
	unit_state = UnitState.MOVING
	
	# Create visual lock overlay
	_create_movement_lock_overlay()
	
	# Emit signals
	unit_state_changed.emit(unit_state)
	movement_started.emit(target, movement_time)
	
	return true

func progress_movement() -> bool:
	"""Progress movement by one turn. Returns true if movement completed."""
	if unit_state != UnitState.MOVING or movement_time_remaining <= 0:
		return false

	movement_time_remaining -= 1
	
	if movement_time_remaining <= 0:
		return true
	return false

func handle_arrival_completion() -> void:
	"""Handle movement completion - called after all units progress in a turn."""
	complete_movement()

func complete_movement() -> void:
	"""Complete movement and unlock unit."""
	var from_node = current_node
	var arrived_node: VillageNode = target_node
	
	if target_node:
		# Update current node
		assign_to_node(target_node)
		
		# Emit signal
		unit_moved.emit(from_node, arrived_node)
		movement_completed.emit()
	
	# Clear movement state
	target_node = null
	movement_time_remaining = 0
	is_locked = false
	# Movement finished: leave MOVING state before arrival state evaluation.
	set_unit_state(UnitState.STATIONED)
	
	# Remove visual lock overlay
	_remove_movement_lock_overlay()
	
	# On arrival, immediately resolve state/combat/capture logic.
	_handle_arrival_state_and_combat()

func unload_inventory_to_node(node: VillageNode) -> void:
	"""Unload all resources except llama to destination node."""
	if not node:
		return
	
	for resource_type in inventory.keys():
		if resource_type == "llama":
			continue
		
		var amount = inventory.get(resource_type, 0)
		if amount > 0:
			node.add_resource(resource_type, amount)
	
	inventory.clear()
	inventory_changed.emit(inventory)

func _handle_arrival_state_and_combat() -> void:
	"""Apply arrival rules: attacking on uncontrolled nodes, immediate capture if no enemies,
	or resolve one combat round immediately if enemies are present."""
	if not current_node or not is_alive:
		return
	
	# Determine baseline state from node control.
	update_state()
	var enemy_count = _get_alive_enemy_count(current_node)
	
	# Controlled node: arrive as stationed, no combat.
	if unit_state != UnitState.ATTACKING:
		unload_inventory_to_node(current_node)
		return
	
	_resolve_node_combat_or_capture(current_node)

func _resolve_node_combat_or_capture(node: VillageNode) -> void:
	"""Set attacking state on hostile entry and register node combat.
	If no enemies are present, capture immediately."""
	if not node:
		return
	
	if _get_alive_enemy_count(node) == 0:
		_capture_node_if_possible(node)
		return
	
	# Node with enemy presence must be uncontrolled and all non-moving player units are attacking.
	if game_map:
		game_map.occupy_node(node, false)
	else:
		node.set_control(false)
	
	for player_unit in node.stationed_units:
		if player_unit and player_unit.is_alive and player_unit.unit_state != UnitState.MOVING:
			player_unit.set_unit_state(UnitState.ATTACKING)
	
	var combat_system = _get_combat_system()
	if not combat_system:
		return

	var player_units: Array[Unit] = []
	for player_unit in node.stationed_units:
		if player_unit and player_unit.is_alive and player_unit.unit_state != UnitState.MOVING:
			player_units.append(player_unit)
	
	var enemy_units: Array[EnemyUnit] = []
	for enemy_unit in node.enemy_units:
		if enemy_unit and enemy_unit.is_alive:
			enemy_units.append(enemy_unit)
	
	if player_units.is_empty() or enemy_units.is_empty():
		_capture_node_if_possible(node)
		return

	var combat = combat_system.get_combat_at_node(node)
	if not combat:
		combat_system.start_combat(node, player_units, enemy_units)
		return

	# Merge newly arrived units or refreshed enemy list into ongoing combat.
	for player_unit in player_units:
		if player_unit not in combat.player_units:
			combat.player_units.append(player_unit)

	for enemy_unit in enemy_units:
		if enemy_unit not in combat.enemy_units:
			combat.enemy_units.append(enemy_unit)

func _capture_node_if_possible(node: VillageNode) -> void:
	"""Capture node for player if at least one player unit survives there, then station units."""
	if not node:
		return
	
	if _get_alive_player_count(node) == 0:
		return
	
	if game_map:
		game_map.occupy_node(node, true)
	else:
		node.set_control(true)

	for player_unit in node.stationed_units:
		if player_unit and player_unit.is_alive and player_unit.unit_state != UnitState.MOVING:
			player_unit.set_unit_state(UnitState.STATIONED)
			player_unit.unload_inventory_to_node(node)

func _get_alive_player_count(node: VillageNode) -> int:
	var alive := 0
	for player_unit in node.stationed_units:
		if player_unit and player_unit.is_alive:
			alive += 1
	return alive

func _get_alive_enemy_count(node: VillageNode) -> int:
	var alive := 0
	for enemy_unit in node.enemy_units:
		if enemy_unit and enemy_unit.is_alive:
			alive += 1
	return alive

func _get_combat_system() -> CombatSystem:
	return get_tree().root.get_node_or_null("Main/Systems/CombatSystem") as CombatSystem

func _create_movement_lock_overlay() -> void:
	"""Create a semi-transparent overlay showing 'Moving' text (GDD 5.2.1)"""
	# This overlay would be visible on the unit's display
	# For now, we store the information that the unit is locked
	# Visual representation will be handled by UI when displaying unit info
	pass

func _remove_movement_lock_overlay() -> void:
	"""Remove the movement lock overlay"""
	if movement_lock_overlay:
		movement_lock_overlay.queue_free()
		movement_lock_overlay = null
