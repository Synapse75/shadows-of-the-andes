extends Camera2D
class_name CameraManager

# 摄像机参数
@export var min_zoom: float = 0.5
@export var max_zoom: float = 8.0
@export var zoom_speed: float = 0.1
@export var drag_enabled: bool = true

# 内部状态
var is_dragging: bool = false
var camera_start_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	# 初始化相机
	make_current()
	zoom = Vector2.ONE * 4.0
	
	# 启用输入
	set_process_input(true)

func _input(event: InputEvent) -> void:
	"""处理鼠标输入：滚轮缩放和左键拖动"""
	
	# 滚轮缩放
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_in()
			get_tree().root.set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_out()
			get_tree().root.set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			# 检查是否点击了UI按钮 - 如果是则不处理拖动
			var screen_pos = event.position
			
			# NextTurnButton: 10, 360 - 200, 40
			var next_turn_rect = Rect2(Vector2(10, 360), Vector2(190, 40))
			if next_turn_rect.has_point(screen_pos):
				return  # Let button handle it
			
			# PauseButton: 1840, 10 - 70, 40
			var pause_btn_rect = Rect2(Vector2(1840, 10), Vector2(70, 40))
			if pause_btn_rect.has_point(screen_pos):
				return  # Let button handle it
			
			if event.pressed:
				_start_drag()
			else:
				_end_drag()
			get_tree().root.set_input_as_handled()
	
	# 左键拖动 - 使用 event.relative 获取屏幕坐标的相对移动
	elif event is InputEventMouseMotion and is_dragging:
		_update_drag(event)
		get_tree().root.set_input_as_handled()

func zoom_in() -> void:
	"""放大摄像机"""
	zoom = zoom + Vector2.ONE * zoom_speed
	zoom = zoom.clamp(Vector2.ONE * min_zoom, Vector2.ONE * max_zoom)
	print("缩放: %.1fx" % zoom.x)

func zoom_out() -> void:
	"""缩小摄像机"""
	zoom = zoom - Vector2.ONE * zoom_speed
	zoom = zoom.clamp(Vector2.ONE * min_zoom, Vector2.ONE * max_zoom)
	print("缩放: %.1fx" % zoom.x)

func _start_drag() -> void:
	"""开始拖动"""
	is_dragging = true
	camera_start_pos = global_position
	print("开始拖动")

func _end_drag() -> void:
	"""结束拖动"""
	is_dragging = false
	print("结束拖动")

func _update_drag(motion_event: InputEventMouseMotion) -> void:
	"""更新拖动位置
	
	鼠标在屏幕上移动时将该移动转换为世界坐标的摄像机移动
	同时更新UI层以跟随摄像机
	"""
	# 获取屏幕坐标的移动距离
	var screen_delta = motion_event.relative
	
	# 将屏幕坐标转换为世界坐标
	# 屏幕移动需要除以缩放倍数来得到世界空间的移动
	var world_delta = -screen_delta / zoom.x
	
	# 更新摄像机位置
	global_position = camera_start_pos + world_delta
	
	# 更新起始位置以支持连续拖动
	camera_start_pos = global_position
