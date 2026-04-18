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

# Camera view adjacency - which cameras connect to which
var camera_adjacency: Dictionary = {
	"tinta": ["andahuaylillas"],
	"andahuaylillas": ["tinta", "marcapata", "jungle"],
	"marcapata": ["andahuaylillas"],
	"jungle": ["andahuaylillas"]
}

# Which camera each node belongs to (GDD 3.3 camera assignments)
var node_camera_map: Dictionary = {
	"tinta": "tinta",
	"tungasuca": "tinta",
	"pampamarca": "tinta",
	"sicuani": "tinta",
	"urcos": "andahuaylillas",
	"quiquijana": "andahuaylillas",
	"paucartambo": "jungle",
	"andahuaylillas": "andahuaylillas",
	"cusco": "andahuaylillas",
	"ocongate": "andahuaylillas",
	"marcapata": "marcapata",
	"pilcopata": "jungle",
	"challabamba": "jungle"
}

# Hardcoded node screen positions for each camera view (precomputed, no runtime calculation)
# Formula: screen_pos = viewport_center(390, 225) + 3/4 * (world_pos - camera_center)
var node_screen_positions_by_camera: Dictionary = {
	"tinta": {
		"tinta": Vector2(390, 225),
		"tungasuca": Vector2(353, 238),
		"pampamarca": Vector2(360, 227),
		"sicuani": Vector2(479, 293),
	},
	"andahuaylillas": {
		"urcos": Vector2(419, 229),
		"quiquijana": Vector2(460, 305),
		"andahuaylillas": Vector2(390, 225),
		"cusco": Vector2(245, 149),
		"ocongate": Vector2(538, 199),
	},
	"marcapata": {
		"marcapata": Vector2(390, 225),
	},
	"jungle": {
		"paucartambo": Vector2(340, 332),
		"pilcopata": Vector2(440, 133),
		"challabamba": Vector2(312, 285),
	},
}

# Cache for current camera view positions
var current_camera_positions: Dictionary = {}
var camera_manager: CameraManager = null

signal node_selected(node: VillageNode)

func _ready() -> void:
	# 自动查找所有节点
	_collect_all_nodes()
	_setup_connections()
	ui_manager = get_tree().root.get_node("Main/Systems/UIManager")
	unit_manager = get_tree().root.get_node("Main/Systems/UnitManager")
	camera_manager = get_node("../Camera2D") as CameraManager
	
	print("DEBUG: GameMap._ready() - collected %d nodes" % all_nodes.size())
	print("DEBUG: Camera manager: %s" % ("found" if camera_manager else "NOT FOUND"))
	
	# 等待 UnitManager 收集单位后，将单位分配到节点
	await unit_manager.tree_entered
	_assign_units_to_nodes()
	
	# Initialize coordinate mapping
	print("DEBUG: Initializing camera positions for 'tinta'...")
	print("DEBUG: node_screen_positions_by_camera keys: %s" % node_screen_positions_by_camera.keys())
	_update_camera_positions("tinta")
	
	# Subscribe to camera changes
	if camera_manager:
		camera_manager.camera_view_changed.connect(_on_camera_view_changed)
	
	# Debug: print all camera views and their nodes
	_debug_print_all_cameras()
	
	print("\nDEBUG: _ready() complete. current_camera_positions size: %d" % current_camera_positions.size())
	print("DEBUG: node_screen_positions_by_camera['tinta'] size: %d" % node_screen_positions_by_camera.get("tinta", {}).size())

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
	"""No longer needed - drop targets are determined by camera view, not neighbors"""
	pass

func _assign_units_to_nodes() -> void:
	"""Assign units to starting nodes"""
	# Find Tinta node
	var tinta_node = _get_node_by_id("tinta")
	if tinta_node:
		# Assign all units to Tinta
		for unit in unit_manager.all_units:
			unit.assign_to_node(tinta_node)

func _process(_delta: float) -> void:
	"""Handle mouse hover effect and click detection"""
	# Only respond to hover when not locked and not dragging
	if ui_manager.is_panel_locked or ui_manager.is_dragging:
		return
	
	# Get global mouse position
	var global_mouse_pos = get_global_mouse_position()
	var node_at_pos = _get_node_at_position(global_mouse_pos)
	
	# Hover effect - only update shader, not information display
	if node_at_pos != hovered_node:
		if hovered_node != null and hovered_node.has_method("set_hover_state"):
			hovered_node.set_hover_state(false)
			
		if node_at_pos != null:
			hovered_node = node_at_pos
			if hovered_node.has_method("set_hover_state"):
				hovered_node.set_hover_state(true)
		else:
			hovered_node = null
	
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
				# Display node information on click
				ui_manager.show_node_info(clicked_node)
				
				var units_here = clicked_node.stationed_units
				if units_here.size() > 0:
					unit_manager.select_unit(units_here[0])
				
				node_selected.emit(clicked_node)

func _input(event: InputEvent) -> void:
	"""Handle mouse click - only consume if clicking on game nodes"""
	# Don't process clicks while dragging units
	if ui_manager and ui_manager.is_dragging:
		return
	
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

func _update_camera_positions(camera_name: String) -> void:
	"""Update current camera view positions from precomputed table (no calculation)"""
	current_camera_positions = node_screen_positions_by_camera.get(camera_name, {})
	print("Updated camera positions for view '%s': %d visible nodes" % [camera_name, current_camera_positions.size()])
	
	# Debug: print all visible nodes with their screen positions
	print("\n=== DEBUG: Visible nodes in %s camera ===" % camera_name)
	for node_id in current_camera_positions:
		var node = _get_node_by_id(node_id)
		var screen_pos = current_camera_positions[node_id]
		if node:
			print("  %s: screen(%.0f, %.0f), world(%.0f, %.0f)" % [
				node_id, screen_pos.x, screen_pos.y, 
				node.global_position.x, node.global_position.y
			])
	print("===\n")

func _on_camera_view_changed(camera_name: String) -> void:
	"""Called when camera transitions to a new view - update coordinate table"""
	_update_camera_positions(camera_name)

func get_node_at_screen_position(screen_pos: Vector2, detection_radius: float = 40.0) -> VillageNode:
	"""Get the closest node to a screen position using precomputed coordinates (O(n) lookup only)"""
	var closest_node: VillageNode = null
	var closest_distance = detection_radius
	
	print("\n=== DEBUG: get_node_at_screen_position ===")
	print("Looking for node at screen position (%.1f, %.1f) with radius %.0f" % [screen_pos.x, screen_pos.y, detection_radius])
	print("Current camera positions available: %d nodes" % current_camera_positions.size())
	
	# Search only visible nodes for current camera view
	for node_id in current_camera_positions:
		var node = _get_node_by_id(node_id)
		if node:
			var node_screen_pos = current_camera_positions[node_id]
			var distance = node_screen_pos.distance_to(screen_pos)
			print("  %s: screen(%.0f, %.0f), distance: %.1f %s" % [
				node_id, node_screen_pos.x, node_screen_pos.y, distance,
				" ✓ WITHIN RANGE" if distance < closest_distance else ""
			])
			if distance < closest_distance:
				closest_node = node
				closest_distance = distance
	
	if closest_node:
		print("RESULT: Found %s at distance %.1f" % [closest_node.location_name, closest_distance])
	else:
		print("RESULT: No node found within radius")
	print("===\n")
	
	return closest_node

func _debug_print_all_cameras() -> void:
	"""Debug: Print all cameras and their nodes with screen positions"""
	var separator = "=================================================================================="
	print("\n" + separator)
	print("DEBUG: Complete Coordinate Mapping for All Cameras")
	print(separator)
	
	for camera_name in node_screen_positions_by_camera:
		var positions = node_screen_positions_by_camera[camera_name]
		print("\n[%s Camera] (%d nodes)" % [camera_name.to_upper(), positions.size()])
		
		for node_id in positions:
			var node = _get_node_by_id(node_id)
			var screen_pos = positions[node_id]
			if node:
				print("  • %s: screen(%.0f, %.0f) | world(%.0f, %.0f)" % [
					node_id,
					screen_pos.x, screen_pos.y,
					node.global_position.x, node.global_position.y
				])
	
	print("\n" + separator + "\n")

func get_all_draggable_nodes() -> Array[VillageNode]:
	"""Get all nodes that a unit can be dragged to (same camera + adjacent cameras)"""
	return all_nodes

func get_movement_time_to_node(from_node: VillageNode, to_node: VillageNode) -> int:
	"""Calculate movement time from one node to another based on camera distance (GDD 4.3 revised)
	- Same camera: 2 turns
	- Each camera crossing: +4 turns
	"""
	var from_camera = node_camera_map.get(from_node.node_id, "tinta")
	var to_camera = node_camera_map.get(to_node.node_id, "tinta")
	
	if from_camera == to_camera:
		# Same camera view
		return 2
	else:
		# Different camera - calculate shortest path
		return 2 + (_calculate_camera_distance(from_camera, to_camera) * 4)

func _calculate_camera_distance(from_camera: String, to_camera: String) -> int:
	"""Calculate shortest path distance between two cameras"""
	if from_camera == to_camera:
		return 0
	
	# Simple BFS for shortest path
	var visited = {}
	var queue = [[from_camera, 0]]  # [camera_name, distance]
	
	while queue.size() > 0:
		var current = queue.pop_front()
		var camera = current[0]
		var distance = current[1]
		
		if visited.has(camera):
			continue
		visited[camera] = true
		
		if camera == to_camera:
			return distance
		
		for adjacent in camera_adjacency.get(camera, []):
			if not visited.has(adjacent):
				queue.append([adjacent, distance + 1])
	
	# No path found (shouldn't happen with proper camera setup)
	return 999

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
