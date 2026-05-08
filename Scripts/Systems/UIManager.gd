extends Node
class_name UIManager

var info_panel: Panel
var info_label: Label
var recruit_button: TextureButton
var current_hovered_node: VillageNode = null
var locked_node: VillageNode = null
var is_panel_locked: bool = false

# Cached references
var game_map: GameMap = null
var audio_manager: Node = null

# Drag-and-drop system
var dragging_unit: Unit = null
var drag_start_position: Vector2 = Vector2.ZERO
var is_dragging: bool = false
var valid_drop_targets: Array[VillageNode] = []
var dragging_icon: TextureRect = null  # Icon following mouse during drag
var original_icon: TextureRect = null  # Original icon in panel
var unit_panel_container: Control = null  # Reference to panel with original icon

# Resource drag-and-drop system
var dragging_resource: String = ""
var dragging_resource_amount: int = 0
var dragging_resource_icon: TextureRect = null
var dragging_resource_panel: Panel = null
var original_resource_icon: TextureRect = null

# InfoPanel 资源图标显示
var altitude_texture_rect: TextureRect
var resource1_texture_rect: TextureRect
var resource2_texture_rect: TextureRect

# InfoPanel 海拔文本显示
var altitude_text_label: Label

# 当前选中节点的海拔
var current_altitude: String = ""

# Icon tooltip 面板
var icon_tooltip_panel: Control

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
var _node_signal_connect_retries: int = 0

func _ready() -> void:
	await _initialize_tooltip_system()
	audio_manager = get_node_or_null("../../Systems/AudioManager")
	
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
	altitude_text_label = get_node_or_null("../../UILayer/InfoPanel/AltitudeText")
	resource1_texture_rect = get_node_or_null("../../UILayer/InfoPanel/Resource1")
	resource2_texture_rect = get_node_or_null("../../UILayer/InfoPanel/Resource2")
	
	# 初始化 icon tooltip panel
	icon_tooltip_panel = preload("res://Scenes/UI/IconTooltipPanel.tscn").instantiate()
	get_node("../../UILayer").add_child(icon_tooltip_panel)
	
	# 获取 RecruitButton
	recruit_button = get_node_or_null("../../UILayer/RecruitButton")
	if recruit_button:
		recruit_button.pressed.connect(_on_recruit_button_pressed)
		recruit_button.mouse_entered.connect(func():
			# if audio_manager:
			# 	audio_manager.play_choose()
			if icon_tooltip_panel:
				icon_tooltip_panel.show_text("Need population: 25")
		)
		recruit_button.mouse_exited.connect(func():
			if icon_tooltip_panel:
				icon_tooltip_panel.hide_text()
		)
	
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
	game_map = get_tree().root.get_node("Main/SubViewportContainer/SubViewport/Map") as GameMap
	if game_map and game_map.has_signal("node_selected"):
		game_map.node_selected.connect(_on_node_selected)
	
	# Node data can change during movement/combat; wire realtime refresh.
	call_deferred("_connect_node_runtime_signals")

func _connect_node_runtime_signals() -> void:
	if not game_map:
		return

	# GameMap may still be initializing all_nodes in this frame.
	if game_map.all_nodes.is_empty() and _node_signal_connect_retries < 5:
		_node_signal_connect_retries += 1
		call_deferred("_connect_node_runtime_signals")
		return

	for node in game_map.all_nodes:
		if not (node is VillageNode):
			continue

		var units_callable = Callable(self, "_on_observed_node_changed").bind(node)
		if not node.units_changed.is_connected(units_callable):
			node.units_changed.connect(units_callable)

		var enemies_callable = Callable(self, "_on_observed_node_changed").bind(node)
		if not node.enemy_units_changed.is_connected(enemies_callable):
			node.enemy_units_changed.connect(enemies_callable)

		var resources_callable = Callable(self, "_on_observed_node_changed").bind(node)
		if not node.resources_changed.is_connected(resources_callable):
			node.resources_changed.connect(resources_callable)

		var control_callable = Callable(self, "_on_observed_node_changed").bind(node)
		if not node.control_changed.is_connected(control_callable):
			node.control_changed.connect(control_callable)

func _on_observed_node_changed(_changed_data = null, node: VillageNode = null) -> void:
	if not node:
		return

	if locked_node == node and info_panel.visible:
		# Use call_deferred to avoid multiple updates in the same frame
		call_deferred("show_node_info", node)

func show_node_info(node: VillageNode) -> void:
	"""Display node information in bottom-left and show resources/units in left panel"""
	current_hovered_node = node
	locked_node = node  # Lock the node for recruitment and other operations
	var info = node.get_node_info()
	
	var text = ""
	# Location name
	text += info["location_name"] + "\n"
	
	# Population
	text += "Population: %d\n" % info["resources"].get("population", 0)
	
	# Hunger status (GDD 4.4)
	text += "Hunger: %s" % ("Hungry" if node.hunger_status else "Normal")
	
	info_label.text = text
	info_panel.visible = true
	
	# Set altitude icon in TextureRect
	var altitude = info["altitude"]
	current_altitude = altitude
	var altitude_icon_path = altitude_icons.get(altitude, "")
	if altitude_texture_rect:
		if altitude_icon_path and ResourceLoader.exists(altitude_icon_path):
			altitude_texture_rect.texture = load(altitude_icon_path)
		else:
			altitude_texture_rect.texture = null
		altitude_texture_rect.mouse_filter = Control.MOUSE_FILTER_STOP
		altitude_texture_rect.mouse_entered.connect(func():
			_show_altitude_tooltip(altitude)
		)
		altitude_texture_rect.mouse_exited.connect(func():
			if icon_tooltip_panel:
				icon_tooltip_panel.hide_text()
		)
	
	# Set produced resource icons
	var produced_resources = node.produced_resource_types
	
	if resource1_texture_rect:
		resource1_texture_rect.texture = null
		resource1_texture_rect.mouse_filter = Control.MOUSE_FILTER_STOP
		resource1_texture_rect.mouse_entered.connect(func():
			if produced_resources.size() > 0:
				_show_resource_name_tooltip(produced_resources[0])
		)
		resource1_texture_rect.mouse_exited.connect(func():
			if icon_tooltip_panel:
				icon_tooltip_panel.hide_text()
		)
	if resource2_texture_rect:
		resource2_texture_rect.texture = null
		resource2_texture_rect.mouse_filter = Control.MOUSE_FILTER_STOP
		resource2_texture_rect.mouse_entered.connect(func():
			if produced_resources.size() > 1:
				_show_resource_name_tooltip(produced_resources[1])
		)
		resource2_texture_rect.mouse_exited.connect(func():
			if icon_tooltip_panel:
				icon_tooltip_panel.hide_text()
		)
	
	# Set resource textures
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
	
	# Resource icon (32x32, fixed position)
	var icon_texture = TextureRect.new()
	var icon_path = resource_icons.get(resource_type, "")
	if icon_path and ResourceLoader.exists(icon_path):
		icon_texture.texture = ResourceLoader.load(icon_path)
	icon_texture.offset_left = 4.0
	icon_texture.offset_top = 4.0
	icon_texture.offset_right = 36.0
	icon_texture.offset_bottom = 36.0
	icon_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Resource name label (fixed position)
	var name_label = Label.new()
	name_label.text = resource_type.capitalize()
	name_label.offset_left = 40.0
	name_label.offset_top = 12.0
	name_label.offset_right = 70.0
	name_label.offset_bottom = 28.0
	var clear_font = ResourceLoader.load("res://Fonts/ClearFont.ttf")
	name_label.add_theme_font_override("font", clear_font)
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Amount label (fixed position)
	var amount_label = Label.new()
	amount_label.text = "x" + str(amount)
	amount_label.offset_left = 120.0
	amount_label.offset_top = 12.0
	amount_label.offset_right = 138.0
	amount_label.offset_bottom = 28.0
	amount_label.add_theme_font_override("font", clear_font)
	amount_label.add_theme_font_size_override("font_size", 16)
	amount_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Add tooltip on mouse hover
	bg_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	bg_panel.mouse_entered.connect(func():
		_show_resource_tooltip(resource_type)
	)
	bg_panel.mouse_exited.connect(func():
		TooltipManager.hide()
	)
	
	# Store metadata for drag operations
	bg_panel.set_meta("resource_type", resource_type)
	bg_panel.set_meta("resource_amount", amount)
	bg_panel.set_meta("icon_ref", icon_texture)
	
	# Add drag listener
	var res_type = resource_type
	var res_amount = amount
	var panel_ref = bg_panel
	bg_panel.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_on_resource_panel_pressed(res_type, res_amount, panel_ref)
	)
	
	bg_panel.add_child(icon_texture)
	bg_panel.add_child(name_label)
	bg_panel.add_child(amount_label)
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
	
	# Store reference to unit on the panel for drag detection
	bg_panel.set_meta("unit_ref", unit)
	
	# Enable mouse input for drag detection
	bg_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Create lambda for input handling that captures unit reference
	var unit_ref = unit
	var panel_ref = bg_panel
	bg_panel.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if not unit_ref.is_locked:  # Only allow drag if not locked
				_on_unit_panel_pressed(unit_ref, panel_ref)
	)
	
	# Add tooltip on mouse hover
	bg_panel.mouse_entered.connect(func():
		_show_unit_tooltip(unit_ref)
	)
	bg_panel.mouse_exited.connect(func():
		TooltipManager.hide()
	)
	
	# Unit icon (32x32, fixed position)
	var icon_texture = TextureRect.new()
	icon_texture.texture = ResourceLoader.load(icon_path)
	icon_texture.offset_left = 4.0
	icon_texture.offset_top = 4.0
	icon_texture.offset_right = 36.0
	icon_texture.offset_bottom = 36.0
	icon_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Store icon reference for drag operations
	bg_panel.set_meta("icon_ref", icon_texture)
	
	# Unit name label (fixed position)
	var name_label = Label.new()
	name_label.offset_left = 40.0
	name_label.offset_top = 12.0
	name_label.offset_right = 138.0
	name_label.offset_bottom = 28.0
	var clear_font = ResourceLoader.load("res://Fonts/ClearFont.ttf")
	name_label.add_theme_font_override("font", clear_font)
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	if unit.is_locked and unit.unit_state == Unit.UnitState.MOVING:
		# Hide icon, show "Moving" overlay
		icon_texture.visible = false
		name_label.text = "Moving (%d)" % unit.movement_time_remaining
		name_label.add_theme_color_override("font_color", Color.WHITE)
		
		# Add semi-transparent background
		var overlay = ColorRect.new()
		overlay.color = Color(0, 0, 0, 0.5)
		overlay.anchor_left = 0
		overlay.anchor_top = 0
		overlay.anchor_right = 1
		overlay.anchor_bottom = 1
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bg_panel.add_child(overlay)
	else:
		name_label.text = unit.unit_name
	
	bg_panel.add_child(icon_texture)
	bg_panel.add_child(name_label)
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
	
	# Enemy unit icon (32x32, fixed position)
	var icon_texture = TextureRect.new()
	icon_texture.texture = ResourceLoader.load(icon_path)
	icon_texture.offset_left = 4.0
	icon_texture.offset_top = 4.0
	icon_texture.offset_right = 36.0
	icon_texture.offset_bottom = 36.0
	icon_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Enemy unit name label (fixed position)
	var name_label = Label.new()
	name_label.text = enemy_unit.unit_name
	name_label.offset_left = 40.0
	name_label.offset_top = 12.0
	name_label.offset_right = 138.0
	name_label.offset_bottom = 28.0
	var clear_font = ResourceLoader.load("res://Fonts/ClearFont.ttf")
	name_label.add_theme_font_override("font", clear_font)
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Add tooltip on mouse hover
	var enemy_unit_ref = enemy_unit
	bg_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	bg_panel.mouse_entered.connect(func():
		_show_enemy_tooltip(enemy_unit_ref)
	)
	bg_panel.mouse_exited.connect(func():
		TooltipManager.hide()
	)
	
	bg_panel.add_child(icon_texture)
	bg_panel.add_child(name_label)
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
	locked_node.add_child(unit)
	unit.assign_to_node(locked_node)
	locked_node.population -= 25
	locked_node.resources["population"] -= 25  # Also update resources dict
	MessageLog.add_message("Recruited %s at %s" % [unit.unit_name, locked_node.location_name], "success")
	
	# Refresh display
	show_node_info(locked_node)

func show_recruitment_failed_tooltip(message: String) -> void:
	"""Show recruitment failure in the message log."""
	MessageLog.add_message(message, "error")

func refresh_displayed_node_info() -> void:
	"""Refresh the currently displayed node info (called after auto phase ends)
	This ensures that all resource/population changes are reflected in the UI"""
	if locked_node and info_panel.visible:
		show_node_info(locked_node)

# Drag-and-drop system implementation (GDD 5.2.1)
func _on_unit_panel_pressed(unit: Unit, panel: Panel) -> void:
	"""Handle unit panel mouse press - initiate drag if unit is not locked"""
	# Don't allow dragging if unit is already moving/locked
	if unit.is_locked:
		return
	
	# Use cached GameMap reference
	if not game_map:
		return
	
	dragging_unit = unit
	drag_start_position = get_viewport().get_mouse_position()
	is_dragging = true
	unit_panel_container = panel
	
	# Get the original icon from the panel
	original_icon = panel.get_meta("icon_ref") if panel.has_meta("icon_ref") else null
	
	# Hide the original icon
	if original_icon:
		original_icon.visible = false
	
	# Create a dragging icon that follows the mouse
	if original_icon and original_icon.texture:
		dragging_icon = TextureRect.new()
		dragging_icon.texture = original_icon.texture
		dragging_icon.custom_minimum_size = Vector2(32, 32)
		dragging_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		dragging_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dragging_icon.z_index = 1000  # Ensure it's on top
		dragging_icon.modulate = Color(1, 1, 1, 0.5)  # Semi-transparent (50% opacity)
		
		# Add to UI layer so it appears above everything
		var ui_layer = get_node("../../UILayer")
		ui_layer.add_child(dragging_icon)
		
		# Update icon position to center it on mouse (will be updated in _process)
		_update_dragging_icon_position()
	
	# Calculate valid drop targets (all nodes except current node)
	valid_drop_targets.clear()
	if unit.current_node:
		# print("\n=== DEBUG: Calculating drop targets ===")
		# print("Unit %s at node: %s (camera: %s)" % [
		# 	unit.unit_name, unit.current_node.location_name,
		# 	game_map.node_camera_map.get(unit.current_node.node_id, "unknown")
		# ])
		# print("DEBUG: map.all_nodes size: %d" % game_map.all_nodes.size())
		
		# All nodes are draggable targets except the current node
		for node in game_map.all_nodes:
			if node != unit.current_node:
				valid_drop_targets.append(node)
				var movement_time = game_map.get_movement_time_to_node(unit.current_node, node)
				# print("  ✓ Added %s: %d turns (camera: %s)" % [
				# 	node.location_name, movement_time,
				# 	game_map.node_camera_map.get(node.node_id, "unknown")
				# ])
		
		# print("DEBUG: Final valid_drop_targets count: %d" % valid_drop_targets.size())
		# print("===\n")
	
	# Debug output
	# print("Started dragging unit %s from %s. Valid targets: %d" % [unit.unit_name, unit.current_node.location_name, valid_drop_targets.size()])

func _process(_delta: float) -> void:
	"""Process drag operations (unit or resource)"""
	if not is_dragging:
		return
	
	# Check if mouse button is still held
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if dragging_resource != "":
			_complete_resource_drag()
		elif dragging_unit:
			_complete_drag()
		return
	
	# Check distance from start position to initiate visual feedback
	var current_pos = get_viewport().get_mouse_position()
	var distance = drag_start_position.distance_to(current_pos)
	
	if distance > 5:  # Minimum drag distance to show feedback
		if dragging_resource != "":
			_update_resource_dragging_icon_position()
		elif dragging_unit:
			_update_drag_visualization()

func _update_drag_visualization() -> void:
	"""Update visual feedback during drag"""
	# Update dragging icon position to follow mouse with center aligned
	_update_dragging_icon_position()

func _update_dragging_icon_position() -> void:
	"""Update the position of the dragging icon to follow the mouse with centered alignment"""
	if not dragging_icon:
		return
	
	var mouse_pos = get_viewport().get_mouse_position()
	# Center the icon on the mouse position using custom_minimum_size (32x32)
	var icon_size = dragging_icon.custom_minimum_size
	if icon_size == Vector2.ZERO:
		icon_size = Vector2(32, 32)
	dragging_icon.global_position = mouse_pos - icon_size / 2

func _complete_drag() -> void:
	"""Complete drag operation and attempt movement"""
	if not dragging_unit:
		is_dragging = false
		return
	
	# Drop targeting uses the same hovered node source that drives shader highlight.
	var target_node = _get_drop_target_from_hover()
	
	# print("\n=== DEBUG: Drag completion ===")
	# print("Unit: %s, Valid targets: %d" % [dragging_unit.unit_name, valid_drop_targets.size()])
	# print("Drop target source: hovered_node(shader)")
	# print("Hovered target: %s" % (target_node.location_name if target_node else "None"))
	# if target_node:
	# 	print("Target node found: %s (in valid targets: %s)" % [
	# 		target_node.location_name, 
	# 		target_node in valid_drop_targets
	# 	])
	# else:
	# 	print("No target node found")
	# print("===\n")
	
	var movement_successful = false
	
	if target_node and target_node in valid_drop_targets:
		# Valid drop target - start movement
		if dragging_unit.start_movement(target_node):
			movement_successful = true
			# Refresh UI to show "Moving" label
			refresh_displayed_node_info()
	
	# Remove dragging icon
	if dragging_icon:
		dragging_icon.queue_free()
		dragging_icon = null
	
	# Refresh UI to sync with unit state
	# This will properly display the unit panel based on whether movement succeeded
	refresh_displayed_node_info()
	
	# Clean up drag state
	dragging_unit = null
	is_dragging = false
	valid_drop_targets.clear()
	unit_panel_container = null
	original_icon = null

# ============ Resource Drag-and-Drop ============

func _on_resource_panel_pressed(resource_type: String, amount: int, panel: Panel) -> void:
	"""Initiate resource drag"""
	if not locked_node or amount <= 0:
		return
	
	dragging_resource = resource_type
	dragging_resource_amount = amount
	dragging_resource_panel = panel
	drag_start_position = get_viewport().get_mouse_position()
	is_dragging = true
	
	# Get icon and hide original
	original_resource_icon = panel.get_meta("icon_ref") if panel.has_meta("icon_ref") else null
	if original_resource_icon:
		original_resource_icon.visible = false
	
	# Create dragging icon
	if original_resource_icon and original_resource_icon.texture:
		dragging_resource_icon = TextureRect.new()
		dragging_resource_icon.texture = original_resource_icon.texture
		dragging_resource_icon.custom_minimum_size = Vector2(32, 32)
		dragging_resource_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		dragging_resource_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dragging_resource_icon.z_index = 1000
		dragging_resource_icon.modulate = Color(1, 1, 1, 0.5)
		
		var ui_layer = get_node("../../UILayer")
		ui_layer.add_child(dragging_resource_icon)
		_update_resource_dragging_icon_position()

func _update_resource_dragging_icon_position() -> void:
	"""Update resource dragging icon to follow mouse"""
	if not dragging_resource_icon:
		return
	
	var mouse_pos = get_viewport().get_mouse_position()
	var icon_size = dragging_resource_icon.custom_minimum_size
	if icon_size == Vector2.ZERO:
		icon_size = Vector2(32, 32)
	dragging_resource_icon.global_position = mouse_pos - icon_size / 2

func _complete_resource_drag() -> void:
	"""Complete resource drag - transfer or revert"""
	if dragging_resource == "":
		is_dragging = false
		return
	
	var transfer_success = false
	
	# Check if dropping on unit panel in same node
	var mouse_pos = get_viewport().get_mouse_position()
	var ui_layer = get_node("../../UILayer")
	var unit_panels = ui_layer.find_children("*", "Panel", false, false)
	
	# Find all unit panels in resources_vbox
	var all_panels = resources_vbox.get_children()
	var unit_rows: Array[Panel] = []
	
	for child in all_panels:
		if child is Panel and child.has_meta("unit_ref"):
			unit_rows.append(child)
	
	# Check if mouse is over any unit panel
	for unit_panel in unit_rows:
		var panel_rect = unit_panel.get_global_rect()
		if panel_rect.has_point(mouse_pos):
			# Try to transfer resource to unit
			var unit = unit_panel.get_meta("unit_ref") as Unit
			if unit and unit.current_node == locked_node:
				# Special handling for llama (mount) - only 1 per unit
				if dragging_resource == "llama":
					if unit.has_mount:
						MessageLog.add_message("Unit already has a mount!", "error")
						transfer_success = false
					elif unit.add_to_inventory(dragging_resource, 1) > 0:
						locked_node.resources[dragging_resource] -= 1
						transfer_success = true
					break
				
				if unit.add_to_inventory(dragging_resource, 1) > 0:
					# Transfer successful
					locked_node.resources[dragging_resource] -= 1
					transfer_success = true
					break
	
	# Restore or remove icon
	if original_resource_icon:
		original_resource_icon.visible = true
	
	# Clean up dragging icon
	if dragging_resource_icon:
		dragging_resource_icon.queue_free()
		dragging_resource_icon = null
	
	# Refresh UI
	if transfer_success or dragging_resource_amount <= 1:
		# Resource gone - remove panel
		refresh_displayed_node_info()
	else:
		# Refresh to update amount
		refresh_displayed_node_info()
	
	# Clean up drag state
	dragging_resource = ""
	dragging_resource_amount = 0
	dragging_resource_panel = null
	original_resource_icon = null
	is_dragging = false

# ============ Unit Tooltip Handler ============

func _show_unit_tooltip(unit: Unit) -> void:
	"""Display tooltip with unit stats"""
	var unit_type_names = {
		"rebel_army": "Rebel Army",
		"female_corps": "Female Corps",
		"enemy": "Enemy"
	}
	var display_type = unit_type_names.get(unit.unit_type, unit.unit_type)
	var tooltip_text = "%s - %s\n" % [unit.unit_name, display_type]
	tooltip_text += "\n"
	tooltip_text += "Health: %d/%d\n" % [unit.current_health, unit.max_health]
	tooltip_text += "Satiety: %d/%d\n" % [unit.current_satiety, unit.max_satiety]
	tooltip_text += "Attack: %d\n" % unit.get_current_attack_power()
	tooltip_text += "Speed: %.1fx" % unit.movement_speed_multiplier
	TooltipManager.show_unit_inventory(tooltip_text, unit.inventory, unit.INVENTORY_CAPACITY, unit.has_mount, 0.1)

func _show_resource_tooltip(resource_type: String) -> void:
	"""Display tooltip with resource description"""
	var resource_descriptions = {
		"population": "Population - Recruit units\nwith 25 population per unit",
		"potato": "Potato\nRestore satiety: +50",
		"llama": "Llama\nTransport speed: x2.0",
		"corn": "Corn\nRestore satiety: +30\nCombat power: x1.2",
		"quinoa": "Quinoa\nRestore satiety: +20\nHeal: +20\nMove speed: x1.2 (3 turns)",
		"coca": "Coca\nHeal unit: +50"
	}
	var description = resource_descriptions.get(resource_type, resource_type)
	TooltipManager.show_text(description, 0.1)

func _show_altitude_tooltip(altitude: String) -> void:
	"""Display tooltip for altitude icon"""
	var altitude_text = ""
	match altitude:
		"high":
			altitude_text = "High"
		"middle", "medium":
			altitude_text = "Middle"
		"low":
			altitude_text = "Low"
		_:
			altitude_text = altitude
	
	if icon_tooltip_panel:
		icon_tooltip_panel.show_text(altitude_text)

func _show_resource_name_tooltip(resource_type: String) -> void:
	var resource_names = {
		"potato": "Potato",
		"llama": "Llama",
		"corn": "Corn",
		"quinoa": "Quinoa",
		"coca": "Coca"
	}
	var name = resource_names.get(resource_type, resource_type)
	if icon_tooltip_panel:
		icon_tooltip_panel.show_text(name)

func _show_enemy_tooltip(enemy_unit: EnemyUnit) -> void:
	"""Display tooltip with enemy unit stats"""
	var tooltip_text = "%s\n" % enemy_unit.unit_name
	tooltip_text += "\n"
	tooltip_text += "Health: %d/%d\n" % [enemy_unit.current_health, enemy_unit.max_health]
	tooltip_text += "Attack: %d" % enemy_unit.get_current_attack_power()
	TooltipManager.show_text(tooltip_text, 0.1)

# ============ Tooltip System Initialization ============

func _initialize_tooltip_system() -> void:
	"""Initialize tooltip system"""
	if TooltipManager._instance != null:
		return
	
	# Get TooltipManager from scene
	var tooltip_manager = get_tree().root.get_node_or_null("Main/TooltipManager")
	if not tooltip_manager:
		push_error("TooltipManager not found in scene!")
		return
	
	TooltipManager._instance = tooltip_manager
	tooltip_manager._enter_tree()
	
	await get_tree().process_frame
	
	if not tooltip_manager.is_node_ready():
		tooltip_manager._ready()

func _get_drop_target_from_hover() -> VillageNode:
	"""Return current drag target using GameMap hover state (same source as shader highlight)."""
	if not game_map or not game_map is GameMap:
		return null

	return game_map.hovered_node
