extends Node
class_name UIManager

var info_panel: Panel
var info_label: Label
var current_hovered_node: BaseNode = null
var locked_node: BaseNode = null
var is_panel_locked: bool = false

func _ready() -> void:
	info_panel = get_node("../../UILayer/InfoPanel")
	info_label = get_node("../../UILayer/InfoPanel/Label")
	info_panel.visible = false

func show_node_info(node: BaseNode) -> void:
	"""Display node information"""
	current_hovered_node = node
	var info = node.get_node_info()
	
	var text = ""
	# Location name and description
	text += "📍 %s\n" % info["location_name"]
	text += "%s\n\n" % info["location_description"]
	
	# Basic info
	text += "Type: %s\n" % info["type"]
	text += "Altitude: %s\n" % info["altitude"]
	text += "Status: %s\n" % ("✅ Player" if info["player_controlled"] else "❌ Enemy")
	text += "\nResources:\n"
	text += "  Food: %d\n" % info["resources"]["food"]
	text += "  Population: %d\n" % info["resources"]["population"]
	text += "  Units: %d\n" % info["resources"]["units"]
	text += "\nAdjacent Nodes: %d" % info["neighbors_count"]
	
	# Display stationed units
	if node.stationed_units.size() > 0:
		text += "\n\nStationed Units:"
		for unit in node.stationed_units:
			var unit_str = "  • %s" % unit.unit_name
			if unit.is_special:
				unit_str += " ⭐"
			text += "\n" + unit_str
	
	# If village, show max population
	if node is VillageNode:
		text += "\nMax Population: %d" % node.max_population
	
	info_label.text = text
	info_panel.visible = true

func hide_node_info() -> void:
	"""Hide node information"""
	current_hovered_node = null
	# Only hide if not locked
	if not is_panel_locked:
		info_panel.visible = false

func update_position_to_node(node: BaseNode) -> void:
	"""Update panel position relative to node"""
	if is_panel_locked:
		return
	
	if not node:
		return
	
	var camera = get_tree().root.get_node("Main/Camera2D")
	if not camera:
		return
	
	# Convert node world position to screen position
	var node_world_pos = node.global_position
	var camera_pos = camera.global_position
	var zoom = camera.zoom
	var relative_pos = node_world_pos - camera_pos
	var viewport_size = get_viewport().get_visible_rect().size
	var viewport_center = viewport_size / 2
	var node_screen_pos = viewport_center + relative_pos * zoom
	
	# Position panel above the node with offset
	var panel_size = info_panel.size
	var new_x = node_screen_pos.x - panel_size.x / 2
	var new_y = node_screen_pos.y - panel_size.y - 20
	
	# Prevent panel from going off-screen
	if new_x < 0:
		new_x = 0
	if new_x + panel_size.x > viewport_size.x:
		new_x = viewport_size.x - panel_size.x
	if new_y < 0:
		new_y = node_screen_pos.y + 20
	if new_y + panel_size.y > viewport_size.y:
		new_y = viewport_size.y - panel_size.y
	
	info_panel.position = Vector2(new_x, new_y)

func lock_node_info(node: BaseNode) -> void:
	"""Lock node information panel"""
	is_panel_locked = true
	locked_node = node
	show_node_info(node)
	# Fixed at top-left
	info_panel.position = Vector2(10, 10)
	print("Locked node: %s" % node.location_name)

func unlock_node_info() -> void:
	"""Unlock node information panel"""
	is_panel_locked = false
	locked_node = null
	info_panel.visible = false
	print("Unlocked node information panel")
