extends Node
class_name ResourceManager

# Global resource pool (summarizes resources from all nodes)
var total_resources: Dictionary = {
	"food": 0,
	"population": 0,
	"units": 0
}

var resource_nodes: Array[ResourceNode] = []
var village_nodes: Array[VillageNode] = []

signal resources_updated(new_total: Dictionary)

func _ready() -> void:
	# Wait for GameMap to finish initializing
	await get_tree().root.child_entered_tree
	_collect_nodes()

func _collect_nodes() -> void:
	"""Collect all resource nodes and villages"""
	for node in get_tree().get_nodes_in_group("nodes"):
		if node is ResourceNode:
			resource_nodes.append(node)
		elif node is VillageNode:
			village_nodes.append(node)

func calculate_total_resources() -> Dictionary:
	"""Calculate the sum of all resources"""
	var total = {
		"food": 0,
		"population": 0,
		"units": 0
	}
	
	for node in resource_nodes + village_nodes:
		for resource_type in total:
			total[resource_type] += node.resources.get(resource_type, 0)
	
	total_resources = total
	resources_updated.emit(total)
	return total

func check_resource_status() -> Dictionary:
	"""Check if resources are sufficient"""
	var total = calculate_total_resources()
	return {
		"food_ok": total["food"] > 0,
		"population_ok": total["population"] > 0,
		"units_ok": total["units"] > 0,
		"total": total
	}

func apply_resource_consumption(consumption: Dictionary) -> bool:
	"""消耗资源（如果不足则返回false）"""
	var status = check_resource_status()
	
	for resource_type in consumption:
		if not status[resource_type + "_ok"]:
			return false
	
	# 实现消耗逻辑（从各节点扣除）
	for resource_type in consumption:
		var remaining = consumption[resource_type]
		for node in (resource_nodes + village_nodes):
			if remaining <= 0:
				break
			if node.resources[resource_type] > 0:
				var consumed = min(remaining, node.resources[resource_type])
				node.resources[resource_type] -= consumed
				remaining -= consumed
	
	calculate_total_resources()
	return true
