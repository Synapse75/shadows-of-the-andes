extends Node
class_name CameraArrowManager

# 镜头配置
var camera_manager: CameraManager
var arrow_buttons: Dictionary = {}
var current_active_arrows: Array[String] = []
var last_camera: String = ""

func _ready() -> void:
	# 获取摄像机管理器
	var main_node = get_parent()
	if not main_node:
		push_error("CameraArrowManager: 无法获取 Main 节点")
		return
	
	camera_manager = main_node.get_node("SubViewportContainer/SubViewport/Camera2D") as CameraManager
	if not camera_manager:
		push_error("CameraArrowManager: 无法获取 CameraManager")
		return
	
	# 记录初始镜头
	last_camera = camera_manager.current_camera
	
	# 收集所有箭头按钮
	_collect_arrows()
	
	# 初始化箭头显示
	update_arrows_display()

func _collect_arrows() -> void:
	"""收集UILayer中的所有箭头按钮"""
	var main_node = get_parent()
	if not main_node:
		push_error("CameraArrowManager: 无法获取 Main 节点")
		return
	
	var ui_layer = main_node.get_node_or_null("UILayer")
	if not ui_layer:
		push_error("CameraArrowManager: 无法获取 UILayer，尝试直接查找")
		# 尝试递归搜索 UILayer
		_find_ui_layer(main_node)
		return
	
	# 查找所有箭头按钮实例
	for child in ui_layer.get_children():
		if child.name.begins_with("Arrow"):
			var direction = child.name.to_lower().replace("arrow", "")
			arrow_buttons[direction] = child
			# 初始隐藏所有箭头
			if child:
				child.visible = false
			print("找到箭头: %s -> %s (类型: %s)" % [direction, child.name, child.get_class()])
	
	print("CameraArrowManager: 收集了 %d 个箭头" % arrow_buttons.size())

func _find_ui_layer(node: Node) -> void:
	"""递归搜索 UILayer 节点"""
	for child in node.get_children():
		if child.name == "UILayer":
			print("找到 UILayer")
			for arrow_child in child.get_children():
				if arrow_child.name.begins_with("Arrow"):
					var direction = arrow_child.name.to_lower().replace("arrow", "")
					arrow_buttons[direction] = arrow_child
					if arrow_child:
						arrow_child.visible = false
					print("找到箭头: %s -> %s" % [direction, arrow_child.name])
			return
		_find_ui_layer(child)

func _process(_delta: float) -> void:
	"""每帧更新箭头显示"""
	if not camera_manager:
		return
	
	# 仅在镜头改变时更新
	var current = camera_manager.current_camera
	if current != last_camera:
		print("CameraArrowManager: 镜头改变 %s -> %s" % [last_camera, current])
		last_camera = current
		update_arrows_display()

func update_arrows_display() -> void:
	"""根据当前镜头更新箭头的显示"""
	if arrow_buttons.is_empty():
		return
	
	var current_camera = camera_manager.current_camera
	print("CameraArrowManager.update_arrows_display: 更新箭头显示，当前镜头 %s" % current_camera)
	
	# 隐藏所有箭头
	for arrow in arrow_buttons.values():
		if arrow and is_instance_valid(arrow):
			arrow.visible = false
	
	# 根据当前镜头显示相应的箭头
	match current_camera:
		"tinta":
			# Tinta: 只显示向上箭头（连接到 Andahuaylillas）
			if "up" in arrow_buttons and arrow_buttons["up"]:
				arrow_buttons["up"].visible = true
				print("  → 显示 up 箭头")
		
		"andahuaylillas":
			# Andahuaylillas (中心): 显示上、右、下三个箭头
			# 上 → Jungle, 右 → Marcapata, 下 → Tinta
			if "up" in arrow_buttons and arrow_buttons["up"]:
				arrow_buttons["up"].visible = true
			if "right" in arrow_buttons and arrow_buttons["right"]:
				arrow_buttons["right"].visible = true
			if "down" in arrow_buttons and arrow_buttons["down"]:
				arrow_buttons["down"].visible = true
			print("  → 显示 up/right/down 箭头")
		
		"marcapata":
			# Marcapata: 显示返回箭头（向左）返回到 Andahuaylillas
			if "left" in arrow_buttons and arrow_buttons["left"]:
				arrow_buttons["left"].visible = true
				print("  → 显示 left 箭头")
		
		"jungle":
			# Jungle (Paucartambo/Pilcopata中点): 显示返回箭头（向下）返回到 Andahuaylillas
			if "down" in arrow_buttons and arrow_buttons["down"]:
				arrow_buttons["down"].visible = true
				print("  → 显示 down 箭头")
