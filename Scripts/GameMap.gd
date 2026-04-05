extends Node2D
class_name GameMap

# Node management
var all_nodes: Array[BaseNode] = []
var player_nodes: Array[BaseNode] = []
var enemy_nodes: Array[BaseNode] = []

# Current turn
var current_turn: int = 0

# UI management
var ui_manager: UIManager
var unit_manager: UnitManager
var hovered_node: BaseNode = null

signal turn_changed(new_turn: int)
signal node_selected(node: BaseNode)

func _ready() -> void:
	# 自动查找所有节点
	_collect_all_nodes()
	_setup_connections()
	ui_manager = get_parent().get_node("Systems/UIManager")
	unit_manager = get_parent().get_node("Systems/UnitManager")
	
	# 等待 UnitManager 收集单位后，将单位分配到节点
	await unit_manager.tree_entered
	_assign_units_to_nodes()

func _collect_all_nodes() -> void:
	"""Recursively find all BaseNodes in the scene"""
	for node in get_children():
		if node is BaseNode:
			all_nodes.append(node)
			if node.control_by_player:
				player_nodes.append(node)
			else:
				enemy_nodes.append(node)

func _setup_connections() -> void:
	"""Establish node connections - set manually in inspector or generate with script"""
	pass

func _assign_units_to_nodes() -> void:
	"""Assign units to starting nodes"""
	# Find Tinta node
	var tinta_node = _get_node_by_id("tinta")
	if tinta_node:
		# Assign all units to Tinta
		for unit in unit_manager.all_units:
			unit.assign_to_node(tinta_node)
		print("All units assigned to Tinta")

func _process(_delta: float) -> void:
	"""Handle mouse hover effect"""
	# Only respond to hover when not locked
	if ui_manager.is_panel_locked:
		return
	
	var mouse_pos = get_local_mouse_position()
	var node_at_pos = _get_node_at_position(mouse_pos)
	
	if node_at_pos != hovered_node:
		if node_at_pos != null:
			hovered_node = node_at_pos
			ui_manager.show_node_info(node_at_pos)
		else:
			hovered_node = null
			ui_manager.hide_node_info()
	
	# Update panel position to global mouse coordinates
	if hovered_node != null:
		var global_mouse = get_global_mouse_position()
		ui_manager.update_position_to_mouse(global_mouse)

func _input(event: InputEvent) -> void:
	"""Handle mouse click"""
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Check if click is on UI panel
		var mouse_pos = get_global_mouse_position()
		var info_panel = ui_manager.info_panel
		
		if ui_manager.is_panel_locked:
			# Locked state: check if clicked outside panel
			var panel_rect = Rect2(info_panel.global_position, info_panel.size)
			if not panel_rect.has_point(mouse_pos):
				# Clicked outside panel, unlock
				ui_manager.unlock_node_info()
				get_tree().root.set_input_as_handled()
		else:
			# Unlocked state: check clicked node
			var local_mouse_pos = get_local_mouse_position()
			var clicked_node = _get_node_at_position(local_mouse_pos)
			if clicked_node:
				# Clicked on node
				# Check if units are at this node
				var units_here = clicked_node.stationed_units
				if units_here.size() > 0:
					# Units present, select the first one
					unit_manager.select_unit(units_here[0])
				
				# 锁定信息面板
				ui_manager.lock_node_info(clicked_node)
				node_selected.emit(clicked_node)
				print("已锁定节点: %s" % clicked_node.node_id)
				get_tree().root.set_input_as_handled()

func _get_node_at_position(pos: Vector2) -> BaseNode:
	"""检测鼠标点击的节点"""
	for node in all_nodes:
		if node.global_position.distance_to(global_position + pos) < 30:
			return node
	return null

func _get_node_by_id(node_id: String) -> BaseNode:
	"""通过 ID 获取节点"""
	for node in all_nodes:
		if node.node_id == node_id:
			return node
	return null

func next_turn() -> void:
	"""推进回合"""
	current_turn += 1
	
	# 所有资源点生产资源
	for node in all_nodes:
		if node is ResourceNode:
			node.produce_resource()
	
	turn_changed.emit(current_turn)
	print("回合 %d 结束" % current_turn)

func get_player_controlled_nodes() -> Array[BaseNode]:
	"""获取玩家控制的所有节点"""
	return player_nodes

func occupy_node(node: BaseNode, by_player: bool = true) -> void:
	"""占领节点"""
	node.set_control(by_player)
	
	# 更新列表
	if by_player and node not in player_nodes:
		player_nodes.append(node)
		if node in enemy_nodes:
			enemy_nodes.erase(node)
	elif not by_player and node not in enemy_nodes:
		enemy_nodes.append(node)
		if node in player_nodes:
			player_nodes.erase(node)
