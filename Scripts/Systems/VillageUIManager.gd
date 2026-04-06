extends Node
class_name VillageUIManager

# UI管理
var game_map: GameMap
var camera: Camera2D
var village_ui_nodes: Dictionary = {}  # village_id -> Sprite2D UI node
var village_labels: Dictionary = {}  # village_id -> Label (显示村庄名称)

# Sprite资源
var controlled_sprite: Texture2D
var uncontrolled_sprite: Texture2D

signal village_ui_clicked(village_id: String)

func _ready() -> void:
	game_map = get_tree().root.get_node("Main/Map")
	camera = get_tree().root.get_node("Main/Camera2D")
	
	# 加载sprite资源
	controlled_sprite = load("res://Sprites/village_controlled.png")
	uncontrolled_sprite = load("res://Sprites/village_uncontrolled.png")
	
	# 为每个村庄创建UI
	_create_village_uis()
	
	set_process(true)

func _process(_delta: float) -> void:
	"""每帧更新所有村庄UI精灵和标签的位置以跟随摄像机"""
	if not camera or not game_map:
		return
	
	# 为每个村庄更新其UI精灵和标签的屏幕位置
	for node in game_map.all_nodes:
		if node is VillageNode and node.node_id in village_ui_nodes:
			var sprite = village_ui_nodes[node.node_id]
			var label = village_labels[node.node_id]
			
			# 将世界坐标转换为屏幕坐标
			var world_pos = node.global_position
			var screen_pos = _world_to_screen(world_pos)
			
			# 更新精灵位置
			sprite.position = screen_pos
			
			# 更新标签位置（在精灵上方）
			label.position = screen_pos + Vector2(0, -50)

func _world_to_screen(world_pos: Vector2) -> Vector2:
	"""将世界坐标转换为屏幕坐标"""
	if not camera:
		return world_pos
	
	# 获取摄像机位置和缩放
	var camera_pos = camera.global_position
	var zoom = camera.zoom
	
	# 计算相对于摄像机中心的位置
	var relative_pos = world_pos - camera_pos
	
	# 获取视口大小
	var viewport_size = get_viewport().get_visible_rect().size
	var viewport_center = viewport_size / 2
	
	# 应用缩放并转换为屏幕坐标
	var screen_pos = viewport_center + relative_pos * zoom
	
	return screen_pos

func _create_village_uis() -> void:
	"""为所有村庄创建UI节点"""
	for village in game_map.all_nodes:
		if village is VillageNode:
			_create_ui_for_village(village)
	
	print("村庄UI创建完成，共 %d 个村庄" % village_ui_nodes.size())

func _create_ui_for_village(village: VillageNode) -> void:
	"""为单个村庄创建UI（包括精灵和名称标签）"""
	var sprite = Sprite2D.new()
	sprite.global_position = village.global_position
	sprite.name = village.node_id + "_UI"
	sprite.scale = Vector2(2, 2)
	
	# 设置初始sprite
	if village.control_by_player:
		sprite.texture = controlled_sprite
	else:
		sprite.texture = uncontrolled_sprite
	
	# 添加到UILayer
	add_child(sprite)
	
	# 存储引用
	village_ui_nodes[village.node_id] = sprite
	
	# 创建村庄名称标签
	var label = Label.new()
	label.text = village.location_name
	label.add_theme_font_size_override("font_size", 14)
	label.anchor_left = 0.5
	label.anchor_top = 0.5
	label.offset_left = -50
	label.offset_right = 50
	label.offset_top = -10
	label.offset_bottom = 10
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# 添加到UILayer
	add_child(label)
	
	# 存储引用
	village_labels[village.node_id] = label
	
	# 监听村庄的控制变化信号，更新UI
	village.control_changed.connect(_on_village_control_changed.bindv([village.node_id]))

func _on_village_control_changed(village_id: String, is_player: bool) -> void:
	"""当村庄的控制权改变时更新UI"""
	if village_id in village_ui_nodes:
		var sprite = village_ui_nodes[village_id]
		if is_player:
			sprite.texture = controlled_sprite
		else:
			sprite.texture = uncontrolled_sprite
		print("村庄UI已更新: %s -> %s" % [village_id, "controlled" if is_player else "uncontrolled"])

func _input(event: InputEvent) -> void:
	"""处理点击村庄UI"""
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# 获取屏幕坐标鼠标位置
		var screen_mouse_pos = event.position
		
		# 检查是否点击了UI按钮 - 如果是则不消费事件
		# NextTurnButton: 10, 360 - 200, 400
		var next_turn_rect = Rect2(Vector2(10, 360), Vector2(190, 40))
		if next_turn_rect.has_point(screen_mouse_pos):
			return  # Let button handle it
		
		# PauseButton: 1840, 10 - 1910, 50
		var pause_btn_rect = Rect2(Vector2(1840, 10), Vector2(70, 40))
		if pause_btn_rect.has_point(screen_mouse_pos):
			return  # Let button handle it
		
		# 检查是否点击了某个村庄UI
		# 注：精灵位置现在是屏幕坐标（由_process设置）
		for village_id in village_ui_nodes:
			var sprite = village_ui_nodes[village_id]
			var sprite_size = sprite.get_rect().size * sprite.scale
			var sprite_rect = Rect2(sprite.position - sprite_size / 2, sprite_size)
			
			if sprite_rect.has_point(screen_mouse_pos):
				village_ui_clicked.emit(village_id)
				print("点击了村庄: %s" % village_id)
				get_tree().root.set_input_as_handled()
				break

func update_village_position(village_id: String, new_pos: Vector2) -> void:
	"""更新村庄UI的位置（当村庄移动时调用）"""
	if village_id in village_ui_nodes:
		village_ui_nodes[village_id].global_position = new_pos
