extends Node
class_name GameController

# 游戏流程控制器
var game_map: GameMap
var turn_manager: TurnManager
var pause_menu: PauseMenuController
var camera_manager: CameraManager
var settings: SettingsAndData

signal game_started
signal game_over(winner: String)

func _ready() -> void:
	# 获取各个系统的引用
	game_map = get_node("Map")
	turn_manager = get_node("Systems/TurnManager")
	pause_menu = get_node("UILayer/PauseMenu")
	camera_manager = get_node("Camera2D")
	settings = SettingsAndData.new()
	
	# 连接暂停按钮
	var pause_button = get_node("UILayer/PauseButton")
	pause_button.pressed.connect(pause_menu.pause_game)
	
	# 连接回合管理器信号
	turn_manager.turn_started.connect(_on_turn_started)
	turn_manager.turn_ended.connect(_on_turn_ended)
	turn_manager.auto_phase_started.connect(_on_auto_phase_started)
	turn_manager.auto_phase_ended.connect(_on_auto_phase_ended)
	
	# Wait one frame for GameMap to complete its initialization
	await get_tree().process_frame
	
	# 初始化所有村庄
	initialize_villages()
	
	# 启动回合系统
	turn_manager.start_turn()
	
	emit_signal("game_started")

func initialize_villages() -> void:
	"""Initialize all villages with resources and enemy garrisons"""
	var all_populations = settings.get_all_populations()
	
	for village_id in all_populations:
		var village = game_map._get_node_by_id(village_id)
		if not village:
			continue
		
		# Initialize village population
		var population = settings.get_village_population(village_id)
		village.resources["population"] = population
		
		# Initialize resource production
		var resource_types = settings.get_initial_resources(village_id)
		var production_rate = settings.get_production_rate(village_id)
		village.initialize_resource_production(resource_types, production_rate)
		
		# Initialize resource amounts (start at 0, will be produced during game)
		for resource_type in resource_types:
			village.resources[resource_type] = 0
		
		# Spawn enemy units
		spawn_enemy_garrison(village, village_id)

func spawn_enemy_garrison(village: BaseNode, village_id: String) -> void:
	"""Spawn enemy units to garrison a village"""
	# Tinta is player's starting village, no enemy garrison
	if village_id == "tinta":
		return
	
	var enemy_count = settings.get_enemy_garrison_count(village_id)
	
	for i in range(enemy_count):
		var enemy = EnemyUnit.new()
		enemy.unit_id = "enemy_%s_%d" % [village_id, i]
		enemy.unit_name = "Spanish Guard %d" % (i + 1)
		enemy.assign_to_node(village)

func _on_turn_started(turn_number: int) -> void:
	"""回合开始时的处理"""
	pass

func _on_turn_ended(turn_number: int) -> void:
	"""回合结束时的处理"""
	pass

func _on_auto_phase_started() -> void:
	"""自动流程开始时的处理"""
	pass

func _on_auto_phase_ended() -> void:
	"""自动流程结束时的处理"""
	# 检查胜利条件
	check_victory_condition()

func check_victory_condition() -> bool:
	"""检查胜利条件"""
	# 检查是否占领了Cusco（目标城市）
	var cusco = game_map._get_node_by_id("cusco")
	if cusco and cusco.control_by_player:
		emit_signal("game_over", "player")
		return true
	return false

# 镜头切换方法 - 供UI按钮调用
func camera_next() -> void:
	"""切换到下一个镜头"""
	camera_manager.cycle_camera_next()

func camera_prev() -> void:
	"""切换到上一个镜头"""
	camera_manager.cycle_camera_prev()

func camera_to_north() -> void:
	"""切换到 Tinta 镜头"""
	camera_manager.set_camera_view("tinta")

func camera_to_south() -> void:
	"""切换到 Jungle 镜头"""
	camera_manager.set_camera_view("jungle")

func camera_to_east() -> void:
	"""切换到 Marcapata 镜头"""
	camera_manager.set_camera_view("marcapata")

func camera_to_west() -> void:
	"""切换到 Andahuaylillas 镜头"""
	camera_manager.set_camera_view("andahuaylillas")
