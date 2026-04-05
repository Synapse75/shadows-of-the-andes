extends Node
class_name GameController

# 游戏流程控制器
var game_map: GameMap
var turn_manager: TurnManager
var map_system: MapSystem

signal game_started
signal game_over(winner: String)

func _ready() -> void:
	# 获取各个系统的引用
	game_map = get_node("Map")
	turn_manager = get_node("Systems/TurnManager")
	map_system = get_node("Systems/MapSystem")
	
	# 等待GameMap初始化完成
	await game_map.tree_entered
	
	# 初始化所有村庄的sprite（确保显示是最新的）
	_initialize_village_sprites()
	
	# 初始化地图系统（注册所有地图视野）
	_setup_map_system()
	
	# 设置起始地图
	map_system.set_starting_map("tinta")
	
	emit_signal("game_started")
	print("游戏初始化完成")

func _initialize_village_sprites() -> void:
	"""确保所有VillageNode都有正确的sprite"""
	# 加载sprite资源
	var controlled_sprite = load("res://Sprites/village_controlled.png")
	var uncontrolled_sprite = load("res://Sprites/village_uncontrolled.png")
	
	# 遍历所有节点，初始化sprite
	for node in game_map.all_nodes:
		if node is VillageNode:
			var village = node as VillageNode
			# 如果sprite为空，则分配
			if village.controlled_sprite == null:
				village.controlled_sprite = controlled_sprite
			if village.uncontrolled_sprite == null:
				village.uncontrolled_sprite = uncontrolled_sprite
			# 重新更新视觉（确保显示正确）
			village.update_visual()
	
	print("所有村庄sprite初始化完成")

func _setup_map_system() -> void:
	"""初始化MapSystem - 注册所有地图视野"""
	# 这里可以从game_map的所有节点自动生成地图视野
	# 或者手动注册所有的地图位置
	
	# 获取所有节点并注册为地图视野
	for node in game_map.all_nodes:
		var map_id = node.node_id
		var map_name = node.location_name
		var camera_pos = node.global_position
		
		# 获取这个地点可以到达的其他地点（需要从game_map的连接中获取）
		var connected_maps = _get_connected_maps(node)
		
		map_system.register_map_view(map_id, map_name, camera_pos, connected_maps)
	
	# 设置初始已探索地点（只有Tinta）
	map_system.set_starting_map("tinta")
	print("MapSystem初始化完成，共注册 %d 个地图视野" % game_map.all_nodes.size())

func _get_connected_maps(node: BaseNode) -> Array[String]:
	"""获取该节点连接的其他地点 - 暂时返回空数组，后续可以扩展"""
	# TODO: 从节点的连接关系中获取相邻地点
	return []

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
