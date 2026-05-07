extends Control
class_name MessageLogUI

# Message Log UI Display with scrolling capability
# Displays messages in scrollable container at top-right of screen
# Supports only mouse wheel for scrolling, no scrollbar visible

@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var message_box: VBoxContainer = $ScrollContainer/VBoxContainer

var message_item_scene: PackedScene
var fade_timer: Timer
var fade_tween: Tween
var is_hovered: bool = false
const SCROLL_SPEED = 40
const FADE_DELAY_SECONDS = 3.0
const FADE_TARGET_ALPHA = 0.1
const FADE_TRANSITION_SECONDS = 0.5
const FADE_IN_TRANSITION_SECONDS = 0.2

func _process(_delta: float) -> void:
	# Use global coordinates (like wheel logic) for more reliable detection
	var global_mouse = get_global_mouse_position()
	var global_rect = get_global_rect()
	if global_rect.has_point(global_mouse):
		if not is_hovered:
			print("[MessageLogUI] Mouse in - entered")
			_on_mouse_entered()
	else:
		if is_hovered:
			print("[MessageLogUI] Mouse out - exited")
			_on_mouse_exited()

func _ready() -> void:
	# Create and configure fade timer first
	fade_timer = Timer.new()
	# Create and configure fade timer first
	fade_timer = Timer.new()
	fade_timer.one_shot = true
	fade_timer.wait_time = FADE_DELAY_SECONDS
	fade_timer.timeout.connect(_on_fade_delay_timeout)
	add_child(fade_timer)
	
	# Load message item scene
	message_item_scene = load("res://Scenes/UI/MessageItem.tscn")
	modulate.a = 1.0
	mouse_filter = Control.MOUSE_FILTER_PASS
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	print("[MessageLogUI] Setting mouse_filter to STOP on main control")
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Connect to global message log
	if MessageLog.message_added.is_connected(_on_message_added):
		MessageLog.message_added.disconnect(_on_message_added)
	MessageLog.message_added.connect(_on_message_added)
	
	if MessageLog.messages_cleared.is_connected(_on_messages_cleared):
		MessageLog.messages_cleared.disconnect(_on_messages_cleared)
	MessageLog.messages_cleared.connect(_on_messages_cleared)
	
	# Setup scroll container
	if scroll_container:
		var h_scroll = scroll_container.get_h_scroll_bar()
		var v_scroll = scroll_container.get_v_scroll_bar()
		
		if h_scroll:
			h_scroll.visible = false
			h_scroll.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		if v_scroll:
			v_scroll.visible = false
			v_scroll.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		# Allow mouse wheel input on the container itself
		scroll_container.mouse_filter = Control.MOUSE_FILTER_PASS
		# Forward mouse events from scroll container to parent
		scroll_container.mouse_entered.connect(_on_mouse_entered)
		scroll_container.mouse_exited.connect(_on_mouse_exited)
	
	# Setup message box
	if message_box:
		message_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# Ensure proper expansion
		message_box.size_flags_vertical = Control.SIZE_FILL
	
	set_process_input(true)

func _input(event: InputEvent) -> void:
	"""Handle mouse wheel scrolling for message history"""
	if not scroll_container or not scroll_container.visible:
		return
	
	if event is InputEventMouseButton:
		# Check if mouse is over the message log area
		var mouse_pos = get_local_mouse_position()
		if scroll_container.get_rect().has_point(mouse_pos):
			var v_scroll = scroll_container.get_v_scroll_bar()
			if v_scroll:
				if event.button_index == MOUSE_BUTTON_WHEEL_UP:
					v_scroll.value = max(0, v_scroll.value - SCROLL_SPEED)
					get_tree().root.set_input_as_handled()
				elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
					v_scroll.value = min(v_scroll.max_value, v_scroll.value + SCROLL_SPEED)
					get_tree().root.set_input_as_handled()

func _on_message_added(message: String, msg_type: String) -> void:
	"""Called when a new message is added to the log"""
	if not message_box or not message_item_scene:
		return
	
	# Create new message item from scene (avoid typed class reference to prevent parse errors)
	var new_item = message_item_scene.instantiate()
	message_box.add_child(new_item)
	new_item.set_message(message, msg_type)
	_show_full_and_restart_fade_timer()
	
	# Auto-scroll to bottom to show newest message
	await get_tree().process_frame
	scroll_to_bottom()

func _on_messages_cleared() -> void:
	"""Called when message history is cleared"""
	if not message_box:
		return
	
	for child in message_box.get_children():
		child.queue_free()

func scroll_to_bottom() -> void:
	"""Auto-scroll to show the latest message"""
	if not scroll_container:
		return
	
	var v_scroll = scroll_container.get_v_scroll_bar()
	if v_scroll:
		v_scroll.value = v_scroll.max_value

func _on_mouse_entered() -> void:
	print("[MessageLogUI] Mouse entered - resetting to full opacity")
	is_hovered = true
	fade_timer.stop()
	_fade_to(1.0, FADE_IN_TRANSITION_SECONDS)

func _on_mouse_exited() -> void:
	print("[MessageLogUI] Mouse exited - starting fade timer")
	is_hovered = false
	fade_timer.start()

func _on_fade_delay_timeout() -> void:
	# Only fade if mouse is NOT over the message log
	if not is_hovered:
		_fade_to(FADE_TARGET_ALPHA)

func _start_fade_timer() -> void:
	if not fade_timer:
		return

	fade_timer.stop()
	fade_timer.start()

func _show_full_and_restart_fade_timer() -> void:
	_show_full()
	_start_fade_timer()

func _show_full() -> void:
	_fade_to(1.0, FADE_IN_TRANSITION_SECONDS)

func _fade_to(target_alpha: float, duration: float = FADE_TRANSITION_SECONDS) -> void:
	if fade_tween:
		fade_tween.kill()
		fade_tween = null

	fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", target_alpha, duration)
