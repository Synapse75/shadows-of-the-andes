extends Control
class_name PauseMenuController

var is_paused: bool = false
var pause_panel: Panel
var resume_button: Button
var settings_button: Button
var menu_button: Button
var quit_button: Button
var dark_overlay: ColorRect

signal game_paused
signal game_resumed

func _ready() -> void:
	# 获取对节点的引用 (使用相对路径，从脚本附加的节点开始)
	pause_panel = get_node_or_null("PausePanel")
	dark_overlay = get_node_or_null("DarkOverlay")
	
	# 如果找不到，尝试从父节点查找
	if not pause_panel:
		pause_panel = get_parent().get_node_or_null("PausePanel")
	if not dark_overlay:
		dark_overlay = get_parent().get_node_or_null("DarkOverlay")
	
	# 检查是否成功获取关键节点
	if not pause_panel:
		push_error("PauseMenuController: 无法找到 PausePanel 节点")
		return
	if not dark_overlay:
		push_error("PauseMenuController: 无法找到 DarkOverlay 节点")
		return
	
	resume_button = pause_panel.get_node_or_null("VBoxContainer/ResumeButton")
	settings_button = pause_panel.get_node_or_null("VBoxContainer/SettingsButton")
	menu_button = pause_panel.get_node_or_null("VBoxContainer/MenuButton")
	quit_button = pause_panel.get_node_or_null("VBoxContainer/QuitButton")
	
	# 检查按钮
	if not resume_button or not settings_button or not menu_button or not quit_button:
		push_error("PauseMenuController: 无法找到暂停菜单的所有按钮")
		return
	
	# 初始状态：隐藏暂停菜单
	pause_panel.visible = false
	dark_overlay.visible = false
	
	# 连接按钮信号
	resume_button.pressed.connect(_on_resume_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# 监听 ESC 键
	set_process_unhandled_input(true)

func _unhandled_input(event: InputEvent) -> void:
	"""处理 ESC 暂停/恢复"""
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if is_paused:
			resume_game()
		else:
			pause_game()
		get_tree().root.set_input_as_handled()

func pause_game() -> void:
	"""暂停游戏"""
	if not pause_panel or not dark_overlay:
		push_error("PauseMenuController: 暂停菜单未正确初始化")
		return
	
	is_paused = true
	get_tree().paused = true
	pause_panel.visible = true
	dark_overlay.visible = true
	game_paused.emit()
	print("游戏已暂停 (按 ESC 继续)")

func resume_game() -> void:
	"""恢复游戏"""
	if not pause_panel or not dark_overlay:
		push_error("PauseMenuController: 暂停菜单未正确初始化")
		return
	
	is_paused = false
	get_tree().paused = false
	pause_panel.visible = false
	dark_overlay.visible = false
	game_resumed.emit()
	print("游戏已恢复")

func _on_resume_pressed() -> void:
	"""恢复按钮"""
	if resume_button:
		resume_game()

func _on_settings_pressed() -> void:
	"""设置按钮 - TODO: 实现设置菜单"""
	if settings_button:
		print("设置菜单 (暂未实现)")
	# await show_settings_menu()

func _on_menu_pressed() -> void:
	"""返回菜单按钮"""
	if menu_button:
		get_tree().paused = false  # 恢复游戏时间流，才能切换场景
		if ResourceLoader.exists("res://Scenes/MainMenu.tscn"):
			get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
		else:
			print("错误: MainMenu.tscn 不存在")

func _on_quit_pressed() -> void:
	"""退出游戏"""
	if quit_button:
		get_tree().paused = false
		get_tree().quit()
