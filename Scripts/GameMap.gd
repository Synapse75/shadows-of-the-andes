extends Node2D
class_name GameMap

# Node management
var all_nodes: Array[VillageNode] = []
var player_nodes: Array[VillageNode] = []
var enemy_nodes: Array[VillageNode] = []

# Current turn
var current_turn: int = 0

# UI management
var ui_manager: UIManager
var unit_manager: UnitManager
var hovered_node: VillageNode = null

signal node_selected(node: VillageNode)

func _ready() -> void:
	# 自动查找所有节点
	_collect_all_nodes()
	_setup_connections()
	ui_manager = get_tree().root.get_node("Main/Systems/UIManager")
	unit_manager = get_tree().root.get_node("Main/Systems/UnitManager")
	
	# 等待 UnitManager 收集单位后，将单位分配到节点
	await unit_manager.tree_entered
	_assign_units_to_nodes()

func _collect_all_nodes() -> void:
	"""Recursively find all VillageNodes in the scene"""
	for node in get_children():
		if node is VillageNode:
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
	"""Handle mouse hover effect and click detection"""
	# Only respond to hover when not locked
	if ui_manager.is_panel_locked:
		return
	
	# Get global mouse position
	var global_mouse_pos = get_global_mouse_position()
	var node_at_pos = _get_node_at_position(global_mouse_pos)
	
	# Hover effect
	if node_at_pos != hovered_node:
		if hovered_node != null and hovered_node.has_method("set_hover_state"):
			hovered_node.set_hover_state(false)
			# 悬浮到不同节点时隐藏资源滚动框
			if ui_manager.resources_scroll_container:
				ui_manager.resources_scroll_container.visible = false
			
		if node_at_pos != null:
			hovered_node = node_at_pos
			if hovered_node.has_method("set_hover_state"):
				hovered_node.set_hover_state(true)
			print("[GameMap._process] Hovering over: %s" % node_at_pos.node_id)
			ui_manager.show_node_info(node_at_pos)
		else:
			hovered_node = null
			print("[GameMap._process] Not hovering over any node")
			ui_manager.hide_node_info()
	
	# Click detection in _process (since _input might be consumed by UI)
	if Input.is_action_just_pressed("ui_accept") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		# Check UI button areas first
		var screen_mouse_pos = get_viewport().get_mouse_position()
		
		# Skip if clicking on UI elements
		var next_turn_rect = Rect2(Vector2(3, 90), Vector2(48, 10))
		var pause_btn_rect = Rect2(Vector2(460, 3), Vector2(18, 10))
		var arrow_up_rect = Rect2(Vector2(236, 3), Vector2(10, 10))
		var arrow_down_rect = Rect2(Vector2(236, 290), Vector2(10, 10))
		var arrow_left_rect = Rect2(Vector2(0, 145), Vector2(10, 10))
		var arrow_right_rect = Rect2(Vector2(470, 145), Vector2(10, 10))
		
		if not (next_turn_rect.has_point(screen_mouse_pos) or 
				pause_btn_rect.has_point(screen_mouse_pos) or
				arrow_up_rect.has_point(screen_mouse_pos) or
				arrow_down_rect.has_point(screen_mouse_pos) or
				arrow_left_rect.has_point(screen_mouse_pos) or
				arrow_right_rect.has_point(screen_mouse_pos)):
			
			# Not on UI buttons, check for node click
			var clicked_node = _get_node_at_position(global_mouse_pos)
			if clicked_node:
				var units_here = clicked_node.stationed_units
				if units_here.size() > 0:
					unit_manager.select_unit(units_here[0])
				
				node_selected.emit(clicked_node)

func _input(event: InputEvent) -> void:
	"""Handle mouse click - only consume if clicking on game nodes"""
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Get screen coordinates for UI button checks
		var screen_mouse_pos = event.position
		
		# Check if click is on UI buttons - don't consume those events
		# NextTurnButton: 3, 90 - 48, 10
		var next_turn_rect = Rect2(Vector2(3, 90), Vector2(48, 10))
		if next_turn_rect.has_point(screen_mouse_pos):
			return  # Let button handle it
		
		# PauseButton: 460, 3 - 18, 10
		var pause_btn_rect = Rect2(Vector2(460, 3), Vector2(18, 10))
		if pause_btn_rect.has_point(screen_mouse_pos):
			return  # Let button handle it
		
		# Arrow buttons - allow clicks on arrow UI
		# ArrowUp: 236, 3 - 10x10
		var arrow_up_rect = Rect2(Vector2(236, 3), Vector2(10, 10))
		if arrow_up_rect.has_point(screen_mouse_pos):
			return  # Let button handle it
		
		# ArrowDown: 236, 290 - 10x10
		var arrow_down_rect = Rect2(Vector2(236, 290), Vector2(10, 10))
		if arrow_down_rect.has_point(screen_mouse_pos):
			return  # Let button handle it
		
		# ArrowLeft: 0, 145 - 10x10
		var arrow_left_rect = Rect2(Vector2(0, 145), Vector2(10, 10))
		if arrow_left_rect.has_point(screen_mouse_pos):
			return  # Let button handle it
		
		# ArrowRight: 470, 145 - 10x10
		var arrow_right_rect = Rect2(Vector2(470, 145), Vector2(10, 10))
		if arrow_right_rect.has_point(screen_mouse_pos):
			return  # Let button handle it
		
		# Check for node click
		var global_mouse_pos = get_global_mouse_position()
		var clicked_node = _get_node_at_position(global_mouse_pos)
		if clicked_node:
			# Clicked on node - select units if present
			var units_here = clicked_node.stationed_units
			if units_here.size() > 0:
				unit_manager.select_unit(units_here[0])
			
			node_selected.emit(clicked_node)
			get_tree().root.set_input_as_handled()

func _get_node_at_position(global_pos: Vector2) -> VillageNode:
	"""检测全局位置处的节点 - 通过与AnimatedSprite2D碰撞检测"""
	for node in all_nodes:
		if node is VillageNode and node.village_sprite:
			var sprite = node.village_sprite
			# 稍微扩大碰撞判定范围，使其更容易点击 (16x16)
			var sprite_half_size = Vector2(8, 8)
			var sprite_rect = Rect2(sprite.global_position - sprite_half_size, sprite_half_size * 2)
			
			if sprite_rect.has_point(global_pos):
				return node
	return null

func _get_node_by_id(node_id: String) -> VillageNode:
	"""通过 ID 获取节点"""
	for node in all_nodes:
		if node.node_id == node_id:
			return node
	return null

func get_player_controlled_nodes() -> Array[VillageNode]:
	"""获取玩家控制的所有节点"""
	return player_nodes

func occupy_node(node: VillageNode, by_player: bool = true) -> void:
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
