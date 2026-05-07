extends Panel
#class_name IconTooltipPanel

var tween: Tween
var label: Label

const LABEL_MAX_WIDTH = 100
const OFFSET_FROM_MOUSE = Vector2(0, -16)

var clear_font: Font

func _ready() -> void:
	z_index = 999
	custom_minimum_size = Vector2(120, 24)
	
	# 透明背景
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.set_corner_radius_all(4)
	add_theme_stylebox_override("panel", style)
	
	label = get_node_or_null("Label")
	if label == null:
		label = Label.new()
		label.name = "Label"
		label.offset_left = 8
		label.offset_top = 4
		label.offset_right = 112
		label.offset_bottom = 20
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.add_theme_font_size_override("font_size", 16)
		add_child(label)
	
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _init_font() -> void:
	if clear_font == null:
		clear_font = preload("res://Fonts/ClearFont.ttf")
	if clear_font:
		label.add_theme_font_override("font", clear_font)

func _process(_delta: float) -> void:
	if visible:
		_update_position_to_mouse()

func _update_position_to_mouse() -> void:
	var mouse_pos = get_global_mouse_position()
	var panel_size = size
	var screen_size = get_viewport_rect().size
	
	var final_position = mouse_pos + OFFSET_FROM_MOUSE
	
	if final_position.x + panel_size.x > screen_size.x:
		final_position.x = mouse_pos.x - panel_size.x - OFFSET_FROM_MOUSE.x
	if final_position.y + panel_size.y > screen_size.y:
		final_position.y = mouse_pos.y - panel_size.y - OFFSET_FROM_MOUSE.y
	
	global_position = final_position

func show_text(text: String) -> void:
	if tween:
		tween.kill()
	
	_init_font()
	label.text = text
	
	_update_position_to_mouse()
	show()

func hide_text() -> void:
	if tween:
		tween.kill()
	hide()
