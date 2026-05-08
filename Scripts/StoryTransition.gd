extends Control

var story_texts: Array[String] = []
var current_text_index: int = 0
var label: Label
var is_transitioning: bool = false  # 防止过渡中继续点击
const TEXT_FADE_OUT_DURATION: float = 0.2
const TEXT_FADE_IN_DURATION: float = 0.2
const TEXT_SWITCH_PAUSE_DURATION: float = 0.1

func _ready() -> void:
	# print("DEBUG: StoryTransition._ready() 开始")
	# 获取Label节点
	label = $StoryLayer/Label
	label.modulate.a = 0.0
	# print("DEBUG: Label节点: ", label)
	
	# 从文件读取故事
	_load_story_from_file()
	
	# print("DEBUG: 准备处理输入事件")
	
	# 显示第一行文字并淡入
	_show_current_text()
	_fade_in_current_text()
	# print("DEBUG: StoryTransition._ready() 完成")
	
	# 播放背景音乐
	get_tree().root.get_node("AudioManager").play_music("hidden")

func _load_story_from_file() -> void:
	"""从story.txt文件读取故事内容"""
	var file = FileAccess.open("res://Scenes/story.txt", FileAccess.READ)
	if file == null:
		push_error("无法打开story.txt文件")
		story_texts = ["错误：无法加载故事文件"]
		# print("DEBUG: 文件打开失败")
		return
	
	var content = file.get_as_text()
	# print("DEBUG: 文件内容长度: ", content.length())
	# print("DEBUG: 文件内容: ", content)
	# 按换行符分割内容，去掉空行
	var split_result = content.split("\n", false)
	# print("DEBUG: 分割后数量: ", split_result.size())
	story_texts.clear()
	for text in split_result:
		story_texts.append(text)
		# print("DEBUG: 添加文本: ", text)
	# print("DEBUG: story_texts总数: ", story_texts.size())

func _input(event: InputEvent) -> void:
	"""捕获全局输入事件"""
	if event is InputEventMouseButton and event.pressed and not is_transitioning:
		# print("DEBUG: _input()捕获到点击事件, 当前索引: ", current_text_index)
		_next_text()
		if get_viewport() != null:
			get_viewport().set_input_as_handled()

func _show_current_text() -> void:
	# print("DEBUG: 显示文字索引: ", current_text_index, " / ", story_texts.size())
	if current_text_index < story_texts.size():
		label.text = story_texts[current_text_index]
		# print("DEBUG: 设置Label文字: ", label.text)
	else:
		# 所有文字显示完毕，开始淡出
		# print("DEBUG: 故事完成，准备过渡")
		_finish_story()

func _next_text() -> void:
	is_transitioning = true
	
	# 先把当前文本淡出，再切换文字并淡入。
	var fade_out_tween = create_tween()
	fade_out_tween.tween_property(label, "modulate:a", 0.0, TEXT_FADE_OUT_DURATION)
	await fade_out_tween.finished
	await get_tree().create_timer(TEXT_SWITCH_PAUSE_DURATION).timeout

	current_text_index += 1
	if current_text_index >= story_texts.size():
		_finish_story()
		return

	label.text = story_texts[current_text_index]
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

func _finish_story() -> void:
	"""故事讲完，触发过渡到Main"""
	# print("DEBUG: _finish_story() 开始")
	is_transitioning = true
	# 清空文字，准备淡出
	label.text = ""
	# 调用TransitionManager进行过渡
	TransitionManager.transition_to_main()
	# print("DEBUG: _finish_story() 完成")
