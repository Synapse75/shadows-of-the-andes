extends Node
class_name CameraUIController

# UI 绠ご鎸夐挳寮曠敤
var arrow_up: Button
var arrow_down: Button
var arrow_left: Button
var arrow_right: Button
var camera_manager: CameraManager

func _ready() -> void:
	# 鑾峰彇鎽勫儚鏈虹鐞嗗櫒鍜孶I鎸夐挳寮曠敤
	camera_manager = get_tree().root.get_node("Main/SubViewportContainer/SubViewport/Camera2D")
	
	# 鑾峰彇绠ご鎸夐挳锛堟牴鎹疄闄呭満鏅爲缁撴瀯璋冩暣璺緞锛?
	arrow_up = get_parent().get_node_or_null("ArrowUp")
	arrow_down = get_parent().get_node_or_null("ArrowDown")
	arrow_left = get_parent().get_node_or_null("ArrowLeft")
	arrow_right = get_parent().get_node_or_null("ArrowRight")
	
	# 杩炴帴绠ご鎸夐挳淇″彿
	if arrow_up:
		arrow_up.pressed.connect(_on_arrow_up_pressed)
	if arrow_down:
		arrow_down.pressed.connect(_on_arrow_down_pressed)
	if arrow_left:
		arrow_left.pressed.connect(_on_arrow_left_pressed)
	if arrow_right:
		arrow_right.pressed.connect(_on_arrow_right_pressed)
	
	# 鍒濆鍖栫澶存樉绀虹姸鎬?
	update_arrow_visibility()

func _process(_delta: float) -> void:
	"""姣忓抚鏇存柊绠ご鐨勫彲瑙佺姸鎬?""
	update_arrow_visibility()

func update_arrow_visibility() -> void:
	"""鏍规嵁褰撳墠闀滃ご鏇存柊绠ご鐨勬樉绀?闅愯棌"""
	var connected = camera_manager.get_connected_cameras()
	
	# 鏍规嵁闀滃ご杩炴帴鍏崇郴鏇存柊绠ご鏄剧ず
	if arrow_up:
		arrow_up.visible = "andahuaylillas" in connected
	if arrow_down:
		arrow_down.visible = "jungle" in connected or "marcapata" in connected
	if arrow_left:
		arrow_left.visible = "marcapata" in connected
	if arrow_right:
		arrow_right.visible = "tinta" in connected

func _on_arrow_up_pressed() -> void:
	"""鍚戜笂绠ご - 閫氬父杩炴帴鍒癆ndahuaylillas"""
	if camera_manager.can_view_camera("andahuaylillas"):
		camera_manager.set_camera_view("andahuaylillas")

func _on_arrow_down_pressed() -> void:
	"""鍚戜笅绠ご - Jungle鎴朚arcapata"""
	if camera_manager.can_view_camera("jungle"):
		camera_manager.set_camera_view("jungle")
	elif camera_manager.can_view_camera("marcapata"):
		camera_manager.set_camera_view("marcapata")

func _on_arrow_left_pressed() -> void:
	"""鍚戝乏绠ご - Marcapata"""
	if camera_manager.can_view_camera("marcapata"):
		camera_manager.set_camera_view("marcapata")

func _on_arrow_right_pressed() -> void:
	"""鍚戝彸绠ご - Tinta"""
	if camera_manager.can_view_camera("tinta"):
		camera_manager.set_camera_view("tinta")
