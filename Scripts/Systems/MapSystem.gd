extends Node
class_name MapSystem

# 地图视野数据结构（内部类）
class MapView:
	var id: String
	var display_name: String
	var camera_position: Vector2
	var connected_maps: Array[String] = []  # 可到达的地图ID列表

# 地图系统
var map_views: Dictionary = {}  # id -> MapView
var current_map_id: String = ""
var explored_maps: Array[String] = []  # 已探索的地图ID

# 切换按钮管理
var current_map_buttons: Array[Button] = []

signal map_changed(map_id: String)
signal exploration_changed(explored_maps: Array[String])

func _ready():
	# 初始化地图结构（用户可以在编辑器中扩展）
	# 这里提供一个示例，玩家可能需要在代码中添加更多地图
	pass

# 注册一个地图视野
func register_map_view(id: String, display_name: String, camera_pos: Vector2, connected_to: Array[String] = []):
	var map_view = MapView.new()
	map_view.id = id
	map_view.display_name = display_name
	map_view.camera_position = camera_pos
	map_view.connected_maps = connected_to
	map_views[id] = map_view

# 探索一个新地图
func explore_map(map_id: String):
	if map_id in map_views and not map_id in explored_maps:
		explored_maps.append(map_id)
		exploration_changed.emit(explored_maps)

# 设置初始地图
func set_starting_map(map_id: String):
	if map_id in map_views:
		current_map_id = map_id
		explore_map(map_id)
		map_changed.emit(map_id)

# 从当前地图切换到另一个地图
func switch_map(target_map_id: String) -> bool:
	# 检查目标地图是否存在
	if not target_map_id in map_views:
		push_error("地图不存在: " + target_map_id)
		return false
	
	# 检查是否已探索
	if not target_map_id in explored_maps:
		push_error("地图尚未探索: " + target_map_id)
		return false
	
	# 检查是否有连接关系
	var current_map = map_views[current_map_id]
	if current_map.connected_maps.size() > 0 and not target_map_id in current_map.connected_maps:
		push_error("无法从 %s 到达 %s" % [current_map_id, target_map_id])
		return false
	
	current_map_id = target_map_id
	map_changed.emit(target_map_id)
	return true

# 获取当前地图可以到达的地图列表
func get_accessible_maps() -> Array[String]:
	var current_map = map_views[current_map_id]
	var accessible: Array[String] = []
	
	if current_map.connected_maps.size() == 0:
		# 如果没有设置连接关系，返回所有已探索地图
		return explored_maps
	else:
		# 返回已连接且已探索的地图
		for map_id in current_map.connected_maps:
			if map_id in explored_maps:
				accessible.append(map_id)
		return accessible

# 获取地图对象
func get_map_view(map_id: String) -> MapView:
	return map_views.get(map_id, null)

# 获取当前地图信息
func get_current_map() -> MapView:
	return map_views.get(current_map_id, null)
