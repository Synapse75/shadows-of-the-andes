extends Node
class_name VillageUIManager

# UI管理
var game_map: GameMap
var village_ui_nodes: Dictionary = {}  # village_id -> VillageNode

func _ready() -> void:
	game_map = get_tree().root.get_node("Main/Map")
	
	# 收集所有村庄的UI引用
	_collect_village_uis()

func _collect_village_uis() -> void:
	"""从所有村庄Prefab中收集UI引用"""
	for node in game_map.all_nodes:
		if node is VillageNode:
			village_ui_nodes[node.node_id] = node
