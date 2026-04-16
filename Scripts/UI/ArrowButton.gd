extends Button
class_name ArrowButton

@export var direction: String = "up"
var game_controller: GameController
var camera_manager: CameraManager
var arrow_sprite: AnimatedSprite2D

# 动画帧数据
var animation_frames: Array[AtlasTexture] = []
var current_frame: int = 0
var frame_timer: float = 0.0
var frame_duration: float = 0.5  # 2fps = 0.5秒/帧

func _ready() -> void:
	# 获取gambe controller引用
	game_controller = get_tree().root.get_node("Main") as GameController
	camera_manager = get_tree().root.get_node("Main/SubViewportContainer/SubViewport/Camera2D") as CameraManager
	
	# 检查是否成功获取管理器
	if not camera_manager:
		push_error("ArrowButton[%s]: 无法获取 CameraManager" % direction)
	else:
		print("ArrowButton[%s]: 成功获取 CameraManager，当前镜头: %s" % [direction, camera_manager.current_camera])
	
	# 获取 AnimatedSprite2D 引用
	arrow_sprite = get_node_or_null("AnimatedSprite2D")
	if not arrow_sprite:
		push_error("ArrowButton[%s]: 无法获取 AnimatedSprite2D" % direction)
	else:
		# 设置精灵位置到按钮中心，确保绕中心旋转
		arrow_sprite.position = size / 2.0
		arrow_sprite.offset = Vector2.ZERO
	
	# 初始化动画帧
	_setup_animation_frames()
	
	# 根据方向设置箭头旋转
	_rotate_arrow()
	
	# 连接信号
	pressed.connect(_on_pressed)
	
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

func _input(event: InputEvent) -> void:
	"""捕获所有输入事件用于调试"""
	if not event is InputEventMouseButton:
		return
	
	# 检查鼠标位置是否在按钮范围内
	var mouse_pos = event.position
	var button_rect = get_global_rect()
	
	if button_rect.has_point(mouse_pos):
		print("ArrowButton[%s]: 捕获到鼠标事件 - 位置:%s, 按下:%s, 按钮区域:%s" % [direction, mouse_pos, event.pressed, button_rect])

func _on_pressed() -> void:
	"""按钮被点击时切换相机"""
	print("\n========== ArrowButton[%s] 被点击 ==========" % direction)
	
	if not camera_manager:
		push_error("ArrowButton[%s]: camera_manager 为 null，无法切换镜头" % direction)
		return
	
	var current = camera_manager.current_camera
	print("当前镜头: %s" % current)
	print("目标方向: %s" % direction)
	
	match direction:
		"up":
			print("  → up 箭头逻辑")
			if current == "tinta":
				print("    → Tinta -> Andahuaylillas")
				camera_manager.set_camera_view("andahuaylillas")
				print("    → set_camera_view 已调用")
			elif current == "andahuaylillas":
				print("    → Andahuaylillas -> Jungle")
				camera_manager.set_camera_view("jungle")
				print("    → set_camera_view 已调用")
			elif current == "jungle":
				print("    → Jungle -> Andahuaylillas")
				camera_manager.set_camera_view("andahuaylillas")
				print("    → set_camera_view 已调用")
			else:
				print("    → 不匹配任何条件 (当前镜头: %s)" % current)
		
		"down":
			print("  → down 箭头逻辑")
			if current == "andahuaylillas":
				print("    → Andahuaylillas -> Tinta")
				camera_manager.set_camera_view("tinta")
				print("    → set_camera_view 已调用")
			elif current == "jungle":
				print("    → Jungle -> Andahuaylillas")
				camera_manager.set_camera_view("andahuaylillas")
				print("    → set_camera_view 已调用")
			else:
				print("    → 不匹配任何条件 (当前镜头: %s)" % current)
		
		"left":
			print("  → left 箭头逻辑")
			if current == "marcapata":
				print("    → Marcapata -> Andahuaylillas")
				camera_manager.set_camera_view("andahuaylillas")
				print("    → set_camera_view 已调用")
			else:
				print("    → 不匹配任何条件 (当前镜头: %s)" % current)
		
		"right":
			print("  → right 箭头逻辑")
			if current == "andahuaylillas":
				print("    → Andahuaylillas -> Marcapata")
				camera_manager.set_camera_view("marcapata")
				print("    → set_camera_view 已调用")
			else:
				print("    → 不匹配任何条件 (当前镜头: %s)" % current)
	
	print("新的镜头位置: %s" % camera_manager.global_position)
	print("========================================\n")

func _rotate_arrow() -> void:
	"""根据箭头方向旋转图标"""
	if not arrow_sprite:
		return
	
	match direction:
		"up":
			arrow_sprite.rotation = 0.0
		"down":
			arrow_sprite.rotation = PI  # 180度
		"left":
			arrow_sprite.rotation = -PI / 2.0  # -90度
		"right":
			arrow_sprite.rotation = PI / 2.0  # 90度
		_:
			push_warning("ArrowButton: 未知的方向 %s" % direction)
