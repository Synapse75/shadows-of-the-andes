extends Node
class_name TurnManager

var current_turn: int = 0
var is_player_turn: bool = true  # 是否是玩家操作阶段
var game_map: GameMap
var combat_system: CombatSystem
var ui_manager: Node
var camera_manager: Node
var turn_label: Label
var next_turn_button: Button

signal turn_started(turn_number: int)
signal turn_ended(turn_number: int)
signal player_phase_started  # 玩家操作开始
signal player_phase_ended    # 玩家操作结束
signal auto_phase_started    # 自动流程开始
signal auto_phase_ended      # 自动流程结束

func _ready() -> void:
	# 获取GameMap引用
	game_map = get_tree().root.get_node("Main/SubViewportContainer/SubViewport/Map")
	combat_system = get_tree().root.get_node_or_null("Main/Systems/CombatSystem") as CombatSystem
	ui_manager = get_tree().root.get_node_or_null("Main/Systems/UIManager")
	camera_manager = get_tree().root.get_node_or_null("Main/SubViewportContainer/SubViewport/Camera2D")
	
	# 获取UI元素
	var main_node = get_tree().root.get_node("Main")
	turn_label = main_node.get_node("UILayer/TurnInfo/TurnLabel")
	next_turn_button = main_node.get_node("UILayer/NextTurnButton")
	
	# 连接按钮信号
	if next_turn_button:
		next_turn_button.pressed.connect(_on_next_turn_pressed)
	else:
		push_error("NextTurnButton not found!")
	
	update_ui()

func _on_next_turn_pressed() -> void:
	"""玩家点击结束回合按钮"""
	if is_player_turn:
		end_player_phase()

func start_turn() -> void:
	"""开始新回合"""
	current_turn += 1
	is_player_turn = true
	
	turn_started.emit(current_turn)
	player_phase_started.emit()
	
	update_ui()

func end_player_phase() -> void:
	"""玩家操作阶段结束，开始自动流程"""
	if not is_player_turn:
		return
	
	is_player_turn = false
	player_phase_ended.emit()
	
	# 禁用结束回合按钮
	next_turn_button.disabled = true
	
	# 禁用地图输入
	if game_map:
		game_map.input_disabled = true
	
	# 运行自动流程
	await execute_auto_phase()
	
	# 恢复地图输入
	if game_map:
		game_map.input_disabled = false
	
	# 启用结束回合按钮并开始下一回合
	next_turn_button.disabled = false
	turn_ended.emit(current_turn)
	is_player_turn = true
	update_ui()
	start_turn()

func execute_auto_phase() -> void:
	"""执行自动流程"""
	auto_phase_started.emit()
	auto_phase_text = "Turn %d - Enemy Invasion" % current_turn
	update_ui()
	
	# 1. 敌人入侵
	var newly_invaded: Array[VillageNode] = []
	if current_turn % 5 == 0:
		newly_invaded = _trigger_enemy_invasion()
		if combat_system:
			combat_system.resolve_all_combats()
		if newly_invaded.size() > 0:
			await _show_enemy_invasion_phase(newly_invaded)
	
	# 2. 单位移动（只展示到达的）
	auto_phase_text = "Turn %d - Unit Movement" % current_turn
	update_ui()
	var arrived_units = _process_unit_movements()
	if arrived_units.size() > 0:
		await _show_unit_arrival_phase(arrived_units)
	
	# 3. 战斗
	auto_phase_text = "Turn %d - Combat" % current_turn
	update_ui()
	if combat_system:
		combat_system.resolve_all_combats()
		await _show_combat_phase()
	
	# 后台执行（不展示）
	_produce_village_resources()
	_process_unit_satiety()
	_consume_village_resources()
	
	auto_phase_ended.emit()

func _show_enemy_invasion_phase(villages: Array[VillageNode]) -> void:
	for village in villages:
		await _show_single_village_event(village, "Enemy Appeared!")

func _show_unit_arrival_phase(arrived_units: Array[Unit]) -> void:
	var villages: Array[VillageNode] = []
	for unit in arrived_units:
		if unit.current_node and unit.current_node not in villages:
			villages.append(unit.current_node)
	
	for village in villages:
		await _show_single_village_event(village, "Unit Arrived!")

func _show_combat_phase() -> void:
	var villages: Array[VillageNode] = []
	for node in game_map.all_nodes:
		if node is VillageNode and node.enemy_units.size() > 0 and node.stationed_units.size() > 0:
			villages.append(node)
	
	for village in villages:
		await _show_single_village_event(village, "Combat!")

func _show_single_village_event(village: VillageNode, event_message: String) -> void:
	# 0. 如果相机不在目标镜头，先移动相机
	if camera_manager and game_map:
		var target_camera = game_map.node_camera_map.get(village.node_id, "tinta")
		var current_camera = "tinta"
		if "current_camera" in camera_manager:
			current_camera = camera_manager.current_camera
		if current_camera != target_camera and camera_manager.has_method("set_camera_view"):
			camera_manager.set_camera_view(target_camera)
			await get_tree().create_timer(0.6).timeout
	
	# 1. outline闪三下 + 显示UI
	_flash_outline(village)
	ui_manager.show_node_info(village)
	
	# 2. 等待后显示事件消息
	await get_tree().create_timer(1.2).timeout
	if event_message != "":
		MessageLog.add_message("%s: %s" % [village.location_name, event_message], "warning")

func _flash_outline(village: VillageNode) -> void:
	if village.has_method("set_hover_state"):
		for i in range(3):
			village.set_hover_state(true)
			await get_tree().create_timer(0.1).timeout
			village.set_hover_state(false)
			await get_tree().create_timer(0.1).timeout

func _process_unit_movements() -> Array[Unit]:
	var processed_units: Array[Unit] = []
	var arrived_units: Array[Unit] = []
	
	for node in game_map.all_nodes:
		if not (node is VillageNode):
			continue
		for unit in node.stationed_units:
			if not (unit is Unit):
				continue
			if unit in processed_units:
				continue
			processed_units.append(unit)
			if unit.unit_state == Unit.UnitState.MOVING:
				if unit.progress_movement():
					arrived_units.append(unit)
	
	for unit in arrived_units:
		unit.handle_arrival_completion()
	
	return arrived_units

func _produce_village_resources() -> void:
	for node in game_map.all_nodes:
		if node is VillageNode:
			node.produce_resources()

func _process_unit_satiety() -> void:
	for unit_node in get_tree().get_nodes_in_group("units"):
		if unit_node is Unit:
			var unit = unit_node as Unit
			if unit.is_alive and unit.current_node and unit.current_node.control_by_player:
				unit.update_bonus_turns()
				unit.consume_satiety()

func _consume_village_resources() -> void:
	for node in game_map.all_nodes:
		if node is VillageNode:
			node.consume_resources()

func _trigger_enemy_invasion() -> Array[VillageNode]:
	"""Enemy invasion: if any camera has uncontrolled villages, spawn enemies at all controlled villages.
	Returns list of newly invaded villages."""
	if not game_map:
		return []
	
	var newly_invaded: Array[VillageNode] = []
	var camera_nodes: Dictionary = {}
	
	for node in game_map.all_nodes:
		if node is VillageNode:
			var camera_name = game_map.node_camera_map.get(node.node_id, "tinta")
			if camera_name not in camera_nodes:
				camera_nodes[camera_name] = []
			camera_nodes[camera_name].append(node)
	
	for camera_name in camera_nodes:
		var nodes = camera_nodes[camera_name]
		var has_uncontrolled = false
		var controlled_villages: Array[VillageNode] = []
		
		for node in nodes:
			if node is VillageNode:
				if not node.control_by_player:
					has_uncontrolled = true
				else:
					controlled_villages.append(node)
		
		if has_uncontrolled:
			for village in controlled_villages:
				var has_defenders = false
				for unit in village.stationed_units:
					if unit is Unit and unit.is_alive and unit.unit_state != Unit.UnitState.MOVING:
						has_defenders = true
						break
				
				var enemy = EnemyUnit.new()
				enemy.set_script(load("res://Scripts/Units/EnemyUnit.gd"))
				get_tree().root.add_child(enemy)
				enemy.add_to_group("enemy_units")
				village.add_enemy_unit(enemy)
				newly_invaded.append(village)
				
				if not has_defenders:
					village.set_control(false)
					MessageLog.add_message("Enemy forces invaded %s!" % village.location_name, "error")
				else:
					MessageLog.add_message("Enemy forces attacked %s!" % village.location_name, "warning")
					for unit in village.stationed_units:
						if unit is Unit and unit.is_alive and unit.unit_state == Unit.UnitState.STATIONED:
							unit.set_unit_state(Unit.UnitState.ATTACKING)
			
			if combat_system:
				for village in controlled_villages:
					var player_units: Array[Unit] = []
					for unit in village.stationed_units:
						if unit is Unit and unit.is_alive and unit.unit_state != Unit.UnitState.MOVING:
							player_units.append(unit)
					var enemy_units: Array[EnemyUnit] = []
					for enemy in village.enemy_units:
						if enemy is EnemyUnit and enemy.is_alive:
							enemy_units.append(enemy)
					if not player_units.is_empty() and not enemy_units.is_empty():
						combat_system.start_combat(village, player_units, enemy_units)
	
	return newly_invaded

func update_ui() -> void:
	"""更新UI显示"""
	if is_node_ready():
		if is_player_turn:
			turn_label.text = "Turn %d - Player's Turn" % current_turn
		else:
			turn_label.text = auto_phase_text

var auto_phase_text: String = "Auto Phase"
