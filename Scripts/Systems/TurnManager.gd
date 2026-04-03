extends Node
class_name TurnManager

var current_turn: int = 0
var game_map: GameMap
var resource_manager: ResourceManager

signal turn_started(turn_number: int)
signal turn_ended(turn_number: int)

@onready var turn_label = $"../../UILayer/TurnInfo/TurnLabel"
@onready var next_turn_button = $"../../UILayer/NextTurnButton"

func _ready() -> void:
	game_map = get_parent().get_parent()
	resource_manager = get_parent().get_node("ResourceManager")
	
	# Connect button signal
	next_turn_button.pressed.connect(_on_next_turn_pressed)
	
	update_ui()

func _on_next_turn_pressed() -> void:
	"""Next turn button pressed"""
	next_turn()

func next_turn() -> void:
	"""Progress to next turn"""
	turn_ended.emit(current_turn)
	current_turn += 1
	
	# All resource nodes produce resources
	for node in game_map.all_nodes:
		if node is ResourceNode:
			(node as ResourceNode).produce_resource()
	
	# Update total resources
	resource_manager.calculate_total_resources()
	
	turn_started.emit(current_turn)
	update_ui()
	
	print("=== Turn %d Started ===" % current_turn)

func update_ui() -> void:
	"""Update UI display"""
	if is_node_ready():
		turn_label.text = "Turn: %d" % current_turn
