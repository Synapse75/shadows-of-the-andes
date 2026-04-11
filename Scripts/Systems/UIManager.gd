extends Node
class_name UIManager

var info_panel: Panel
var info_label: RichTextLabel
var current_hovered_node: BaseNode = null
var locked_node: BaseNode = null
var is_panel_locked: bool = false

# 海拔图标映射
var altitude_icons: Dictionary = {
	"high": "res://Sprites/high.png",
	"middle": "res://Sprites/middle.png",
	"low": "res://Sprites/low.png"
}

func _ready() -> void:
	info_panel = get_node("../../UILayer/InfoPanel")
	var old_label = get_node("../../UILayer/InfoPanel/Label")
	
	# 获取旧 Label 的样式引用
	var old_font = old_label.get_theme_font("font")
	var old_font_size = old_label.get_theme_font_size("font_size")
	
	# 创建 RichTextLabel 替代原有的 Label
	info_label = RichTextLabel.new()
	info_label.name = "Label"
	info_label.offset_left = 10.0
	info_label.offset_top = 10.0
	info_label.offset_right = 340.0
	info_label.offset_bottom = 270.0
	info_label.bbcode_enabled = true
	info_label.scroll_active = true
	
	# 继承旧样式
	if old_font:
		info_label.add_theme_font_override("normal_font", old_font)
		info_label.add_theme_font_override("bold_font", old_font)
	if old_font_size:
		info_label.add_theme_font_size_override("normal_font_size", old_font_size)
		info_label.add_theme_font_size_override("bold_font_size", old_font_size)
	
	# 设置文字颜色为黑色
	info_label.add_theme_color_override("default_color", Color.BLACK)
	info_label.add_theme_color_override("font_bold_color", Color.BLACK)
	
	# 替换旧的 Label
	old_label.queue_free()
	info_panel.add_child(info_label)
	
	info_panel.visible = false
	# 增加面板高度（保持宽度不变）
	info_panel.custom_minimum_size = Vector2(info_panel.custom_minimum_size.x, 400)

func show_node_info(node: BaseNode) -> void:
	"""Display node information in bottom-left (without resources)"""
	print("[UIManager.show_node_info] Showing info for: %s" % node.node_id)
	current_hovered_node = node
	var info = node.get_node_info()
	
	var text = ""
	# Location name and description
	text += "[b]📍 %s[/b]\n" % info["location_name"]
	text += "%s\n\n" % info["location_description"]
	
	# Altitude with icon
	var altitude = info["altitude"]
	var altitude_icon_path = altitude_icons.get(altitude, "")
	if altitude_icon_path and ResourceLoader.exists(altitude_icon_path):
		text += "[b]Altitude:[/b] [img=20x20]%s[/img] %s\n" % [altitude_icon_path, altitude.capitalize()]
	else:
		text += "[b]Altitude:[/b] %s\n" % altitude.capitalize()
	
	# Control status
	text += "Status: %s\n" % ("✅ Player Controlled" if info["player_controlled"] else "❌ Enemy Controlled")
	
	# Population
	text += "\n[b]Population:[/b] %d\n" % info["resources"].get("population", 0)
	
	# Note: Resources are now displayed as icons on the map
	text += "\n[i](Resources shown as icons on map)[/i]"
	text += "\n[b]Adjacent Nodes:[/b] %d" % info["neighbors_count"]
	
	info_label.text = text
	info_panel.visible = true
	# 固定在左下角
	_set_panel_bottom_left()
	
	# Show resource icons on map
	if node and node.has_method("show_resource_icons"):
		node.show_resource_icons()

func hide_node_info() -> void:
	"""Hide node information and icons"""
	print("[UIManager.hide_node_info] Hiding info")
	current_hovered_node = null
	# Only hide if not locked
	if not is_panel_locked:
		info_panel.visible = false
		# Hide all nodes' resource icons
		get_tree().call_group("nodes", "hide_resource_icons")

func _set_panel_bottom_left() -> void:
	"""Set panel position to bottom-left corner"""
	var viewport_size = get_viewport().get_visible_rect().size
	var panel_size = info_panel.size
	# Bottom-left: 10 pixels from left and bottom edges
	info_panel.position = Vector2(10, viewport_size.y - panel_size.y - 10)

func update_position_to_node(node: BaseNode) -> void:
	"""Update panel position - now fixed at bottom-left"""
	if is_panel_locked:
		return

func lock_node_info(node: BaseNode) -> void:
	"""Lock node information panel at bottom-left"""
	is_panel_locked = true
	locked_node = node
	show_node_info(node)
	# Already positioned at bottom-left by show_node_info()
	print("Locked node: %s" % node.location_name)

func unlock_node_info() -> void:
	"""Unlock node information panel"""
	is_panel_locked = false
	locked_node = null
	info_panel.visible = false
	get_tree().call_group("nodes", "hide_resource_icons")
	print("Unlocked node information panel")
