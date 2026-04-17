extends Node
class_name UIManager

var info_panel: Panel
var info_label: Label
var recruit_button: TextureButton
var current_hovered_node: VillageNode = null
var locked_node: VillageNode = null
var is_panel_locked: bool = false

# InfoPanel 资源图标显示
var altitude_texture_rect: TextureRect
var resource1_texture_rect: TextureRect
var resource2_texture_rect: TextureRect

# 资源容器
var resources_scroll_container: ScrollContainer
var resources_vbox: VBoxContainer

# 海拔图标映射
var altitude_icons: Dictionary = {
	"high": "res://Sprites/high.png",
	"medium": "res://Sprites/middle.png",
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

# 单位图标映射
var unit_icons: Dictionary = {
	"rebel_army": "res://Sprites/rebelarmy.png",
	"female_corps": "res://Sprites/femalecorps.png",
	"enemy": "res://Sprites/enemy.png"
}

# resourcepanel 背景
var resource_panel_bg: String = "res://Sprites/resourcepanel.png"
var unit_panel_bg: String = "res://Sprites/unitpanel.png"
var enemy_panel_bg: String = "res://Sprites/enemypanel.png"

func _ready() -> void:
	info_panel = get_node("../../UILayer/InfoPanel")
	var old_label = get_node("../../UILayer/InfoPanel/Label")
	
	# 获取旧 Label 的样式引用
	var old_font = old_label.get_theme_font("font")
	var old_font_size = old_label.get_theme_font_size("font_size")
	
	# 创建 Label 替代原有的 RichTextLabel
	info_label = Label.new()
	info_label.name = "Label"
	info_label.layout_mode = 1  # Anchored layout
	info_label.anchors_preset = 15  # Fill parent
	info_label.offset_left = 10.0
	info_label.offset_top = 5.0
	info_label.offset_right = -10.0
	info_label.offset_bottom = -5.0
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	
	# 继承旧样式
	if old_font:
		info_label.add_theme_font_override("font", old_font)
	if old_font_size:
		info_label.add_theme_font_size_override("font_size", old_font_size)
	
	# 设置文字颜色为黑色
	info_label.add_theme_color_override("font_color", Color.BLACK)
	
	# 替换旧的 Label
	old_label.queue_free()
	info_panel.add_child(info_label)
	
	info_panel.visible = false
	
	# 设置 InfoPanel 的背景纹理
	var info_panel_stylebox = StyleBoxTexture.new()
	if ResourceLoader.exists("res://Sprites/infopanel.png"):
		info_panel_stylebox.texture = ResourceLoader.load("res://Sprites/infopanel.png")
	info_panel.add_theme_stylebox_override("panel", info_panel_stylebox)
	
	# 获取 InfoPanel 下的资源图标 TextureRect
	altitude_texture_rect = get_node_or_null("../../UILayer/InfoPanel/Altitude")
	resource1_texture_rect = get_node_or_null("../../UILayer/InfoPanel/Resource1")
	resource2_texture_rect = get_node_or_null("../../UILayer/InfoPanel/Resource2")
	
	# 获取 RecruitButton
	recruit_button = get_node_or_null("../../UILayer/RecruitButton")
	if recruit_button:
		recruit_button.pressed.connect(_on_recruit_button_pressed)
	
	# 获取手动添加的 ScrollContainer
	var ui_layer = get_node("../../UILayer")
	
	resources_scroll_container = ui_layer.get_node("ScrollContainer")
	if resources_scroll_container:
		if resources_scroll_container.get_child_count() > 0:
			resources_vbox = resources_scroll_container.get_child(0) as VBoxContainer
			if resources_vbox:
				resources_vbox.add_theme_constant_override("separation", 0)
		resources_scroll_container.visible = false
	else:
		push_error("[UIManager] ScrollContainer not found in UILayer!")
	
	# 连接 GameMap 的点击事件
	var game_map = get_tree().root.get_node("Main/SubViewportContainer/SubViewport/Map")
	if game_map and game_map.has_signal("node_selected"):
		game_map.node_selected.connect(_on_node_selected)

func show_node_info(node: VillageNode) -> void:
	"""Display node information in bottom-left and show resources/units in left panel"""
	current_hovered_node = node
	locked_node = node  # Lock the node for recruitment and other operations
	var info = node.get_node_info()
	
	var text = ""
	# Location name
	text += info["location_name"] + "\n"
	
	# Population
	text += "Pop: %d" % info["resources"].get("population", 0)
	
	# Show hunger status (GDD 4.4)
	if node.hunger_status:
		text += " [HUNGRY]"
	
	info_label.text = text
	info_panel.visible = true
	
	# Set altitude icon in TextureRect
	var altitude = info["altitude"]
	var altitude_icon_path = altitude_icons.get(altitude, "")
	if altitude_texture_rect:
		if altitude_icon_path and ResourceLoader.exists(altitude_icon_path):
			altitude_texture_rect.texture = load(altitude_icon_path)
		else:
			altitude_texture_rect.texture = null
	
	# Set produced resource icons
	if resource1_texture_rect:
		resource1_texture_rect.texture = null
	if resource2_texture_rect:
		resource2_texture_rect.texture = null
	
	var produced_resources = node.produced_resource_types
	if produced_resources.size() > 0 and resource1_texture_rect:
		var resource1_path = resource_icons.get(produced_resources[0], "")
		if resource1_path and ResourceLoader.exists(resource1_path):
			resource1_texture_rect.texture = load(resource1_path)
	
	if produced_resources.size() > 1 and resource2_texture_rect:
		var resource2_path = resource_icons.get(produced_resources[1], "")
		if resource2_path and ResourceLoader.exists(resource2_path):
			resource2_texture_rect.texture = load(resource2_path)
	
	# Display resources and units in left panel
	_display_node_resources(node)
	if resources_scroll_container:
		resources_scroll_container.visible = true
	
	# Show RecruitButton
	if recruit_button:
		recruit_button.visible = true

func _on_node_selected(node: VillageNode) -> void:
	"""Handle node click - display information via show_node_info"""
	show_node_info(node)

func hide_node_info() -> void:
	"""Hide node information and icons"""
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

func unlock_node_info() -> void:
	"""Unlock node information panel"""
	is_panel_locked = false
	locked_node = null
	info_panel.visible = false

func _display_node_resources(node: VillageNode) -> void:
	"""Display resources and units for the given node"""
	if not resources_vbox:
		return
	
	# Clear previous entries
	for child in resources_vbox.get_children():
		child.queue_free()
	
	# 加载 ClearFont
	var clear_font = ResourceLoader.load("res://Fonts/ClearFont.ttf")
	
	# 显示玩家单位标题 ========================================
	var unit_title = Label.new()
	unit_title.text = "--- Units ---"
	unit_title.add_theme_font_override("font", clear_font)
	unit_title.add_theme_font_size_override("font_size", 16)
	unit_title.add_theme_color_override("font_color", Color.WHITE)
	resources_vbox.add_child(unit_title)
	
	# 显示每个单位
	for unit in node.stationed_units:
		_create_unit_panel_row(unit)
	
	# 显示资源标题 ========================================
	var resource_title = Label.new()
	resource_title.text = "--- Resources ---"
	resource_title.add_theme_font_override("font", clear_font)
	resource_title.add_theme_font_size_override("font_size", 16)
	resource_title.add_theme_color_override("font_color", Color.WHITE)
	resources_vbox.add_child(resource_title)
	
	# 显示资源
	var resource_types = ["potato", "corn", "quinoa", "llama", "coca"]
	for resource_type in resource_types:
		var amount = node.resources.get(resource_type, 0)
		if amount > 0:
			_create_resource_panel_row(resource_type, amount)
	
	# 显示敌方单位标题 ========================================
	var enemy_title = Label.new()
	enemy_title.text = "--- Enemies ---"
	enemy_title.add_theme_font_override("font", clear_font)
	enemy_title.add_theme_font_size_override("font_size", 16)
	enemy_title.add_theme_color_override("font_color", Color.WHITE)
	resources_vbox.add_child(enemy_title)
	
	# 显示每个敌方单位
	for enemy_unit in node.enemy_units:
		_create_enemy_unit_panel_row(enemy_unit)

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
	var clear_font = ResourceLoader.load("res://Fonts/ClearFont.ttf")
	amount_label.add_theme_font_override("font", clear_font)
	amount_label.add_theme_font_size_override("font_size", 16)
	
	inner_hbox.add_child(icon_texture)
	inner_hbox.add_child(amount_label)
	bg_panel.add_child(inner_hbox)
	
	resources_vbox.add_child(bg_panel)

func _create_unit_panel_row(unit: Unit) -> void:
	"""Create a single unit panel row"""
	# Unit icon (32x32)
	var icon_path = unit_icons.get(unit.unit_type, "")
	
	# Check if icon exists
	if not icon_path or not ResourceLoader.exists(icon_path):
		return
	
	# Background panel (140x40)
	var bg_panel = Panel.new()
	bg_panel.custom_minimum_size = Vector2(140, 40)
	var stylebox = StyleBoxTexture.new()
	if ResourceLoader.exists(unit_panel_bg):
		stylebox.texture = ResourceLoader.load(unit_panel_bg)
	bg_panel.add_theme_stylebox_override("panel", stylebox)
	
	# Inner container for content (positioned at 4,4 inside the panel)
	var inner_hbox = HBoxContainer.new()
	inner_hbox.add_theme_constant_override("separation", 4)
	inner_hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	inner_hbox.offset_left = 4
	inner_hbox.offset_top = 4
	inner_hbox.offset_right = 4
	inner_hbox.offset_bottom = 4
	inner_hbox.custom_minimum_size = Vector2(132, 32)
	
	# Unit icon
	var icon_texture = TextureRect.new()
	icon_texture.texture = ResourceLoader.load(icon_path)
	icon_texture.custom_minimum_size = Vector2(32, 32)
	icon_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	
	# Unit name label
	var name_label = Label.new()
	name_label.text = unit.unit_name
	var clear_font = ResourceLoader.load("res://Fonts/ClearFont.ttf")
	name_label.add_theme_font_override("font", clear_font)
	name_label.add_theme_font_size_override("font_size", 16)
	
	inner_hbox.add_child(icon_texture)
	inner_hbox.add_child(name_label)
	bg_panel.add_child(inner_hbox)
	
	resources_vbox.add_child(bg_panel)

func _create_enemy_unit_panel_row(enemy_unit: EnemyUnit) -> void:
	"""Create a single enemy unit panel row"""
	# Enemy unit icon
	var icon_path = unit_icons.get(enemy_unit.unit_type, "")
	
	# Check if icon exists
	if not icon_path or not ResourceLoader.exists(icon_path):
		return
	
	# Background panel (140x40)
	var bg_panel = Panel.new()
	bg_panel.custom_minimum_size = Vector2(140, 40)
	var stylebox = StyleBoxTexture.new()
	if ResourceLoader.exists(enemy_panel_bg):
		stylebox.texture = ResourceLoader.load(enemy_panel_bg)
	bg_panel.add_theme_stylebox_override("panel", stylebox)
	
	# Inner container for content (positioned at 4,4 inside the panel)
	var inner_hbox = HBoxContainer.new()
	inner_hbox.add_theme_constant_override("separation", 4)
	inner_hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	inner_hbox.offset_left = 4
	inner_hbox.offset_top = 4
	inner_hbox.offset_right = 4
	inner_hbox.offset_bottom = 4
	inner_hbox.custom_minimum_size = Vector2(132, 32)
	
	# Enemy unit icon
	var icon_texture = TextureRect.new()
	icon_texture.texture = ResourceLoader.load(icon_path)
	icon_texture.custom_minimum_size = Vector2(32, 32)
	icon_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	
	# Enemy unit name label
	var name_label = Label.new()
	name_label.text = enemy_unit.unit_name
	var clear_font = ResourceLoader.load("res://Fonts/ClearFont.ttf")
	name_label.add_theme_font_override("font", clear_font)
	name_label.add_theme_font_size_override("font_size", 16)
	
	inner_hbox.add_child(icon_texture)
	inner_hbox.add_child(name_label)
	bg_panel.add_child(inner_hbox)
	
	resources_vbox.add_child(bg_panel)

func _on_recruit_button_pressed() -> void:
	"""Recruit a new unit at the locked node"""
	if not locked_node:
		return
	
	if not locked_node.control_by_player:
		return
	
	# Check population requirement (25 population per unit)
	if locked_node.population < 25:
		show_recruitment_failed_tooltip("Not enough population!\n(Need 25, Have %d)" % locked_node.population)
		return
	
	# Recruit a unit - 80% Rebel Army, 20% Female Corps
	var unit: Unit
	if randf() < 0.8:
		unit = RebelArmy.new()
	else:
		unit = FemaleCorps.new()
	
	# Set unit position and add to node
	unit.current_node = locked_node
	locked_node.add_unit(unit)
	locked_node.population -= 25
	locked_node.resources["population"] -= 25  # Also update resources dict
	
	# Refresh display
	show_node_info(locked_node)

func show_recruitment_failed_tooltip(message: String) -> void:
	"""Show a temporary tooltip at the top-left when recruitment fails"""
	var ui_layer = get_node("../../UILayer")
	
	# Create a temporary label at top-left
	var tooltip = Label.new()
	tooltip.text = message
	tooltip.add_theme_font_override("font", ResourceLoader.load("res://Fonts/ClearFont.ttf"))
	tooltip.add_theme_font_size_override("font_size", 12)
	tooltip.add_theme_color_override("font_color", Color.RED)
	tooltip.position = Vector2(5, 5)
	
	# Add to UILayer
	ui_layer.add_child(tooltip)
	
	# Auto-remove after 2 seconds
	await get_tree().create_timer(2.0).timeout
	tooltip.queue_free()

func refresh_displayed_node_info() -> void:
	"""Refresh the currently displayed node info (called after auto phase ends)
	This ensures that all resource/population changes are reflected in the UI"""
	if locked_node and info_panel.visible:
		show_node_info(locked_node)
