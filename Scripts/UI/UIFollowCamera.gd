extends Node
class_name UIFollowCamera

# UIFollowCamera deprecated - resource icons removed
var camera: Camera2D
var ui_layer: CanvasLayer
var game_map: GameMap

func _ready() -> void:
	# 获取引用
	camera = get_tree().root.get_node("Main/SubViewportContainer/SubViewport/Camera2D")
	ui_layer = get_tree().root.get_node("Main/UILayer")
	game_map = get_tree().root.get_node("Main/SubViewportContainer/SubViewport/Map")
	
	set_process(true)

func _process(_delta: float) -> void:
	"""每帧更新UI位置以跟随摄像机"""
	if not camera or not game_map:
		return
	
	# 更新所有村庄UI精灵的屏幕座标
	for node in game_map.all_nodes:
		# 计算世界座标在屏幕上的投影
		var world_pos = node.global_position
		var screen_pos = _world_to_screen(world_pos)
		
		# 如果节点有resource_icons_container，更新其屏幕位置
		if node.has_node("ResourceIconsContainer"):
			var resource_container = node.get_node("ResourceIconsContainer")
			resource_container.position = screen_pos
				var world_pos = node.global_position
				var screen_pos = _world_to_screen(world_pos)
				
				# 鏇存柊绮剧伒鐨勫睆骞曚綅缃?
				sprite.position = screen_pos
				break

func _world_to_screen(world_pos: Vector2) -> Vector2:
	"""灏嗕笘鐣屽潗鏍囪浆鎹负灞忓箷鍧愭爣"""
	if not camera:
		return world_pos
	
	# 鑾峰彇鎽勫儚鏈虹浉瀵逛簬涓栫晫鍧愭爣鐨勫亸绉?
	var camera_world_pos = camera.global_position
	
	# 璁＄畻鐩稿浜庢憚鍍忔満涓績鐨勪綅缃?
	var relative_pos = world_pos - camera_world_pos
	
	# 鑾峰彇瑙嗗彛澶у皬
	var viewport_size = camera.get_viewport().get_visible_rect().size
	var viewport_center = viewport_size / 2
	
	# 搴旂敤缂╂斁骞惰浆鎹负灞忓箷鍧愭爣
	var screen_pos = Vector2(480, 270) + viewport_center + relative_pos * camera.zoom
	
	return screen_pos
