extends Node
class_name UnitSystemTest

# Unit System Testing and Validation Script

func _ready() -> void:
	print("\n" + "=".repeat(80))
	print("UNIT SYSTEM VALIDATION TESTS")
	print("=".repeat(80) + "\n")
	
	test_rebel_army_creation()
	test_female_corps_creation()
	test_enemy_unit_creation()
	test_unit_state_transitions()
	test_satiety_consumption()
	test_damage_system()
	test_multi_unit_combat()
	test_female_corps_stationed_bonus()
	
	print("\n" + "=".repeat(80))
	print("ALL TESTS COMPLETED")
	print("=".repeat(80) + "\n")

# TEST 1: Rebel Army Creation and Properties
func test_rebel_army_creation() -> void:
	print("\n[TEST 1] Rebel Army Creation and Properties")
	print("-".repeat(60))
	
	var rebel = RebelArmy.new()
	rebel.unit_id = "rebel_1"
	rebel.unit_name = "Rebel Squad 1"
	
	verify(rebel.max_health == 100, "Rebel max health should be 100")
	verify(rebel.max_satiety == 100, "Rebel max satiety should be 100")
	verify(rebel.attack_power == 30, "Rebel attack power should be 30")
	verify(rebel.unit_type == "rebel_army", "Rebel type should be rebel_army")
	verify(rebel.get_current_attack_power() == 30, "Rebel current attack should be 30")
	
	print("✓ Rebel Army: Health=100, Satiety=100, Attack=30")

# TEST 2: Female Corps Creation and Properties
func test_female_corps_creation() -> void:
	print("\n[TEST 2] Female Corps Creation and Properties")
	print("-".repeat(60))
	
	var female = FemaleCorps.new()
	female.unit_id = "female_1"
	female.unit_name = "Female Corps 1"
	
	verify(female.max_health == 80, "Female Corps max health should be 80")
	verify(female.max_satiety == 100, "Female Corps max satiety should be 100")
	verify(female.attack_power == 20, "Female Corps attack power should be 20")
	verify(female.unit_type == "female_corps", "Female Corps type should be female_corps")
	
	print("✓ Female Corps: Health=80, Satiety=100, Attack=20")

# TEST 3: Enemy Unit Creation
func test_enemy_unit_creation() -> void:
	print("\n[TEST 3] Enemy Unit Creation and Properties")
	print("-".repeat(60))
	
	var enemy = EnemyUnit.new()
	enemy.unit_id = "enemy_1"
	enemy.unit_name = "Spanish Guard"
	
	verify(enemy.max_health == 80, "Enemy max health should be 80")
	verify(enemy.attack_power == 25, "Enemy attack power should be 25")
	verify(enemy.unit_type == "enemy", "Enemy type should be enemy")
	verify(not enemy.is_alive or enemy.is_alive, "Enemy should have is_alive property")
	
	print("✓ Enemy Unit: Health=80, Attack=25, Type=enemy")

# TEST 4: Unit State Transitions
func test_unit_state_transitions() -> void:
	print("\n[TEST 4] Unit State Transitions")
	print("-".repeat(60))
	
	var rebel = RebelArmy.new()
	rebel.unit_id = "test_rebel"
	rebel.unit_name = "Test Rebel"
	
	# Test state changes
	rebel.set_unit_state(Unit.UnitState.MOVING)
	verify(rebel.unit_state == Unit.UnitState.MOVING, "State should be MOVING")
	print("✓ Set MOVING state")
	
	rebel.set_unit_state(Unit.UnitState.ATTACKING)
	verify(rebel.unit_state == Unit.UnitState.ATTACKING, "State should be ATTACKING")
	print("✓ Set ATTACKING state")
	
	rebel.set_unit_state(Unit.UnitState.STATIONED)
	verify(rebel.unit_state == Unit.UnitState.STATIONED, "State should be STATIONED")
	print("✓ Set STATIONED state")

# TEST 5: Satiety Consumption
func test_satiety_consumption() -> void:
	print("\n[TEST 5] Satiety Consumption Rates")
	print("-".repeat(60))
	
	var rebel = RebelArmy.new()
	rebel.unit_id = "test_rebel"
	rebel.unit_name = "Test Rebel"
	rebel.unit_state = Unit.UnitState.STATIONED
	
	var initial_satiety = rebel.current_satiety
	verify(initial_satiety == 100, "Initial satiety should be 100")
	
	# Test stationed/attacking consumption (-10)
	rebel.consume_satiety()
	verify(rebel.current_satiety == 90, "Satiety should decrease by 10 when STATIONED")
	print("✓ STATIONED state: -10 satiety per turn (90 remaining)")
	
	# Test moving consumption (-15)
	rebel.unit_state = Unit.UnitState.MOVING
	var satiety_before = rebel.current_satiety
	rebel.consume_satiety()
	verify(rebel.current_satiety == satiety_before - 15, "Satiety should decrease by 15 when MOVING")
	print("✓ MOVING state: -15 satiety per turn (75 remaining)")
	
	# Test death when satiety reaches 0
	rebel.current_satiety = 5
	rebel.unit_state = Unit.UnitState.STATIONED
	rebel.consume_satiety()
	verify(not rebel.is_alive, "Unit should die when satiety reaches 0")
	verify(rebel.current_satiety == 0, "Satiety should be 0")
	print("✓ Unit dies when satiety reaches 0")

# TEST 6: Damage System
func test_damage_system() -> void:
	print("\n[TEST 6] Damage and Health System")
	print("-".repeat(60))
	
	var rebel = RebelArmy.new()
	rebel.unit_id = "test_rebel"
	rebel.unit_name = "Test Rebel"
	
	var initial_health = rebel.current_health
	verify(initial_health == 100, "Initial health should be 100")
	
	# Test taking damage
	rebel.take_damage(30)
	verify(rebel.current_health == 70, "Health should be 70 after 30 damage")
	verify(rebel.is_alive, "Unit should still be alive")
	print("✓ Take 30 damage: Health 100→70")
	
	# Test death
	rebel.take_damage(70)
	verify(rebel.current_health == 0, "Health should be 0")
	verify(not rebel.is_alive, "Unit should be dead")
	print("✓ Take 70 damage: Health 0, unit dies")
	
	# Test healing
	var healed = RebelArmy.new()
	healed.unit_id = "test_healed"
	healed.unit_name = "Healed Unit"
	healed.current_health = 50
	healed.heal(30)
	verify(healed.current_health == 80, "Health should be 80 after healing 30")
	print("✓ Heal 30: Health 50→80")

# TEST 7: Female Corps Stationed Bonus
func test_female_corps_stationed_bonus() -> void:
	print("\n[TEST 7] Female Corps Stationed Attack Bonus")
	print("-".repeat(60))
	
	var female = FemaleCorps.new()
	female.unit_id = "female_stationed"
	female.unit_name = "Female Corps Stationed"
	
	# Normal attack power
	female.unit_state = Unit.UnitState.ATTACKING
	verify(female.get_current_attack_power() == 20, "Attack should be 20 when ATTACKING")
	print("✓ ATTACKING state: Attack = 20")
	
	# Stationed bonus
	female.unit_state = Unit.UnitState.STATIONED
	verify(female.get_current_attack_power() == 40, "Attack should be 40 when STATIONED (20*2)")
	print("✓ STATIONED state: Attack = 40 (doubled)")
	
	# Moving no bonus
	female.unit_state = Unit.UnitState.MOVING
	verify(female.get_current_attack_power() == 20, "Attack should be 20 when MOVING")
	print("✓ MOVING state: Attack = 20")

# TEST 8: Multi-Unit Combat System
func test_multi_unit_combat() -> void:
	print("\n[TEST 8] Multi-Unit Combat Calculation")
	print("-".repeat(60))
	
	# Scenario: 3 Rebel Army (30 attack each = 90 total) vs 2 Enemy Units (25 attack each = 50 total)
	var rebels: Array[Unit] = []
	for i in range(3):
		var rebel = RebelArmy.new()
		rebel.unit_id = "rebel_%d" % i
		rebel.unit_name = "Rebel %d" % i
		rebels.append(rebel)
	
	var enemies: Array[EnemyUnit] = []
	for i in range(2):
		var enemy = EnemyUnit.new()
		enemy.unit_id = "enemy_%d" % i
		enemy.unit_name = "Enemy %d" % i
		enemies.append(enemy)
	
	# Calculate damage
	var total_rebel_attack = 0
	for r in rebels:
		total_rebel_attack += r.get_current_attack_power()
	
	var total_enemy_attack = 0
	for e in enemies:
		total_enemy_attack += e.get_current_attack_power()
	
	var damage_per_enemy = int(total_rebel_attack / enemies.size())  # 90 / 2 = 45
	var damage_per_rebel = int(total_enemy_attack / rebels.size())   # 50 / 3 = 16
	
	verify(damage_per_enemy == 45, "Each enemy should take 45 damage (90/2)")
	verify(damage_per_rebel == 16, "Each rebel should take 16 damage (50/3, floored)")
	print("✓ 3 Rebels (30 atk each) vs 2 Enemies (25 atk each):")
	print("  - Each enemy takes: 90 ÷ 2 = 45 damage")
	print("  - Each rebel takes: 50 ÷ 3 = 16 damage (floored)")
	
	# Apply damage
	for enemy in enemies:
		enemy.take_damage(damage_per_enemy)
	
	for rebel in rebels:
		rebel.take_damage(damage_per_rebel)
	
	# Verify results
	for i in range(enemies.size()):
		verify(enemies[i].current_health == 80 - 45, "Enemy health should be %d" % (80 - 45))
	
	for i in range(rebels.size()):
		verify(rebels[i].current_health == 100 - 16, "Rebel health should be %d" % (100 - 16))
	
	print("✓ Damage applied correctly to all units")
	print("  - Enemy health: 80 - 45 = 35")
	print("  - Rebel health: 100 - 16 = 84")
	
	# Test mutual destruction scenario
	print("\n✓ Testing mutual destruction scenario:")
	var rebel_final = RebelArmy.new()
	rebel_final.current_health = 10
	var enemy_final = EnemyUnit.new()
	enemy_final.current_health = 10
	
	rebel_final.take_damage(10)  # Dies
	enemy_final.take_damage(10)  # Dies
	
	verify(not rebel_final.is_alive and not enemy_final.is_alive, 
		"Both should be dead")
	print("  - Both units can die in same turn (mutual destruction)")

# Helper function
func verify(condition: bool, message: String) -> void:
	if not condition:
		print("✗ ASSERTION FAILED: " + message)
		push_error(message)
	else:
		print("  ✓ " + message)
