extends BaseNode
class_name VillageNode

@export var max_population: int = 100
@export var recruitment_rate: int = 5

# UI 引用
var village_sprite: AnimatedSprite2D
var village_label: Label

func _ready() -> void:
	super()
	node_type = "village"
	
	# 获取UI节点引用
	village_sprite = get_node("VillageSprite")
	village_label = get_node("VillageLabel")
	
	# 初始化标签和精灵
	village_label.text = location_name
	update_visual()

func update_visual() -> void:
	"""根据控制权切换动画"""
	if not village_sprite:
		return
	
	if control_by_player:
		village_sprite.animation = "controlled"
	else:
		village_sprite.animation = "uncontrolled"
	
	village_sprite.play()
