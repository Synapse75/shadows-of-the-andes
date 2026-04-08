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
	
	# Altitude and control status
	text += "Altitude: %s\n" % info["altitude"]
	text += "Status: %s\n" % ("✅ Player Controlled" if info["player_controlled"] else "❌ Enemy Controlled")
	
	# Population
	text += "\nPopulation: %d\n" % info["resources"].get("population", 0)
	
	# Resources - display all resource types
	text += "\nResources:\n"
	var has_resources = false
	for resource_type in info["resources"]:
		# Skip meta resources (population, food, units)
		if resource_type not in ["food", "population", "units"]:
			var amount = info["resources"][resource_type]
			text += "  • %s: %d/10\n" % [resource_type.capitalize(), amount]
			has_resources = true
	
	if not has_resources:
		text += "  (None)\n"
	
	text += "\nAdjacent Nodes: %d" % info["neighbors_count"]
	
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
	
	# Get node world position as base
	var node_world_pos = node.global_position
	var viewport_size = get_viewport().get_visible_rect().size
	
	# Position panel above the node (offset from node center)
	var panel_size = info_panel.size
	var new_x = node_world_pos.x - panel_size.x / 2
	var new_y = node_world_pos.y - 60  # Position above the node label
	
	# Prevent panel from going off-screen
	if new_x < 0:
		new_x = 0
	if new_x + panel_size.x > viewport_size.x:
		new_x = viewport_size.x - panel_size.x
	if new_y < 0:
		new_y = node_world_pos.y + 20  # If above doesn't fit, place below
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
