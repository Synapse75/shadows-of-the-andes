extends Camera2D

# 参考
var map_system: Node = null

# 切换设置
@export var transition_duration: float = 1.0  # 1秒切换
@export var use_fade_effect: bool = true

# 动画状态
var is_transitioning: bool = false
var target_position: Vector2 = Vector2.ZERO
var transition_progress: float = 0.0
var fade_tween: Tween = null

# 黑屏overlay
var fade_overlay: CanvasLayer = null
var fade_rect: ColorRect = null

func _ready():
	# 获取MapSystem引用
	map_system = get_tree().root.get_node("Main/Systems/MapSystem")
	
	# 初始化相机
	make_current()
	zoom = Vector2.ONE * 4.0
	
	# 创建淡出/淡入效果层
	if use_fade_effect:
		_setup_fade_layer()
	
	# 连接地图切换信号
	if map_system:
		map_system.map_changed.connect(_on_map_changed)

func _setup_fade_layer():
	fade_overlay = CanvasLayer.new()
	fade_overlay.layer = 100  # 最顶层
	add_child(fade_overlay)
	
	fade_rect = ColorRect.new()
	fade_rect.color = Color.BLACK
	fade_rect.anchor_left = 0
	fade_rect.anchor_top = 0
	fade_rect.anchor_right = 1
	fade_rect.anchor_bottom = 1
	fade_rect.modulate.a = 0.0  # 初始透明
	fade_overlay.add_child(fade_rect)

func _on_map_changed(map_id: String):
	if not map_system:
		return
	
	var target_map = map_system.get_map_view(map_id)
	if target_map:
		target_position = target_map.camera_position
		_start_transition()

func _start_transition():
	if is_transitioning:
		return
	
	is_transitioning = true
	transition_progress = 0.0
	
	if use_fade_effect and fade_rect:
		# 淡出 -> 移动相机 -> 淡入
		_transition_with_fade()
	else:
		# 直接平滑移动
		_transition_smooth()

func _transition_with_fade():
	# 保存起始位置
	var start_position = global_position
	
	# 淡出（0.3秒）
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(fade_rect, "modulate:a", 1.0, transition_duration * 0.3)
	
	# 在黑屏中移动相机（0.4秒）
	await tween.finished
	global_position = target_position
	
	# 淡入（0.3秒）
	tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(fade_rect, "modulate:a", 0.0, transition_duration * 0.3)
	
	await tween.finished
	is_transitioning = false

func _transition_smooth():
	# 使用Tween平滑移动相机（没有黑屏）
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "global_position", target_position, transition_duration)
	
	await tween.finished
	is_transitioning = false

# 禁用输入处理（因为使用UI按钮）
unc _input(event: InputEvent):
	pass
