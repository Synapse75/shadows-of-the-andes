extends Node
class_name TooltipManager

"""
Global Tooltip Manager
Manages TooltipPanel display/hide using TooltipRegistry for text retrieval
"""

var tooltip_panel: TooltipPanel
var tooltip_registry  # TooltipRegistry - type hint removed to avoid parser errors
var current_timer: Timer
var last_element_id: String = ""  # Track last hovered element

func _ready() -> void:
	print("[TooltipManager._ready] called, _instance = %s" % _instance)
	# Create tooltip panel
	tooltip_panel = TooltipPanel.new()
	# caveman: 延迟挂载 tooltip_panel，确保 get_tree() 可用
	call_deferred("_add_tooltip_panel_to_ui")

func _add_tooltip_panel_to_ui():
	var tree = get_tree()
	var ui_layer = null
	if tree == null or tree.root == null:
		add_child(tooltip_panel)
		return
	if tree.root.has_node("UILayer"):
		ui_layer = tree.root.get_node("UILayer")
		ui_layer.add_child(tooltip_panel)
	elif tree.root.has_node("Main/UILayer"):
		ui_layer = tree.root.get_node("Main/UILayer")
		ui_layer.add_child(tooltip_panel)
	else:
		add_child(tooltip_panel)
	
	# Create registry instance
	tooltip_registry = TooltipRegistry.new()
	print("[TooltipManager._ready] tooltip_registry created, _instance = %s" % _instance)

func request_tooltip(category: String, element_name: String, delay: float = 0.3) -> void:
	"""
	Request to show tooltip
	Args:
		category: Tooltip category (e.g., "ResourcePanel", "Buttons")
		element_name: Element name (e.g., "potato_icon", "recruit_button")
		delay: Display delay in seconds
	"""
	var element_id = "%s.%s" % [category, element_name]
	
	# Skip if hovering the same element
	if element_id == last_element_id:
		return
	
	last_element_id = element_id
	
	# 清除之前的计时器
	if current_timer:
		current_timer.queue_free()
	
	current_timer = Timer.new()
	add_child(current_timer)
	current_timer.wait_time = delay
	current_timer.one_shot = true
	current_timer.timeout.connect(func():
		var text = tooltip_registry.get_tooltip(category, element_name)
		tooltip_panel.show_tooltip(text)
	)
	current_timer.start()

func request_tooltip_with_text(text: String, delay: float = 0.3) -> void:
	"""
	Display tooltip with custom text (bypassing registry)
	Args:
		text: Tooltip text
		delay: Display delay in seconds
	"""
	print("[request_tooltip_with_text] called with delay=%.1f" % delay)
	print("[request_tooltip_with_text] tooltip_panel = %s" % tooltip_panel)
	last_element_id = ""
	
	# Clear previous timer
	if current_timer:
		current_timer.queue_free()
	
	current_timer = Timer.new()
	add_child(current_timer)
	current_timer.wait_time = delay
	current_timer.one_shot = true
	print("[request_tooltip_with_text] Timer created, wait_time = %.1f" % delay)
	current_timer.timeout.connect(func():
		print("[request_tooltip_with_text] Timer timeout! Calling tooltip_panel.show_tooltip")
		tooltip_panel.show_tooltip(text)
	)
	current_timer.start()
	print("[request_tooltip_with_text] Timer started")

func hide_tooltip() -> void:
	"""Hide tooltip"""
	last_element_id = ""
	
	if current_timer:
		current_timer.queue_free()
		current_timer = null
	tooltip_panel.hide_tooltip()

func hide_tooltip_immediately() -> void:
	"""Hide tooltip immediately (no animation)"""
	last_element_id = ""
	
	if current_timer:
		current_timer.queue_free()
		current_timer = null
	tooltip_panel.hide_immediately()

# ============ Static singleton interface ============

static var _instance: TooltipManager

func _enter_tree() -> void:
	print("[TooltipManager._enter_tree] called")
	# This is now called manually from UIManager, so just verify
	if _instance == null:
		print("[TooltipManager._enter_tree] WARNING: _instance is null, this means UIManager didn't set it")
	else:
		print("[TooltipManager._enter_tree] OK: _instance is already set")
		# Ensure singleton survives scene changes
		set_meta("singleton", true)

static func get_instance() -> TooltipManager:
	"""Get singleton instance"""
	if not _instance:
		push_error("TooltipManager not initialized! Make sure it's added to the scene.")
	return _instance

# Convenient static methods
static func show(category: String, element_name: String, delay: float = 0.3) -> void:
	"""Quickly display tooltip"""
	if _instance:
		_instance.request_tooltip(category, element_name, delay)
	else:
		push_error("TooltipManager not initialized!")

static func show_text(text: String, delay: float = 0.3) -> void:
	"""Quickly display custom text tooltip"""
	print("[TooltipManager.show_text STATIC] called with delay=%.1f" % delay)
	print("[TooltipManager.show_text STATIC] _instance = %s" % _instance)
	if _instance:
		print("[TooltipManager.show_text STATIC] Calling _instance.request_tooltip_with_text")
		_instance.request_tooltip_with_text(text, delay)
	else:
		push_error("TooltipManager not initialized!")

static func hide() -> void:
	"""Quickly hide tooltip"""
	if _instance:
		_instance.hide_tooltip()
	else:
		push_error("TooltipManager not initialized!")

static func get_registry():
	"""Get tooltip registry"""
	if _instance:
		return _instance.tooltip_registry
	return null
