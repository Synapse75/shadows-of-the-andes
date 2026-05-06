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
	print("[CombatSystem] Ready")

func start_combat(node: VillageNode, player_units: Array, enemy_units: Array) -> Combat:
	"""Start a new combat on a node"""
	if player_units.is_empty() or enemy_units.is_empty():
		print("[CombatSystem] start_combat skipped at %s (player=%d, enemy=%d)" % [node.location_name if node else "Unknown", player_units.size(), enemy_units.size()])
		return null

	var existing = get_combat_at_node(node)
	if existing:
		print("[CombatSystem] Existing combat reused at %s" % node.location_name)
		return existing
	
	var combat = Combat.new(node, player_units, enemy_units)
	active_combats.append(combat)
	combat_started.emit(combat)
	print("[CombatSystem] Combat started at %s (player=%d, enemy=%d)" % [node.location_name, player_units.size(), enemy_units.size()])
	
	return combat

func resolve_combat_turn(combat: Combat) -> void:
	"""Resolve one turn of combat (called at end of game turn)"""
	if combat.player_units.is_empty() or combat.enemy_units.is_empty():
		print("[CombatSystem] resolve skipped at %s, one side empty" % combat.combat_node.location_name)
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
		damage_per_enemy = int(total_player_attack / float(combat.enemy_units.size()))
	
	if combat.player_units.size() > 0:
		damage_per_player = int(total_enemy_attack / float(combat.player_units.size()))

	print("[CombatSystem] Turn %d at %s: p_total=%d, e_total=%d, dmg_to_enemy=%d, dmg_to_player=%d" % [
		combat.turn,
		combat.combat_node.location_name,
		total_player_attack,
		total_enemy_attack,
		damage_per_enemy,
		damage_per_player
	])
	
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
	print("[CombatSystem] After turn %d at %s: player_alive=%d, enemy_alive=%d, player_died=%d, enemy_died=%d" % [
		combat.turn,
		combat.combat_node.location_name,
		combat.player_units.size(),
		combat.enemy_units.size(),
		players_died_this_turn,
		enemies_died_this_turn
	])
	
	combat_resolved_turn.emit(combat, combat.turn)
	
	# Check if combat should end
	if combat.player_units.is_empty() or combat.enemy_units.is_empty():
		end_combat(combat)

func end_combat(combat: Combat) -> void:
	"""End combat and determine winner"""
	var player_won = combat.enemy_units.is_empty() and not combat.player_units.is_empty()
	var enemy_won = combat.player_units.is_empty() and not combat.enemy_units.is_empty()
	var mutual_destruction = combat.player_units.is_empty() and combat.enemy_units.is_empty()
	
	var result_text = ""
	if mutual_destruction:
		result_text = "Mutual Destruction"
	elif player_won:
		result_text = "Enemy Units Eliminated"
		_capture_node_for_player(combat)
	elif enemy_won:
		result_text = "Player Units Eliminated"
	else:
		result_text = "Unknown Outcome"
	
	active_combats.erase(combat)
	print("[CombatSystem] Combat ended at %s: %s" % [combat.combat_node.location_name, result_text])
	combat_ended.emit(combat)

func _capture_node_for_player(combat: Combat) -> void:
	"""Capture node for player immediately after enemies are eliminated."""
	if not combat or not combat.combat_node:
		return

	var node = combat.combat_node
	var game_map = get_tree().root.get_node_or_null("Main/SubViewportContainer/SubViewport/Map") as GameMap
	if game_map:
		game_map.occupy_node(node, true)
	else:
		node.set_control(true)
	print("[CombatSystem] Node captured by player: %s" % node.location_name)

	for unit in combat.player_units:
		if unit and unit.is_alive and unit.unit_state != Unit.UnitState.MOVING:
			unit.set_unit_state(Unit.UnitState.STATIONED)

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
	print("[CombatSystem] resolve_all_combats called, active=%d" % active_combats.size())
	var combats_copy = active_combats.duplicate()
	for combat in combats_copy:
		if combat in active_combats:  # Check in case it was removed
			resolve_combat_turn(combat)
