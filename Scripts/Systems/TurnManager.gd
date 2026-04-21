extends Node
class_name TurnManager

var current_turn: int = 0
var is_player_turn: bool = true  # 是否是玩家操作阶段
var game_map: GameMap
var combat_system: CombatSystem
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
	print("[TurnManager] _ready: combat_system found = %s" % str(combat_system != null))
	
	# 获取UI元素
	var main_node = get_tree().root.get_node("Main")
	turn_label = main_node.get_node("UILayer/TurnInfo/TurnLabel")
	next_turn_button = main_node.get_node("UILayer/NextTurnButton")
	
	# 连接按钮信号
	if next_turn_button:
		next_turn_button.pressed.connect(_on_next_turn_pressed)
		next_turn_button.text = "End Turn"
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
	
	# 运行自动流程
	await execute_auto_phase()
	
	# 启用结束回合按钮并开始下一回合
	next_turn_button.disabled = false
	turn_ended.emit(current_turn)
	start_turn()

func execute_auto_phase() -> void:
	"""执行自动流程（资源生产等）"""
	auto_phase_started.emit()
	print("[TurnManager] Auto phase start - Turn %d" % current_turn)
	
	# Progress all moving units (GDD 5.2.1)
	# Use node stationed_units as source of truth so units spawned outside scene tree
	# are still progressed correctly.
	var processed_units: Array[Unit] = []
	var moving_units_progressed := 0
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
				moving_units_progressed += 1
				unit.progress_movement()
	print("[TurnManager] Moving units progressed this turn: %d" % moving_units_progressed)

	# Resolve one combat round for all active combats in this turn.
	if combat_system:
		print("[TurnManager] Active combats before resolve: %d" % combat_system.active_combats.size())
		combat_system.resolve_all_combats()
		print("[TurnManager] Active combats after resolve: %d" % combat_system.active_combats.size())
	else:
		print("[TurnManager] WARNING: CombatSystem not found, combat resolution skipped")
	
	# 所有村庄消耗资源，然后生产资源
	for node in game_map.all_nodes:
		if node is VillageNode:
			# GDD 4.4 - 村庄资源消耗系统
			node.consume_resources()
			# GDD 3.5 - 资源生成系统
			node.produce_resources()
	
	auto_phase_ended.emit()
	print("[TurnManager] Auto phase end - Turn %d" % current_turn)

func update_ui() -> void:
	"""更新UI显示"""
	if is_node_ready():
		var phase_text = "Player Turn" if is_player_turn else "Auto Phase"
		turn_label.text = "Turn %d - %s" % [current_turn, phase_text]
