extends Node
class_name CameraUIController

# UI 箭头按钮引用
var arrow_up: Button
var arrow_down: Button
var arrow_left: Button
var arrow_right: Button
var camera_manager: CameraManager

func _ready() -> void:
	# 获取摄像机管理器和UI按钮引用
	camera_manager = get_tree().root.get_node("Main/Camera2D")
	
	# 获取箭头按钮（根据实际场景树结构调整路径）
	arrow_up = get_parent().get_node_or_null("ArrowUp")
	arrow_down = get_parent().get_node_or_null("ArrowDown")
	arrow_left = get_parent().get_node_or_null("ArrowLeft")
	arrow_right = get_parent().get_node_or_null("ArrowRight")
	
	# 连接箭头按钮信号
	if arrow_up:
		arrow_up.pressed.connect(_on_arrow_up_pressed)
	if arrow_down:
		arrow_down.pressed.connect(_on_arrow_down_pressed)
	if arrow_left:
		arrow_left.pressed.connect(_on_arrow_left_pressed)
	if arrow_right:
		arrow_right.pressed.connect(_on_arrow_right_pressed)
	
	# 初始化箭头显示状态
	update_arrow_visibility()

func _process(_delta: float) -> void:
	"""每帧更新箭头的可见状态"""
	update_arrow_visibility()

func update_arrow_visibility() -> void:
	"""根据当前镜头更新箭头的显示/隐藏"""
	var connected = camera_manager.get_connected_cameras()
	
	# 根据镜头连接关系更新箭头显示
	if arrow_up:
		arrow_up.visible = "andahuaylillas" in connected
	if arrow_down:
		arrow_down.visible = "jungle" in connected or "marcapata" in connected
	if arrow_left:
		arrow_left.visible = "marcapata" in connected
	if arrow_right:
		arrow_right.visible = "tinta" in connected

func _on_arrow_up_pressed() -> void:
	"""向上箭头 - 通常连接到Andahuaylillas"""
	if camera_manager.can_view_camera("andahuaylillas"):
		camera_manager.set_camera_view("andahuaylillas")

func _on_arrow_down_pressed() -> void:
	"""向下箭头 - Jungle或Marcapata"""
	if camera_manager.can_view_camera("jungle"):
		camera_manager.set_camera_view("jungle")
	elif camera_manager.can_view_camera("marcapata"):
		camera_manager.set_camera_view("marcapata")

func _on_arrow_left_pressed() -> void:
	"""向左箭头 - Marcapata"""
	if camera_manager.can_view_camera("marcapata"):
		camera_manager.set_camera_view("marcapata")

func _on_arrow_right_pressed() -> void:
	"""向右箭头 - Tinta"""
	if camera_manager.can_view_camera("tinta"):
		camera_manager.set_camera_view("tinta")
