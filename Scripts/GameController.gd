extends Node
class_name GameController

# 游戏流程控制器
var game_map: GameMap
var turn_manager: TurnManager
var pause_menu: PauseMenuController
var camera_manager: CameraManager
var settings: SettingsAndData
var ui_manager: UIManager
var spotlight_mask_overlay: SpotlightMaskOverlay

signal game_started
signal game_over(winner: String)

func _ready() -> void:
	# 获取各个系统的引用
	game_map = get_node("SubViewportContainer/SubViewport/Map")
	turn_manager = get_node("Systems/TurnManager")
	pause_menu = get_node("UILayer/PauseMenu")
	camera_manager = get_node("SubViewportContainer/SubViewport/Camera2D")
	ui_manager = get_node("Systems/UIManager")
	spotlight_mask_overlay = get_node_or_null("SpotlightMaskOverlay") as SpotlightMaskOverlay
	settings = SettingsAndData.new()
	UnitNamePool.reset_pool()
	
	# 连接暂停按钮
	var pause_button = get_node("UILayer/PauseButton")
	pause_button.pressed.connect(pause_menu.pause_game)
	
	# 连接回合管理器信号
	turn_manager.auto_phase_ended.connect(_on_auto_phase_ended)
	
	# 连接游戏结束信号
	game_over.connect(_on_game_over)
	
	# Wait one frame for GameMap to complete its initialization
	await get_tree().process_frame
	
	# 初始化所有村庄
	initialize_villages()
	
	# Display Tinta info on startup
	var tinta = game_map._get_node_by_id("tinta")
	if tinta:
		ui_manager.show_node_info(tinta)
		print("[DEBUG] Tinta units at start: ", tinta.stationed_units.size())
		for u in tinta.stationed_units:
			print("[DEBUG]   - ", u.unit_name)
		call_deferred("_show_startup_spotlight", tinta)

	# Allow capture messages only after initialization has finished
	_enable_control_notifications()
	
	# 启动回合系统
	turn_manager.start_turn()
	
	# 播放背景音乐
	get_tree().root.get_node("AudioManager").play_music("knees_beats")
	
	emit_signal("game_started")

func _show_startup_spotlight(node: VillageNode) -> void:
	"""Show the startup spotlight on Tinta using screen-space coordinates."""
	if not spotlight_mask_overlay or not node:
		return

	var spotlight_position := Vector2(390, 225)
	if game_map:
		var tinta_positions: Dictionary = game_map.node_screen_positions_by_camera.get("tinta", {})
		var mapped_position = tinta_positions.get(node.node_id, null)
		if mapped_position is Vector2:
			spotlight_position = mapped_position
		elif game_map.current_camera_positions.has(node.node_id):
			spotlight_position = game_map.get_node_screen_position(node)

	spotlight_mask_overlay.has_clicked_once = false
	spotlight_mask_overlay.show_mask()
	spotlight_mask_overlay.set_highlight_position(spotlight_position, false)
	spotlight_mask_overlay.on_click_callback = _on_first_spotlight_clicked

var _tutorial_step: int = 0

func _on_first_spotlight_clicked() -> void:
	print("DEBUG: _on_first_spotlight_clicked called, step=", _tutorial_step)
	if not spotlight_mask_overlay:
		return
	
	spotlight_mask_overlay.on_click_callback = _on_tutorial_click
	spotlight_mask_overlay.has_clicked_once = false
	
	_tutorial_step = 1
	await get_tree().create_timer(0.2).timeout
	
	print("DEBUG: Moving to step 1: info_panel")
	spotlight_mask_overlay.move_to(Vector2(70, 100), 0.5)
	spotlight_mask_overlay.set_label_text("He hoped to work together with the people to rebuild the vertical archipelago.")

func _on_tutorial_click() -> void:
	print("DEBUG: _on_tutorial_click called, step=", _tutorial_step)
	if not spotlight_mask_overlay:
		return
	
	match _tutorial_step:
		1:
			spotlight_mask_overlay.move_to(Vector2(70, 165), 0.5)
			spotlight_mask_overlay.set_label_text("He called on villagers.")
			_tutorial_step = 2
		2:
			spotlight_mask_overlay.move_to(Vector2(70, 211), 0.5)
			spotlight_mask_overlay.set_label_text("Formed the rebel army.")
			_tutorial_step = 3
		3:
			spotlight_mask_overlay.move_to(Vector2(70, 251), 0.5)
			spotlight_mask_overlay.set_label_text("Among them were defensive specialists known as the female corps.")
			_tutorial_step = 4
		4:
			spotlight_mask_overlay.set_label_text("(Drag the units to move them around)")
			_tutorial_step = 5
		5:
			spotlight_mask_overlay.move_to(Vector2(70, 301), 0.5)
			spotlight_mask_overlay.set_label_text("The villages produced resources.")
			_tutorial_step = 6
		6:
			spotlight_mask_overlay.set_label_text("Tupac Amaru II's forces transported resources between settlements.")
			_tutorial_step = 7
		7:
			spotlight_mask_overlay.set_label_text("(Drag the resources to load them onto units)")
			_tutorial_step = 8
		8:
			spotlight_mask_overlay.move_to(Vector2(400, 55), 0.5)
			spotlight_mask_overlay.set_label_text("(Click on the arrow to switch camera views)", true)
			_tutorial_step = 9
		
		9:
			spotlight_mask_overlay.move_to(Vector2(216, 25), 0.5)
			spotlight_mask_overlay.set_label_text("(Click on the Next Turn button to end your turn)", true)
			_tutorial_step = 10

		10:
			spotlight_mask_overlay.hide_mask(true, 0.5)
			spotlight_mask_overlay.on_click_callback = Callable()
			_tutorial_step = 0
			

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
		village.population = population  # Set new population attribute
		
		# Initialize resource production
		var resource_types = settings.get_initial_resources(village_id)
		var production_rate = settings.get_production_rate(village_id)
		village.initialize_resource_production(resource_types, production_rate)
		village.produced_resource_types = resource_types  # Set produced resource types
		
		# Initialize resource amounts (start with some initial resources for testing)
		for resource_type in resource_types:
			village.resources[resource_type] = 3
		
		# Trigger signal to update display
		village.resources_changed.emit(village.resources)
		
		# Spawn enemy units
		spawn_enemy_garrison(village, village_id)
		
		# Spawn initial player units at Tinta
		if village_id == "tinta":
			spawn_initial_garrison(village)

func _enable_control_notifications() -> void:
	"""Enable control-change messages after startup initialization is complete."""
	for node in game_map.all_nodes:
		if node is VillageNode:
			(node as VillageNode).enable_control_notifications()

func spawn_initial_garrison(village: VillageNode) -> void:
	"""Spawn initial player units at Tinta"""
	# Create 2 initial units: 1 Rebel Army, 1 Female Corps
	var unit1 = RebelArmy.new()
	village.add_child(unit1)
	unit1.assign_to_node(village)
	
	var unit2 = FemaleCorps.new()
	village.add_child(unit2)
	unit2.assign_to_node(village)

func spawn_enemy_garrison(village: VillageNode, village_id: String) -> void:
	"""Spawn enemy units to garrison a village"""
	# Tinta is player's starting village, no enemy garrison
	if village_id == "tinta":
		return
	
	var enemy_count = settings.get_enemy_garrison_count(village_id)
	
	for i in range(enemy_count):
		var enemy = EnemyUnit.new()
		enemy.unit_id = "enemy_%s_%d" % [village_id, i]
		village.add_child(enemy)
		enemy.assign_to_node(village)
func _on_auto_phase_ended() -> void:
	"""自动流程结束时的处理"""
	# 刷新 UI 显示（资源/人口变化后需要更新显示）
	if ui_manager:
		ui_manager.refresh_displayed_node_info()
	
	# 检查失败条件（玩家单位全灭）
	if check_defeat_condition():
		return
	
	# 检查胜利条件（占领所有村庄）
	check_victory_condition()

func check_victory_condition() -> bool:
	"""检查胜利条件 - 占领所有节点"""
	# 检查是否占领了所有村庄
	for node in game_map.all_nodes:
		if not node.control_by_player:
			return false  # 还有未占领的村庄
	
	# 所有村庄都被占领 - 玩家胜利
	emit_signal("game_over", "player")
	return true

func check_defeat_condition() -> bool:
	"""检查失败条件 - 所有玩家单位都死亡"""
	# 遍历所有村庄，统计玩家单位数量
	var player_unit_count = 0
	for node in game_map.all_nodes:
		if node is VillageNode:
			for unit in (node as VillageNode).stationed_units:
				# 统计不在 "enemy_units" 组中的单位（玩家单位）
				if not unit.is_in_group("enemy_units"):
					player_unit_count += 1
	
	# 如果没有玩家单位了 - 玩家失败
	if player_unit_count == 0:
		emit_signal("game_over", "enemy")
		return true
	
	return false

func _on_game_over(winner: String) -> void:
	"""处理游戏结束事件"""
	if winner == "player":
		await TransitionManager.transition_to_victory()
	else:
		await TransitionManager.transition_to_defeat()

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
