extends Node
class_name UIManager

var info_panel: Panel
var info_label: RichTextLabel
var current_hovered_node: VillageNode = null
var locked_node: VillageNode = null
var is_panel_locked: bool = false

# 资源容器
var resources_scroll_container: ScrollContainer
var resources_vbox: VBoxContainer

# 海拔图标映射
var altitude_icons: Dictionary = {
	"high": "res://Sprites/high.png",
	"middle": "res://Sprites/middle.png",
	"low": "res://Sprites/low.png"
}

# 资源图标映射
var resource_icons: Dictionary = {
	"potato": "res://Sprites/potato.png",
	"llama": "res://Sprites/llama.png",
	"corn": "res://Sprites/corn.png",
	"quinoa": "res://Sprites/quinoa.png",
	"coca": "res://Sprites/coca.png"
}

# resourcepanel 背景
var resource_panel_bg: String = "res://Sprites/resourcepanel.png"

func _ready() -> void:
	info_panel = get_node("../../UILayer/InfoPanel")
	var old_label = get_node("../../UILayer/InfoPanel/Label")
	
	# 获取旧 Label 的样式引用
	var old_font = old_label.get_theme_font("font")
	var old_font_size = old_label.get_theme_font_size("font_size")
	
	# 创建 RichTextLabel 替代原有的 Label
	info_label = RichTextLabel.new()
	info_label.name = "Label"
	info_label.offset_left = 2.0
	info_label.offset_top = 2.0
	info_label.offset_right = 2.0
	info_label.offset_bottom = 2.0
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
	# 调整面板大小以适配 480x300 分辨率
	info_panel.custom_minimum_size = Vector2(87, 70)
	
	# 获取手动添加的 ScrollContainer
	print("[UIManager._ready] UIManager path: ", get_path())
	var ui_layer = get_node("../../UILayer")
	print("[UIManager._ready] UILayer path: ", ui_layer.get_path())
	print("[UIManager._ready] UILayer children count: ", ui_layer.get_child_count())
	
	resources_scroll_container = ui_layer.get_node("ScrollContainer")
	if resources_scroll_container:
		print("[UIManager._ready] Found ScrollContainer!")
		if resources_scroll_container.get_child_count() > 0:
			resources_vbox = resources_scroll_container.get_child(0) as VBoxContainer
			if resources_vbox:
				resources_vbox.add_theme_constant_override("separation", 0)
				print("[UIManager._ready] Found VBoxContainer inside ScrollContainer")
			else:
				print("[UIManager._ready] ERROR: First child is not VBoxContainer")
		else:
			print("[UIManager._ready] ERROR: ScrollContainer has no children")
		resources_scroll_container.visible = false
	else:
		print("[UIManager] ERROR: ScrollContainer not found in UILayer!")
		print("[UIManager] Available nodes in UILayer:")
		for child in ui_layer.get_children():
			print("  - ", child.name)
	
	# 连接 GameMap 的点击事件
	var game_map = get_tree().root.get_node("Main/SubViewportContainer/SubViewport/Map")
	if game_map and game_map.has_signal("node_selected"):
		game_map.node_selected.connect(_on_node_selected)

func show_node_info(node: VillageNode) -> void:
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
	
	info_label.text = text
	info_panel.visible = true
	
	# 悬浮时隐藏资源列表（点击时才显示）
	if resources_scroll_container:
		resources_scroll_container.visible = false

func _on_node_selected(node: VillageNode) -> void:
	"""Handle node click - display resources in left panel"""
	_display_node_resources(node)
	if resources_scroll_container:
		resources_scroll_container.visible = true

func hide_node_info() -> void:
	"""Hide node information and icons"""
	print("[UIManager.hide_node_info] Hiding info")
	current_hovered_node = null
	# Only hide if not locked
	if not is_panel_locked:
		info_panel.visible = false
		# 注意：不隐藏 resources_scroll_container，保留资源面板直到点击新节点
		# Hide all nodes' resource icons
		pass

func update_position_to_node(node: VillageNode) -> void:
	"""Panel position is manually set in editor"""
	pass

func lock_node_info(node: VillageNode) -> void:
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
	print("Unlocked node information panel")

func _display_node_resources(node: VillageNode) -> void:
	"""Display resources for the given node"""
	if not resources_vbox:
		print("[UIManager._display_node_resources] ERROR: resources_vbox is null!")
		return
	
	# Clear previous entries
	for child in resources_vbox.get_children():
		child.queue_free()
	
	# 资源类型列表（按优先级）
	var resource_types = ["potato", "corn", "quinoa", "llama", "coca"]
	
	# Create resource panel for each resource type with amount > 0
	for resource_type in resource_types:
		var amount = node.resources.get(resource_type, 0)
		if amount > 0:
			_create_resource_panel_row(resource_type, amount)

func _create_resource_panel_row(resource_type: String, amount: int) -> void:
	"""Create a single resource panel row"""
	# Background panel (140x40)
	var bg_panel = Panel.new()
	bg_panel.custom_minimum_size = Vector2(140, 40)
	var stylebox = StyleBoxTexture.new()
	if ResourceLoader.exists(resource_panel_bg):
		stylebox.texture = ResourceLoader.load(resource_panel_bg)
	bg_panel.add_theme_stylebox_override("panel", stylebox)
	
	# Inner container for content (positioned at 4,4 inside the panel)
	var inner_hbox = HBoxContainer.new()
	inner_hbox.add_theme_constant_override("separation", 4)
	inner_hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	# Position the inner container at (4,4)
	inner_hbox.offset_left = 4
	inner_hbox.offset_top = 4
	inner_hbox.offset_right = 4
	inner_hbox.offset_bottom = 4
	inner_hbox.custom_minimum_size = Vector2(132, 32)
	
	# Resource icon (32x32)
	var icon_texture = TextureRect.new()
	var icon_path = resource_icons.get(resource_type, "")
	if icon_path and ResourceLoader.exists(icon_path):
		icon_texture.texture = ResourceLoader.load(icon_path)
	icon_texture.custom_minimum_size = Vector2(32, 32)
	icon_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	
	# Amount label
	var amount_label = Label.new()
	amount_label.text = "×" + str(amount)
	amount_label.add_theme_font_size_override("font_size", 10)
	
	inner_hbox.add_child(icon_texture)
	inner_hbox.add_child(amount_label)
	bg_panel.add_child(inner_hbox)
	
	resources_vbox.add_child(bg_panel)
