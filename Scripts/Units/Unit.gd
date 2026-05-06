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

# Combat and multiplier attributes (all default to 1.0)
var combat_multiplier: float = 1.0  # Combat power multiplier (e.g., from Corn)
var movement_speed_multiplier: float = 1.0  # Movement speed multiplier (e.g., from Quinoa)
var transport_speed_multiplier: float = 1.0  # Transport speed multiplier (e.g., from Llama)

# Unit inventory/backpack system
var inventory: Dictionary = {}  # {"resource_type": amount}
const INVENTORY_CAPACITY = 5  # Max total resources in backpack

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

# Movement system (GDD 5.2.1 & 4.3)
var movement_lock_overlay: CanvasLayer = null  # Visual lock overlay

func calculate_movement_time(from_node: VillageNode, to_node: VillageNode) -> int:
	"""Calculate movement time between two nodes in turns (GDD 4.3 revised)
	- Same camera: 2 turns
	- Each camera crossing: +4 turns
	Delegates to GameMap for consistent calculation.
	"""
	if from_node == to_node:
		return 0
	
	if game_map:
		return game_map.get_movement_time_to_node(from_node, to_node)
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
	print("[Unit] %s started moving: %s -> %s, duration=%d" % [unit_name, current_node.location_name if current_node else "None", target.location_name if target else "None", movement_time])
	
	return true

func progress_movement() -> void:
	"""Progress movement by one turn. Called by TurnManager during auto_phase."""
	if unit_state != UnitState.MOVING or movement_time_remaining <= 0:
		return

	var before = movement_time_remaining
	
	movement_time_remaining -= 1
	print("[Unit] %s movement progress: %d -> %d" % [unit_name, before, movement_time_remaining])
	
	# Movement completed
	if movement_time_remaining <= 0:
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
	print("[Unit] %s movement completed: arrived at %s" % [unit_name, current_node.location_name if current_node else "None"])

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
		print("[Unit] %s arrived at %s -> state=%s, enemies=%d" % [
			unit_name,
			current_node.location_name,
			UnitState.keys()[unit_state],
			enemy_count
		])
		return
	
	print("[Unit] %s arrived at uncontrolled node %s -> ATTACKING, enemies=%d" % [unit_name, current_node.location_name, enemy_count])
	_resolve_node_combat_or_capture(current_node)

func _resolve_node_combat_or_capture(node: VillageNode) -> void:
	"""Set attacking state on hostile entry and register node combat.
	If no enemies are present, capture immediately."""
	if not node:
		return
	
	if _get_alive_enemy_count(node) == 0:
		print("[Unit] %s no enemies at %s, capturing immediately" % [unit_name, node.location_name])
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
		print("[Unit] WARNING: CombatSystem not found when %s entered %s" % [unit_name, node.location_name])
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
		print("[Unit] %s combat setup empty at %s (player=%d, enemy=%d), fallback capture check" % [unit_name, node.location_name, player_units.size(), enemy_units.size()])
		_capture_node_if_possible(node)
		return

	var combat = combat_system.get_combat_at_node(node)
	if not combat:
		print("[Unit] %s starting combat at %s (player=%d, enemy=%d)" % [unit_name, node.location_name, player_units.size(), enemy_units.size()])
		combat_system.start_combat(node, player_units, enemy_units)
		return

	# Merge newly arrived units or refreshed enemy list into ongoing combat.
	for player_unit in player_units:
		if player_unit not in combat.player_units:
			combat.player_units.append(player_unit)

	for enemy_unit in enemy_units:
		if enemy_unit not in combat.enemy_units:
			combat.enemy_units.append(enemy_unit)

	print("[Unit] %s joined existing combat at %s (combat player=%d, enemy=%d)" % [unit_name, node.location_name, combat.player_units.size(), combat.enemy_units.size()])

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

	print("[Unit] Node captured: %s (alive player units=%d)" % [node.location_name, _get_alive_player_count(node)])
	
	for player_unit in node.stationed_units:
		if player_unit and player_unit.is_alive and player_unit.unit_state != UnitState.MOVING:
			player_unit.set_unit_state(UnitState.STATIONED)

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
