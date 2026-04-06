extends Button
class_name ArrowButton

@export var direction: String = "up"
var game_controller: GameController
var camera_manager: CameraManager

# 动画帧数据
var animation_frames: Array[AtlasTexture] = []
var current_frame: int = 0
var frame_timer: float = 0.0
var frame_duration: float = 0.5  # 2fps = 0.5秒/帧

func _ready() -> void:
	# 获取gambe controller引用
	game_controller = get_tree().root.get_node("Main") as GameController
	camera_manager = get_tree().root.get_node("Main/Camera2D") as CameraManager
	
	# 检查是否成功获取管理器
	if not camera_manager:
		push_error("ArrowButton[%s]: 无法获取 CameraManager" % direction)
	else:
		print("ArrowButton[%s]: 成功获取 CameraManager，当前镜头: %s" % [direction, camera_manager.current_camera])
	
	# 初始化动画帧
	_setup_animation_frames()
	
	# 连接信号
	pressed.connect(_on_pressed)
	print("ArrowButton[%s]: 按钮已创建，方向: %s" % [direction, direction])
	
	# 样式设置
	modulate = Color.WHITE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _setup_animation_frames() -> void:
	"""设置动画帧"""
	var arrow_texture = load("res://Sprites/arrow.png") as Texture2D
	if not arrow_texture:
		push_error("ArrowButton: 无法加载 arrow.png")
		return
	
	# 创建4个 AtlasTexture 帧 (8x8 像素，一行4个)
	for i in range(4):
		var atlas = AtlasTexture.new()
		atlas.atlas = arrow_texture
		atlas.region = Rect2(i * 8, 0, 8, 8)
		animation_frames.append(atlas)
	
	# 设置初始图标
	if animation_frames.size() > 0:
		icon = animation_frames[0]

func _process(delta: float) -> void:
	"""每帧更新动画"""
	if animation_frames.is_empty():
		return
	
	# 更新帧计时器
	frame_timer += delta
	
	# 检查是否需要切换帧
	if frame_timer >= frame_duration:
		frame_timer = 0.0
		current_frame = (current_frame + 1) % animation_frames.size()
		icon = animation_frames[current_frame]

func _on_pressed() -> void:
	"""按钮被点击时切换相机"""
	if not camera_manager:
		push_error("ArrowButton[%s]: camera_manager 为 null，无法切换镜头" % direction)
		return
	
	print("ArrowButton[%s]: 被点击了！当前镜头: %s" % [direction, camera_manager.current_camera])
	
	match direction:
		"up":
			# 向上箭头：
			# 在 Tinta → 移到 Andahuaylillas
			# 在 Andahuaylillas → 移到 Jungle (Paucartambo/Pilcopata中点)
			# 在 Jungle → 返回 Andahuaylillas
			if camera_manager.current_camera == "tinta":
				print("ArrowButton[up]: Tinta -> Andahuaylillas")
				camera_manager.set_camera_view("andahuaylillas")
			elif camera_manager.current_camera == "andahuaylillas":
				print("ArrowButton[up]: Andahuaylillas -> Jungle")
				camera_manager.set_camera_view("jungle")
			elif camera_manager.current_camera == "jungle":
				print("ArrowButton[up]: Jungle -> Andahuaylillas")
				camera_manager.set_camera_view("andahuaylillas")
		
		"down":
			# 向下箭头：
			# 在 Andahuaylillas → 移到 Tinta
			if camera_manager.current_camera == "andahuaylillas":
				print("ArrowButton[down]: Andahuaylillas -> Tinta")
				camera_manager.set_camera_view("tinta")
		
		"left":
			# 向左箭头：
			# 在 Marcapata → 返回 Andahuaylillas
			if camera_manager.current_camera == "marcapata":
				print("ArrowButton[left]: Marcapata -> Andahuaylillas")
				camera_manager.set_camera_view("andahuaylillas")
		
		"right":
			# 向右箭头（仅在 Andahuaylillas 显示）：
			# 在 Andahuaylillas → 移到 Marcapata
			if camera_manager.current_camera == "andahuaylillas":
				print("ArrowButton[right]: Andahuaylillas -> Marcapata")
				camera_manager.set_camera_view("marcapata")
