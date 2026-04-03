extends Node
class_name UnitManager

var all_units: Array[Unit] = []
var player_units: Array[Unit] = []
var selected_unit: Unit = null

signal unit_selected(unit: Unit)
signal unit_deselected()

func _ready() -> void:
	await get_tree().root.child_entered_tree
	_collect_units()

func _collect_units() -> void:
	"""Collect all units in the scene"""
	for unit in get_tree().get_nodes_in_group("units"):
		all_units.append(unit)
		# Temporarily assume all units belong to player
		player_units.append(unit)

func select_unit(unit: Unit) -> void:
	"""Select a unit"""
	if selected_unit == unit:
		return
	
	selected_unit = unit
	unit_selected.emit(unit)
	print("Selected unit: %s" % unit.unit_name)

func deselect_unit() -> void:
	"""Deselect unit"""
	selected_unit = null
	unit_deselected.emit()
	print("Deselected unit")

func get_units_at_node(node: BaseNode) -> Array[Unit]:
	"""Get all units at specified node"""
	var units_at_node: Array[Unit] = []
	for unit in all_units:
		if unit.current_node == node:
			units_at_node.append(unit)
	return units_at_node
