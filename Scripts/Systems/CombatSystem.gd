extends Node
class_name CombatSystem

# Combat system for resolving multi-unit battles

# Represents an active combat between two groups
class Combat:
	var player_units: Array[Unit] = []
	var enemy_units: Array[EnemyUnit] = []
	var combat_node: VillageNode
	var turn: int = 0
	
	func _init(node: VillageNode, p_units: Array, e_units: Array) -> void:
		combat_node = node
		player_units = p_units
		enemy_units = e_units

# Active combats on the map
var active_combats: Array[Combat] = []

signal combat_started(combat: Combat)
signal combat_ended(combat: Combat)
signal combat_resolved_turn(combat: Combat, turn: int)

func _ready() -> void:
	add_to_group("combat_system")

func start_combat(node: VillageNode, player_units: Array, enemy_units: Array) -> Combat:
	"""Start a new combat on a node"""
	if player_units.is_empty() or enemy_units.is_empty():
		return null
	
	var combat = Combat.new(node, player_units, enemy_units)
	active_combats.append(combat)
	combat_started.emit(combat)
	
	return combat

func resolve_combat_turn(combat: Combat) -> void:
	"""Resolve one turn of combat (called at end of game turn)"""
	if combat.player_units.is_empty() or combat.enemy_units.is_empty():
		end_combat(combat)
		return
	
	combat.turn += 1
	
	# Calculate total attack power for each side
	var total_player_attack = 0
	for unit in combat.player_units:
		if unit.is_alive:
			total_player_attack += unit.get_current_attack_power()
	
	var total_enemy_attack = 0
	for unit in combat.enemy_units:
		if unit.is_alive:
			total_enemy_attack += unit.get_current_attack_power()
	
	# Calculate damage per unit (integer division, floor)
	var damage_per_enemy = 0
	var damage_per_player = 0
	
	if combat.enemy_units.size() > 0:
		damage_per_enemy = int(total_player_attack / combat.enemy_units.size())
	
	if combat.player_units.size() > 0:
		damage_per_player = int(total_enemy_attack / combat.player_units.size())
	
	# Apply damage to all units
	var enemies_died_this_turn = 0
	for enemy in combat.enemy_units:
		if enemy.is_alive:
			enemy.take_damage(damage_per_enemy)
			if not enemy.is_alive:
				enemies_died_this_turn += 1
	
	var players_died_this_turn = 0
	for player_unit in combat.player_units:
		if player_unit.is_alive:
			player_unit.take_damage(damage_per_player)
			if not player_unit.is_alive:
				players_died_this_turn += 1
	
	# Remove dead units from combat
	combat.player_units = combat.player_units.filter(func(u): return u.is_alive)
	combat.enemy_units = combat.enemy_units.filter(func(u): return u.is_alive)
	
	combat_resolved_turn.emit(combat, combat.turn)
	
	# Check if combat should end
	if combat.player_units.is_empty() or combat.enemy_units.is_empty():
		end_combat(combat)

func end_combat(combat: Combat) -> void:
	"""End combat and determine winner"""
	var player_won = not combat.enemy_units.is_empty() and combat.player_units.is_empty()
	var enemy_won = not combat.player_units.is_empty() and combat.enemy_units.is_empty()
	var mutual_destruction = combat.player_units.is_empty() and combat.enemy_units.is_empty()
	
	var result_text = ""
	if mutual_destruction:
		result_text = "Mutual Destruction"
	elif player_won:
		result_text = "Enemy Units Eliminated"
	elif enemy_won:
		result_text = "Player Units Eliminated"
	else:
		result_text = "Unknown Outcome"
	
	active_combats.erase(combat)
	combat_ended.emit(combat)

func get_combat_at_node(node: VillageNode) -> Combat:
	"""Get active combat at a specific node"""
	for combat in active_combats:
		if combat.combat_node == node:
			return combat
	return null

func is_node_in_combat(node: VillageNode) -> bool:
	"""Check if node is currently in combat"""
	return get_combat_at_node(node) != null

func resolve_all_combats() -> void:
	"""Resolve one turn for all active combats (called at end of game turn)"""
	var combats_copy = active_combats.duplicate()
	for combat in combats_copy:
		if combat in active_combats:  # Check in case it was removed
			resolve_combat_turn(combat)

func process_player_entry(node: VillageNode) -> void:
	"""Handle player unit entering a node.
	- If node is uncontrolled and has no enemies: capture immediately.
	- If node is uncontrolled and has enemies: resolve one combat turn immediately.
	"""
	if not node:
		return

	# Only non-moving, alive player units on the node can participate or garrison.
	var player_units := _get_alive_player_combatants(node)
	if player_units.is_empty():
		return

	if node.control_by_player:
		_set_player_units_state(player_units, Unit.UnitState.STATIONED)
		return

	# Entering uncontrolled node puts units into attacking state.
	_set_player_units_state(player_units, Unit.UnitState.ATTACKING)

	var enemy_units := _get_alive_enemy_combatants(node)
	if enemy_units.is_empty():
		_capture_node(node)
		return

	var combat = get_combat_at_node(node)
	if combat == null:
		combat = start_combat(node, player_units, enemy_units)
	else:
		combat.player_units = player_units
		combat.enemy_units = enemy_units

	if combat:
		resolve_combat_turn(combat)

	_post_combat_update(node)

func _post_combat_update(node: VillageNode) -> void:
	"""Update control and player states after a combat turn."""
	var alive_players := _get_alive_player_combatants(node)
	var alive_enemies := _get_alive_enemy_combatants(node)

	if alive_enemies.is_empty() and not alive_players.is_empty():
		_capture_node(node)
		return

	if not alive_players.is_empty():
		node.set_control(false)
		_set_player_units_state(alive_players, Unit.UnitState.ATTACKING)

func _capture_node(node: VillageNode) -> void:
	"""Capture node for player and set local units to stationed."""
	node.set_control(true)
	var alive_players := _get_alive_player_combatants(node)
	_set_player_units_state(alive_players, Unit.UnitState.STATIONED)

func _get_alive_player_combatants(node: VillageNode) -> Array[Unit]:
	var units: Array[Unit] = []
	for unit in node.stationed_units:
		if unit and unit.is_alive and unit.unit_state != Unit.UnitState.MOVING:
			units.append(unit)
	return units

func _get_alive_enemy_combatants(node: VillageNode) -> Array[EnemyUnit]:
	var units: Array[EnemyUnit] = []
	for unit in node.enemy_units:
		if unit and unit.is_alive:
			units.append(unit)
	return units

func _set_player_units_state(units: Array[Unit], state: Unit.UnitState) -> void:
	for unit in units:
		if unit and unit.is_alive and unit.unit_state != Unit.UnitState.MOVING:
			unit.set_unit_state(state)
