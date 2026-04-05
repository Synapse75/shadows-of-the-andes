extends BaseNode
class_name VillageNode

@export var max_population: int = 100
@export var recruitment_rate: int = 5
@export var controlled_sprite: Texture2D  # 玩家控制时的sprite
@export var uncontrolled_sprite: Texture2D  # 未控制时的sprite

var sprite: Sprite2D

func _ready() -> void:
	super()
	node_type = "village"
	sprite = $Sprite2D
	resources["population"] = max_population / 2
	update_visual()
	control_changed.connect(_on_control_changed)

func recruit_units(count: int) -> bool:
	if resources["population"] >= count:
		resources["population"] -= count
		resources["units"] += count
		resources_changed.emit(resources)
		return true
	return false

func grow_population() -> void:
	if resources["population"] < max_population:
		resources["population"] += 1
		resources_changed.emit(resources)

func _on_control_changed(_is_player: bool) -> void:
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
