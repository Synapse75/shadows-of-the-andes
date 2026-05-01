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
var cached_tree  # Cache tree ref since get_tree() may return null during manual init

func _ready() -> void:
	# Get TooltipPanel from scene (added to UILayer in main.tscn)
	tooltip_panel = get_tree().root.get_node_or_null("Main/UILayer/TooltipPanel")
	if not tooltip_panel:
		push_error("TooltipPanel not found in scene!")
		return
	
	tooltip_registry = TooltipRegistry.new()
	cached_tree = get_tree()

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
	
	# Clear previous timer
	if current_timer:
		current_timer.queue_free()
	
	current_timer = Timer.new()
	current_timer.wait_time = delay
	current_timer.one_shot = true
	current_timer.timeout.connect(func():
		var text = tooltip_registry.get_tooltip(category, element_name)
		tooltip_panel.show_tooltip(text)
	)
	# Defer add_child so Timer is in tree when start() called
	call_deferred("add_child", current_timer)
	call_deferred("_start_current_timer")

func _start_current_timer():
	"""Start timer after deferred add_child ensures it's in tree"""
	if current_timer and not current_timer.is_stopped():
		return
	if current_timer:
		print("[_start_current_timer] is_inside_tree=%s" % current_timer.is_inside_tree())
		current_timer.start()


func request_tooltip_with_text(text: String, delay: float = 0.3) -> void:
	last_element_id = ""
	
	# Clear previous timer
	if current_timer:
		current_timer.queue_free()
	
	current_timer = Timer.new()
	current_timer.wait_time = delay
	current_timer.one_shot = true
	current_timer.timeout.connect(func():
		print("[Timer.timeout] FIRED!")
		if tooltip_panel:
			tooltip_panel.show_tooltip(text)
	)
	# Add Timer to root directly, not to self
	if cached_tree and cached_tree.root:
		cached_tree.root.add_child(current_timer)
	else:
		add_child(current_timer)
	current_timer.start()
	print("[request_tooltip_with_text] Timer started, is_inside_tree=%s" % current_timer.is_inside_tree())

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
	if _instance == null:
		_instance = self
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
	if _instance:
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
