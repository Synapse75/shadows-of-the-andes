extends Node
class_name TurnManager

var current_turn: int = 0
var is_player_turn: bool = true  # 是否是玩家操作阶段
var game_map: GameMap
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
	game_map = get_tree().root.get_node("Main/Map")
	
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
	
	# 所有村庄生产资源
	for node in game_map.all_nodes:
		if node is VillageNode:
			node.produce_resources()
	
	auto_phase_ended.emit()

func update_ui() -> void:
	"""更新UI显示"""
	if is_node_ready():
		var phase_text = "Player Turn" if is_player_turn else "Auto Phase"
		turn_label.text = "Turn %d - %s" % [current_turn, phase_text]
