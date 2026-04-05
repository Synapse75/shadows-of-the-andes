extends Node
class_name TurnManager

var current_turn: int = 0
var game_map: GameMap
var resource_manager: ResourceManager
var turn_label: Label
var next_turn_button: Button

signal turn_started(turn_number: int)
signal turn_ended(turn_number: int)

func _ready() -> void:
	# 获取GameMap引用（现在在Map节点上）
	game_map = get_tree().root.get_node("Main/Map")
	resource_manager = get_parent().get_node("ResourceManager")
	
	# 使用get_node获取UI元素（更稳健）
	var main_node = get_tree().root.get_node("Main")
	turn_label = main_node.get_node("UILayer/TurnInfo/TurnLabel")
	next_turn_button = main_node.get_node("UILayer/NextTurnButton")
	
	# Connect button signal
	if next_turn_button:
		next_turn_button.pressed.connect(_on_next_turn_pressed)
	else:
		push_error("NextTurnButton not found!")
	
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
