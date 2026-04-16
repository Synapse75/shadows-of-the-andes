extends Node2D
class_name VillageNode

# Node basic properties
@export var node_id: String
@export var location_name: String  # Location name: e.g. "Tinta", "Tungasuca"
@export var location_description: String  # Location description
@export var node_type: String  # "resource" or "village" or "start"
@export var altitude: String  # "high", "medium", "low"
@export var control_by_player: bool = false

# Resources and population
var resources: Dictionary = {
	"food": 0,
	"population": 0,
	"units": 0
}

# Resource storage limits (each resource type max 10)
const RESOURCE_STORAGE_LIMIT = 10

# Resource production system
var resource_production_rates: Dictionary = {}  # {"resource_name": production_rate_per_turn}
var resource_accumulated: Dictionary = {}  # Floating point accumulator for production

var neighbors: Array[VillageNode] = []
var stationed_units: Array[Unit] = []  # Units stationed at this node
var enemy_units: Array[EnemyUnit] = []  # Enemy units at this node

# 资源图标显示
var resource_icons_container: VBoxContainer
var resource_icon_scenes: Dictionary = {}  # resource_type -> HBoxContainer

signal control_changed(is_player_controlled: bool)
signal resources_changed(new_resources: Dictionary)
signal units_changed(new_units: Array)
signal enemy_units_changed(new_units: Array)

@export var max_population: int = 100
@export var recruitment_rate: int = 5

# UI 引用
var village_sprite: AnimatedSprite2D
var village_label: Label

func _ready() -> void:
	add_to_group("nodes")
	
	village_sprite = get_node_or_null("VillageSprite")
	if village_sprite:
		var mat = ShaderMaterial.new()
		mat.shader = load("res://Shaders/outline.gdshader")
		mat.set_shader_parameter("line_color", Color(1.0, 1.0, 1.0, 1.0))
		mat.set_shader_parameter("is_hovered", false)
		village_sprite.material = mat

	village_label = get_node_or_null("VillageLabel")
	if village_label and location_name != "":
		village_label.text = location_name

	update_visual()

func add_neighbor(node: VillageNode) -> void:
	"""Add adjacent node"""
	if node not in neighbors:
		neighbors.append(node)

func add_unit(unit: Unit) -> void:
	"""Add unit to this node"""
	if unit not in stationed_units:
		stationed_units.append(unit)
		units_changed.emit(stationed_units)

func remove_unit(unit: Unit) -> void:
	"""Remove unit from this node"""
	if unit in stationed_units:
		stationed_units.erase(unit)
		units_changed.emit(stationed_units)

func add_enemy_unit(unit: EnemyUnit) -> void:
	"""Add enemy unit to this node"""
	if unit not in enemy_units:
		enemy_units.append(unit)
		enemy_units_changed.emit(enemy_units)

func remove_enemy_unit(unit: EnemyUnit) -> void:
	"""Remove enemy unit from this node"""
	if unit in enemy_units:
		enemy_units.erase(unit)
		enemy_units_changed.emit(enemy_units)

func set_control(is_player: bool) -> void:
	"""Change node control"""
	if control_by_player != is_player:
		control_by_player = is_player
		control_changed.emit(is_player)
		update_visual()

func add_resource(resource_type: String, amount: int) -> bool:
	"""Add resource with storage limit (10 per resource type)
	Returns: true if all resource added, false if capped at limit"""
	if resource_type not in resources:
		resources[resource_type] = 0
	
	var current = resources[resource_type]
	var new_amount = min(current + amount, RESOURCE_STORAGE_LIMIT)
	var added = new_amount - current
	resources[resource_type] = new_amount
	resources_changed.emit(resources)
	
	# Return false if capped (some resource couldn't be added)
	return added == amount

func remove_resource(resource_type: String, amount: int) -> bool:
	"""Consume resource - returns whether successful"""
	if resources[resource_type] >= amount:
		resources[resource_type] -= amount
		resources_changed.emit(resources)
		return true
	return false

func get_node_info() -> Dictionary:
	"""Return node information"""
	return {
		"id": node_id,
		"location_name": location_name,
		"location_description": location_description,
		"type": node_type,
		"altitude": altitude,
		"player_controlled": control_by_player,
		"resources": resources.duplicate(),
		"neighbors_count": neighbors.size()
	}

func initialize_resource_production(resource_types: Array, production_rate: float) -> void:
	"""Initialize resource production for this village"""
	for resource_type in resource_types:
		resource_production_rates[resource_type] = production_rate
		resource_accumulated[resource_type] = 0.0

func produce_resources() -> void:
	"""Produce resources based on production rates (called each turn)"""
	for resource_type in resource_production_rates:
		var rate = resource_production_rates[resource_type]
		resource_accumulated[resource_type] += rate
		
		# Convert accumulated to integer production
		var produced = int(resource_accumulated[resource_type])
		if produced > 0:
			add_resource(resource_type, produced)
			resource_accumulated[resource_type] -= produced

func get_displayed_resource_amount(resource_type: String) -> int:
	"""Get the displayed amount (integer) of a resource"""
	if resource_type in resources:
		return int(resources[resource_type])
	return 0


func set_hover_state(is_hovered: bool) -> void:
	if village_sprite and village_sprite.material is ShaderMaterial:
		village_sprite.material.set_shader_parameter("is_hovered", is_hovered)

func update_visual() -> void:
	"""根据控制权切换动画"""
	if not village_sprite:
		return

	if control_by_player:
		village_sprite.animation = "controlled"
	else:
		village_sprite.animation = "uncontrolled"

	village_sprite.play()
