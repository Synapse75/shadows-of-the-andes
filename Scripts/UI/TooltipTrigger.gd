extends Node
class_name TooltipTrigger

"""
提示框触发器
将此节点作为Control节点的子节点，自动处理mouse_entered/mouse_exited信号
"""

@export var category: String = "ResourcePanel"  # 提示分类
@export var element_name: String = ""  # 元素名称
@export var custom_text: String = ""  # 自定义文本（优先级高于注册表）
@export var show_delay: float = 0.3  # 显示延迟

var target_control: Control

func _ready() -> void:
	# 获取父节点（应该是 Control）
	target_control = get_parent() as Control
	
	if not target_control:
		push_error("TooltipTrigger 必须是 Control 节点的子节点！")
		queue_free()
		return
	
	# 连接信号
	target_control.mouse_entered.connect(_on_mouse_entered)
	target_control.mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
	"""鼠标进入时显示提示框"""
	if custom_text:
		# 使用自定义文本
		TooltipManager.show_text(custom_text, show_delay)
	else:
		# 使用注册表中的文本
		TooltipManager.show(category, element_name, show_delay)

func _on_mouse_exited() -> void:
	"""鼠标离开时隐藏提示框"""
	TooltipManager.hide()

func set_tooltip_text(category_name: String, element_id: String) -> void:
	"""动态设置提示框内容"""
	category = category_name
	element_name = element_id
	custom_text = ""

func set_custom_tooltip(text: String) -> void:
	"""设置自定义提示文本"""
	custom_text = text
	element_name = ""
