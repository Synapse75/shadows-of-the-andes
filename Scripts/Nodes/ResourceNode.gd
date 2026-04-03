extends BaseNode
class_name ResourceNode

@export var resource_type: String
@export var production_rate: int = 5

var circle: ColorRect

func _ready() -> void:
	super()
	node_type = "resource"
	circle = $ColorRect
	update_visual()
	control_changed.connect(_on_control_changed)

func _process(_delta: float) -> void:
	# Generate resources every turn - called by GameManager later
	pass

func produce_resource() -> void:
	"""Generate this resource"""
	add_resource("food", production_rate)

func _on_control_changed(_is_player: bool) -> void:
	"""Update color when control changes"""
	update_visual()

func update_visual() -> void:
	"""Update node color to represent different states"""
	if not is_node_ready():
		return
		
	var color: Color
	match altitude:
		"high":
			color = Color.LIGHT_SKY_BLUE if control_by_player else Color.DARK_GRAY
		"medium":
			color = Color.YELLOW if control_by_player else Color.DIM_GRAY
		"low":
			color = Color.GREEN if control_by_player else Color.DARK_SLATE_GRAY
		_:
			color = Color.WHITE
	
	circle.color = color
