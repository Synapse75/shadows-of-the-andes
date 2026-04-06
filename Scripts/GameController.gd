extends Node
class_name GameController

# 游戏流程控制器
var game_map: GameMap
var turn_manager: TurnManager
var pause_menu: PauseMenuController

signal game_started
signal game_over(winner: String)

func _ready() -> void:
	# 获取各个系统的引用
	game_map = get_node("Map")
	turn_manager = get_node("Systems/TurnManager")
	pause_menu = get_node("UILayer/PauseMenu")
	
	# 连接暂停按钮
	var pause_button = get_node("UILayer/PauseButton")
	pause_button.pressed.connect(pause_menu.pause_game)
	
	# 等待GameMap初始化完成
	await game_map.tree_entered
	
	emit_signal("game_started")
	print("游戏初始化完成 - 摄像机已完全可控")

func on_turn_ended(turn_number: int) -> void:
	"""处理一回合结束后的逻辑"""
	print("第 %d 回合结束" % turn_number)
	# TODO: 处理敌人AI、资源生产等

func check_victory_condition() -> bool:
	"""检查胜利条件"""
	# 检查是否占领了Cusco（目标城市）
	var cusco = game_map._get_node_by_id("cusco")
	if cusco and cusco.control_by_player:
		emit_signal("game_over", "player")
		return true
	return false
