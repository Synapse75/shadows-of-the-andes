extends Node
class_name UIFollowCamera

# 跟随摄像机的UI组件
var camera: Camera2D
var ui_layer: CanvasLayer
var village_ui_manager: VillageUIManager

func _ready() -> void:
	# 获取引用
	camera = get_tree().root.get_node("Main/Camera2D")
	ui_layer = get_tree().root.get_node("Main/UILayer")
	village_ui_manager = get_tree().root.get_node("Main/UILayer/VillageUIManager")
	
	set_process(true)

func _process(_delta: float) -> void:
	"""每帧更新UI位置以跟随摄像机"""
	if not camera or not village_ui_manager:
		return
	
	# 更新所有村庄UI精灵的屏幕坐标
	for village_id in village_ui_manager.village_ui_nodes:
		var sprite = village_ui_manager.village_ui_nodes[village_id]
		var game_map = get_tree().root.get_node("Main/Map")
		
		# 获取对应的村庄节点
		for node in game_map.all_nodes:
			if node.node_id == village_id:
				# 计算世界坐标在屏幕上的投影
				var world_pos = node.global_position
				var screen_pos = _world_to_screen(world_pos)
				
				# 更新精灵的屏幕位置
				sprite.position = screen_pos
				break

func _world_to_screen(world_pos: Vector2) -> Vector2:
	"""将世界坐标转换为屏幕坐标"""
	if not camera:
		return world_pos
	
	# 获取摄像机相对于世界坐标的偏移
	var camera_world_pos = camera.global_position
	
	# 计算相对于摄像机中心的位置
	var relative_pos = world_pos - camera_world_pos
	
	# 获取视口大小
	var viewport_size = get_viewport().get_visible_rect().size
	var viewport_center = viewport_size / 2
	
	# 应用缩放并转换为屏幕坐标
	var screen_pos = viewport_center + relative_pos * camera.zoom
	
	return screen_pos
