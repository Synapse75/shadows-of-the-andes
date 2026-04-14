extends Node
class_name UIFollowCamera

# 璺熼殢鎽勫儚鏈虹殑UI缁勪欢
var camera: Camera2D
var ui_layer: CanvasLayer
var village_ui_manager: VillageUIManager

func _ready() -> void:
	# 鑾峰彇寮曠敤
	camera = get_tree().root.get_node("Main/SubViewportContainer/SubViewport/Camera2D")
	ui_layer = get_tree().root.get_node("Main/UILayer")
	village_ui_manager = get_tree().root.get_node("Main/UILayer/VillageUIManager")
	
	set_process(true)

func _process(_delta: float) -> void:
	"""姣忓抚鏇存柊UI浣嶇疆浠ヨ窡闅忔憚鍍忔満"""
	if not camera or not village_ui_manager:
		return
	
	# 鏇存柊鎵€鏈夋潙搴刄I绮剧伒鐨勫睆骞曞潗鏍?
	for village_id in village_ui_manager.village_ui_nodes:
		var sprite = village_ui_manager.village_ui_nodes[village_id]
		var game_map = get_tree().root.get_node("Main/SubViewportContainer/SubViewport/Map")
		
		# 鑾峰彇瀵瑰簲鐨勬潙搴勮妭鐐?
		for node in game_map.all_nodes:
			if node.node_id == village_id:
				# 璁＄畻涓栫晫鍧愭爣鍦ㄥ睆骞曚笂鐨勬姇褰?
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
