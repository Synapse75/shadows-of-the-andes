extends BaseNode
class_name VillageNode

@export var max_population: int = 100
@export var recruitment_rate: int = 5

func _ready() -> void:
	super()
	node_type = "village"
	resources["population"] = max_population / 2

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
