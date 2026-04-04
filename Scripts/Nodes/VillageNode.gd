extends BaseNode
class_name VillageNode

@export var max_population: int = 100
@export var recruitment_rate: int = 5

var square: ColorRect

func _ready() -> void:
	super()
	node_type = "village"
	square = $ColorRect
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
	if not is_node_ready():
		return
	
	var color: Color = Color.BLUE if control_by_player else Color.RED
	square.color = color
