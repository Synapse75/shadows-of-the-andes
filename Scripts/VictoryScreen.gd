extends Control

var victory_texts: Array[String] = []
var current_text_index: int = 0
var label: Label
var is_transitioning: bool = false
const TEXT_FADE_OUT_DURATION: float = 0.2
const TEXT_FADE_IN_DURATION: float = 0.2
const TEXT_SWITCH_PAUSE_DURATION: float = 0.1

func _ready() -> void:
	label = $VictoryLayer/Label
	label.modulate.a = 0.0
	
	# 从文件读取胜利文字
	_load_victory_from_file()
	
	# 显示第一行文字并淡入
	_show_current_text()
	_fade_in_current_text()
	
	# 播放背景音乐
	get_tree().root.get_node("AudioManager").play_music("hidden")

func _load_victory_from_file() -> void:
	"""从victory.txt文件读取胜利内容"""
	var file = FileAccess.open("res://Scenes/victory.txt", FileAccess.READ)
	if file == null:
		push_error("无法打开victory.txt文件")
		victory_texts = ["Victory! You have liberated all villages."]
		return
	
	var content = file.get_as_text()
	# 按换行符分割内容，去掉空行
	var split_result = content.split("\n", false)
	victory_texts.clear()
	for text in split_result:
		victory_texts.append(text)

func _input(event: InputEvent) -> void:
	"""捕获全局输入事件"""
	if event is InputEventMouseButton and event.pressed and not is_transitioning:
		_next_text()
		if get_viewport() != null:
			get_viewport().set_input_as_handled()

func _show_current_text() -> void:
	if current_text_index < victory_texts.size():
		label.text = victory_texts[current_text_index]
	else:
		# 所有文字显示完毕，准备返回主菜单
		_finish_victory()

func _next_text() -> void:
	is_transitioning = true
	
	# 先把当前文本淡出，再切换文字并淡入
	var fade_out_tween = create_tween()
	fade_out_tween.tween_property(label, "modulate:a", 0.0, TEXT_FADE_OUT_DURATION)
	await fade_out_tween.finished
	await get_tree().create_timer(TEXT_SWITCH_PAUSE_DURATION).timeout

	current_text_index += 1
	if current_text_index >= victory_texts.size():
		_finish_victory()
		return

	label.text = victory_texts[current_text_index]
	label.modulate.a = 0.0

	var fade_in_tween = create_tween()
	fade_in_tween.tween_property(label, "modulate:a", 1.0, TEXT_FADE_IN_DURATION)
	await fade_in_tween.finished

	is_transitioning = false

func _fade_in_current_text() -> void:
	is_transitioning = true
	label.modulate.a = 0.0
	var fade_in_tween = create_tween()
	fade_in_tween.tween_property(label, "modulate:a", 1.0, TEXT_FADE_IN_DURATION)
	await fade_in_tween.finished
	is_transitioning = false

func _finish_victory() -> void:
	"""胜利屏幕完成，返回主菜单"""
	await TransitionManager.transition_to_title()

