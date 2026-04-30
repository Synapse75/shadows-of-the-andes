extends Control
class_name TooltipPanel

# UI 组件
var panel_container: PanelContainer
var label: Label
var margin_container: MarginContainer

# 动画相关
var tween: Tween
var is_visible_tooltip: bool = false  # Track if tooltip should be following mouse

# 常量
const SHOW_DELAY = 0.3
const FADE_DURATION = 0.15
const PANEL_MARGIN = 10
const MAX_WIDTH = 250

func _ready() -> void:
	print("[TooltipPanel._ready] called")
	# 创建 MarginContainer
	margin_container = MarginContainer.new()
	margin_container.add_theme_constant_override("margin_left", 12)
	margin_container.add_theme_constant_override("margin_right", 12)
	margin_container.add_theme_constant_override("margin_top", 8)
	margin_container.add_theme_constant_override("margin_bottom", 8)
	add_child(margin_container)
	print("[TooltipPanel._ready] margin_container added")
	
	# 创建 PanelContainer
	panel_container = PanelContainer.new()
	panel_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin_container.add_child(panel_container)
	
	# 创建标签
	label = Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = ""
	label.custom_minimum_size = Vector2(MAX_WIDTH, 0)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	panel_container.add_child(label)
	
	# 设置 label 主题
	var theme = Theme.new()
	var font_size = 12
	theme.set_font_size("font_size", "Label", font_size)
	label.theme = theme
	
	# 初始隐藏
	hide()
	modulate.a = 0.0
	print("[TooltipPanel._ready] completed")

func _process(_delta: float) -> void:
	"""跟随鼠标移动"""
	if is_visible_tooltip and visible:
		_update_position_to_mouse()

func show_tooltip(text: String, position_override: Vector2 = Vector2.ZERO) -> void:
	"""
	显示提示框
	Args:
		text: 提示框中显示的文字
		position_override: 位置覆盖，如果为 Vector2.ZERO 则跟随鼠标
	"""
	print("[TooltipPanel.show_tooltip] called")
	print("[TooltipPanel.show_tooltip] self = %s" % self)
	print("[TooltipPanel.show_tooltip] label = %s" % label)
	if tween:
		tween.kill()
	print("[TooltipPanel.show_tooltip] tween killed")
	
	label.text = text
	print("[TooltipPanel.show_tooltip] Text set to label")
	
	# 等待下一帧让标签尺寸更新
	await get_tree().process_frame
	print("[TooltipPanel.show_tooltip] after process_frame, label.size=%s, self.size=%s" % [label.size, size])
	
	# 设置初始位置
	is_visible_tooltip = true
	_update_position_to_mouse()
	print("[TooltipPanel.show_tooltip] Position updated, calling show()")
	show()
	print("[TooltipPanel.show_tooltip] After show(), visible = %s" % visible)
	
	# 渐入效果
	tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, FADE_DURATION)
	print("[TooltipPanel.show_tooltip] Tween started")

func _update_position_to_mouse() -> void:
	"""
	更新位置到鼠标位置
	鼠标点击点（光标）和信息框的左下角重合
	"""
	print("[_update_position_to_mouse] called")
	if not visible:
		print("[_update_position_to_mouse] WARNING: not visible!")
		return
	
	var mouse_pos = get_global_mouse_position()
	var panel_size = size
	print("[_update_position_to_mouse] mouse_pos = %s, panel_size = %s" % [mouse_pos, panel_size])
	
	# 信息框的左下角与鼠标位置重合
	# 即：信息框左上角 = 鼠标位置 - (0, panel_height)
	var final_position = mouse_pos - Vector2(0, panel_size.y)
	
	# 边界检查 - 确保不超出屏幕
	var screen_size = get_viewport_rect().size
	print("[_update_position_to_mouse] screen_size = %s" % screen_size)
	
	# 右边界检查
	if final_position.x + panel_size.x > screen_size.x:
		final_position.x = screen_size.x - panel_size.x - PANEL_MARGIN
	
	# 左边界检查
	if final_position.x < 0:
		final_position.x = PANEL_MARGIN
	
	# 上边界检查
	if final_position.y < 0:
		final_position.y = PANEL_MARGIN
	
	# 下边界检查
	if final_position.y + panel_size.y > screen_size.y:
		final_position.y = screen_size.y - panel_size.y - PANEL_MARGIN
	
	global_position = final_position
	print("[_update_position_to_mouse] Final position: %s" % global_position)

func hide_tooltip() -> void:
	"""隐藏提示框（带渐出效果）"""
	is_visible_tooltip = false
	
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, FADE_DURATION)
	tween.tween_callback(func(): hide())

func hide_immediately() -> void:
	"""立即隐藏提示框（无动画）"""
	is_visible_tooltip = false
	
	if tween:
		tween.kill()
	modulate.a = 0.0
	hide()
