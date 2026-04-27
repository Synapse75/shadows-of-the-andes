extends Node
class_name TooltipSystemExample

"""
提示框系统使用示例
展示如何为各个UI元素添加提示框
"""

# 示例 1：为按钮添加提示框（编程方式）
func example_add_tooltip_to_button(button: Button) -> void:
	"""为按钮添加提示框"""
	# 方式 A：使用 TooltipTrigger 组件
	var trigger = TooltipTrigger.new()
	trigger.category = "Buttons"
	trigger.element_name = "recruit_button"
	button.add_child(trigger)
	
	# 或者方式 B：手动连接信号
	# button.mouse_entered.connect(func():
	# 	TooltipManager.show("Buttons", "recruit_button")
	# )
	# button.mouse_exited.connect(func():
	# 	TooltipManager.hide()
	# )

# 示例 2：为资源图标添加提示框
func example_add_tooltip_to_resource_icon(icon: TextureRect, resource_type: String) -> void:
	"""为资源图标添加提示框"""
	var trigger = TooltipTrigger.new()
	trigger.category = "ResourcePanel"
	trigger.element_name = resource_type + "_icon"  # 如 "potato_icon", "corn_icon"
	icon.add_child(trigger)

# 示例 3：为标签添加动态提示框
func example_add_tooltip_with_dynamic_text(label: Label, dynamic_text: String) -> void:
	"""为标签添加动态提示框"""
	var trigger = TooltipTrigger.new()
	trigger.custom_text = dynamic_text  # 使用自定义文本而不是从注册表获取
	label.add_child(trigger)

# 示例 4：手动显示/隐藏提示框
func example_manual_tooltip_control() -> void:
	"""手动控制提示框显示/隐藏"""
	# 显示提示框
	TooltipManager.show("GameStatus", "hunger_status")
	
	# 或使用自定义文本
	TooltipManager.show_text("这是一个自定义的提示文本")
	
	# 隐藏提示框
	# TooltipManager.hide()

# 示例 5：动态修改提示文本
func example_modify_tooltip_dynamically() -> void:
	"""动态修改提示文本"""
	var registry = TooltipManager.get_registry()
	
	# 修改现有提示文本
	registry.set_tooltip("Buttons", "recruit_button", "新的招募按钮提示文本")
	
	# 获取并打印所有提示
	var items = registry.get_category_items("Buttons")
	for element_name in items:
		var text = items[element_name]
		print("按钮 %s: %s" % [element_name, text])

# 示例 6：为包含多个子元素的面板添加提示框
func example_add_tooltip_to_panel_elements(panel: Panel) -> void:
	"""为面板中的多个子元素添加提示框"""
	for child in panel.get_children():
		if child is TextureRect:
			# 假设这是资源图标
			var trigger = TooltipTrigger.new()
			trigger.category = "ResourcePanel"
			
			# 根据纹理路径判断资源类型
			if "potato" in child.texture.resource_path:
				trigger.element_name = "potato_icon"
			elif "corn" in child.texture.resource_path:
				trigger.element_name = "corn_icon"
			
			child.add_child(trigger)

# 示例 7：在 UIManager 中集成提示框
func example_integrate_with_uimanager() -> void:
	"""展示如何在 UIManager 中集成提示框"""
	# 这个函数应该在 UIManager._ready() 中调用
	
	# 示例：为招募按钮添加提示框
	# if recruit_button:
	# 	var trigger = TooltipTrigger.new()
	# 	trigger.category = "Buttons"
	# 	trigger.element_name = "recruit_button"
	# 	recruit_button.add_child(trigger)

# 示例 8：为自定义的游戏状态提示框
func example_game_state_tooltips() -> void:
	"""为游戏状态显示提示框"""
	# 当村庄饥饿时显示提示
	TooltipManager.show("GameStatus", "hunger_status")
	
	# 当人口低迷时显示提示
	TooltipManager.show("GameStatus", "population_low")

# 示例 9：调试 - 打印所有可用提示
func example_debug_print_all_tooltips() -> void:
	"""打印所有可用的提示文本"""
	var registry = TooltipManager.get_registry()
	
	print("\n========== 所有提示文本 ==========\n")
	
	var categories = registry.get_all_categories()
	for category in categories:
		var items = registry.get_category_items(category)
		print("[%s]" % category)
		for element_name in items:
			var text = items[element_name]
			# 用 " | " 替换换行符方便查看
			text = text.replace("\n", " | ")
			print("  - %s: %s" % [element_name, text])
		print()

# 示例 10：在 _process 中实时更新提示内容
func example_realtime_tooltip_update(village: VillageNode) -> void:
	"""根据村庄状态实时更新提示内容"""
	var registry = TooltipManager.get_registry()
	
	# 根据当前状态生成动态提示文本
	var tooltip_text = "%s\n" % village.location_name
	tooltip_text += "人口：%d/%d\n" % [village.population, village.max_population]
	tooltip_text += "饱腹：%s\n" % ("是" if village.hunger_status else "否")
	
	# 显示动态提示
	TooltipManager.show_text(tooltip_text, 0.2)

# ============ 快速参考 ============

"""
快速参考：常用调用方式

# 1. 显示预定义的提示框
TooltipManager.show("Buttons", "recruit_button")

# 2. 显示自定义文本提示框
TooltipManager.show_text("自定义提示文本\n第二行")

# 3. 隐藏提示框
TooltipManager.hide()

# 4. 获取提示注册表
var registry = TooltipManager.get_registry()

# 5. 获取某个分类的所有项
var items = registry.get_category_items("Buttons")

# 6. 修改提示文本
registry.set_tooltip("Buttons", "recruit_button", "新提示文本")

# 7. 打印所有提示（调试）
registry.print_all_tooltips()

# 8. 为 UI 元素添加提示框触发器
var trigger = TooltipTrigger.new()
trigger.category = "ResourcePanel"
trigger.element_name = "potato_icon"
my_button.add_child(trigger)
"""
