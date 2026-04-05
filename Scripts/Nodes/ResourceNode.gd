extends BaseNode
class_name ResourceNode

@export var resource_type: String
@export var production_rate: int = 5
@export var controlled_sprite: Texture2D  # 玩家控制时的sprite
@export var uncontrolled_sprite: Texture2D  # 未控制时的sprite

var sprite: Sprite2D

func _ready() -> void:
	super()
	node_type = "resource"
	sprite = $Sprite2D
	update_visual()
	control_changed.connect(_on_control_changed)

func _process(_delta: float) -> void:
	# Generate resources every turn - called by GameManager later
	pass

func produce_resource() -> void:
	"""Generate this resource"""
	if production_rate > 0:
		add_resource("food", production_rate)

func _on_control_changed(_is_player: bool) -> void:
	"""Update sprite when control changes"""
	update_visual()

func update_visual() -> void:
	"""Update node sprite based on control status"""
	if not is_node_ready() or sprite == null:
		return
	
	# 根据控制状态切换sprite
	if control_by_player and controlled_sprite:
		sprite.texture = controlled_sprite
	elif not control_by_player and uncontrolled_sprite:
		sprite.texture = uncontrolled_sprite
