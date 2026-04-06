extends Node
class_name VillageUIManager

# UI管理
var game_map: GameMap
var village_ui_nodes: Dictionary = {}  # village_id -> Sprite2D UI node

# Sprite资源
var controlled_sprite: Texture2D
var uncontrolled_sprite: Texture2D

signal village_ui_clicked(village_id: String)

func _ready() -> void:
	game_map = get_tree().root.get_node("Main/Map")
	
	# 加载sprite资源
	controlled_sprite = load("res://Sprites/village_controlled.png")
	uncontrolled_sprite = load("res://Sprites/village_uncontrolled.png")
	
	# 为每个村庄创建UI
	_create_village_uis()

func _create_village_uis() -> void:
	"""为所有村庄创建UI节点"""
	for village in game_map.all_nodes:
		if village is VillageNode:
			_create_ui_for_village(village)
	
	print("村庄UI创建完成，共 %d 个村庄" % village_ui_nodes.size())

func _create_ui_for_village(village: VillageNode) -> void:
	"""为单个村庄创建UI"""
	var sprite = Sprite2D.new()
	sprite.global_position = village.global_position
	sprite.name = village.node_id + "_UI"
	
	# 设置初始sprite
	if village.control_by_player:
		sprite.texture = controlled_sprite
	else:
		sprite.texture = uncontrolled_sprite
	
	# 添加到UILayer
	add_child(sprite)
	
	# 存储引用
	village_ui_nodes[village.node_id] = sprite
	
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
		var mouse_pos = event.position
		
		# 检查是否点击了某个村庄UI
		for village_id in village_ui_nodes:
			var sprite = village_ui_nodes[village_id]
			var sprite_rect = Rect2(sprite.global_position - sprite.get_rect().size / 2, sprite.get_rect().size)
			
			if sprite_rect.has_point(mouse_pos):
				village_ui_clicked.emit(village_id)
				print("点击了村庄: %s" % village_id)
				get_tree().root.set_input_as_handled()
				break

func update_village_position(village_id: String, new_pos: Vector2) -> void:
	"""更新村庄UI的位置（当村庄移动时调用）"""
	if village_id in village_ui_nodes:
		village_ui_nodes[village_id].global_position = new_pos
