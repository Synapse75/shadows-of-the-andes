extends Camera2D
class_name CameraManager

# 固定镜头配置
var cameras: Dictionary = {
	"tinta": Vector2(732, 960),           # Tinta 为中心
	"andahuaylillas": Vector2(250, 200),  # Andahuaylillas 为中心
	"marcapata": Vector2(700, 250),       # Marcapata 为中心
	"jungle": Vector2(475, 500)           # Paucartambo 和 Pilcopata 的中点
}

# 镜头连接关系 - 每个镜头可以连接到哪些镜头
var connected_cameras: Dictionary = {
	"tinta": ["andahuaylillas"],
	"andahuaylillas": ["tinta", "marcapata", "jungle"],
	"marcapata": ["andahuaylillas"],
	"jungle": ["andahuaylillas"]
}

var current_camera: String = "tinta"

# 相机平滑过渡
var is_transitioning: bool = false
var transition_speed: float = 300.0  # 像素/秒

func _ready() -> void:
	# 初始化相机
	make_current()
	zoom = Vector2.ONE * 4.0
	
	# 设置初始镜头位置
	set_camera_view("tinta")
	
	# 启用输入
	set_process_input(true)

func _input(_event: InputEvent) -> void:
	"""处理鼠标输入: 拖动已禁用，仅通过箭头切换镜头"""
	# 拖动功能已禁用 - 镜头只能通过箭头按钮切换
	return

func set_camera_view(view_name: String) -> void:
	"""切换到指定镜头"""
	if view_name in cameras:
		current_camera = view_name
		global_position = cameras[view_name]
		print("切换镜头: %s 位置 %s" % [view_name, cameras[view_name]])
	else:
		print("镜头不存在: %s" % view_name)

func cycle_camera_next() -> void:
	"""循环切换到下一个镜头"""
	var view_names = cameras.keys()
	var current_index = view_names.find(current_camera)
	var next_index = (current_index + 1) % view_names.size()
	set_camera_view(view_names[next_index])

func cycle_camera_prev() -> void:
	"""循环切换到上一个镜头"""
	var view_names = cameras.keys()
	var current_index = view_names.find(current_camera)
	var prev_index = (current_index - 1 + view_names.size()) % view_names.size()
	set_camera_view(view_names[prev_index])

func get_connected_cameras() -> Array:
	"""获取当前镜头连接到的镜头列表"""
	if current_camera in connected_cameras:
		return connected_cameras[current_camera]
	return []

func can_view_camera(view_name: String) -> bool:
	"""检查是否可以从当前镜头切换到指定镜头"""
	var connected = get_connected_cameras()
	return view_name in connected
