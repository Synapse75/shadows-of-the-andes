extends CanvasLayer

# 全局黑幕，跨场景使用
var overlay: ColorRect
var tween: Tween

func _ready() -> void:
	# 创建黑幕层
	overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.anchor_left = 0.0
	overlay.anchor_top = 0.0
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE  # 黑幕不拦截点击
	add_child(overlay)
	overlay.z_index = 1000  # 确保在最上层

func transition_to_story() -> void:
	"""从TitleScreen过渡到StoryTransition"""
	# 淡入黑幕
	await _fade_to_black(1.0)
	# 切换场景到StoryTransition
	get_tree().change_scene_to_file("res://Scenes/StoryTransition.tscn")

func transition_to_main() -> void:
	"""从StoryTransition过渡到Main"""
	# 先开始淡出，再立刻切换场景，让main在变亮的同时出现
	_fade_from_black(1.0)
	get_tree().change_scene_to_file("res://Scenes/main.tscn")

func _fade_to_black(duration: float) -> void:
	"""淡入黑幕"""
	if tween:
		tween.kill()
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP  # 启用点击吸收
	tween = create_tween()
	tween.tween_property(overlay, "color", Color(0, 0, 0, 1), duration)
	await tween.finished

func _fade_from_black(duration: float) -> void:
	"""淡出黑幕"""
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(overlay, "color", Color(0, 0, 0, 0), duration)
	await tween.finished
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE  # 禁用点击吸收
