extends Node
class_name TooltipRegistry

"""
统一的提示框文本注册表
所有UI提示文本都在这里集中管理
格式：category -> element_name -> text
"""

# UI 系统提示
var ui_tooltips: Dictionary = {
	"ResourcePanel": {
		"potato_icon": "Potato\nThe primary staple crop with abundant energy.\nProduction multiplier: ×2.0",
		"corn_icon": "Corn\nA grain crop with moderate production capacity.\nProduction multiplier: ×1.0",
		"quinoa_icon": "Quinoa\nA highly nutritious grain crop.\nProduction multiplier: ×1.0",
		"llama_icon": "Llama\nLivestock with strong transport capacity.\nProduction multiplier: ×0.5",
		"coca_icon": "Coca\nTraditional crop with versatile uses.\nProduction multiplier: ×1.0"
	},
	"UnitPanel": {
		"rebel_army": "Rebel Army\nCombat Power: ★★★☆☆\nMovement: Moderate\nSpecial: High morale",
		"female_corps": "Female Corps\nCombat Power: ★★☆☆☆\nMovement: Fast\nSpecial: Highly mobile",
		"enemy_unit": "Enemy Unit\nCombat Power: ★★★★☆\nMovement: Normal\nSpecial: Well-trained"
	},
	"MapPanel": {
		"altitude_high": "High Altitude\nHigh elevation with harsh climate\nAgricultural output: ×0.8",
		"altitude_medium": "Medium Altitude\nModerate elevation and temperate climate\nAgricultural output: ×1.0",
		"altitude_low": "Low Altitude\nLow elevation with warm climate\nAgricultural output: ×1.2"
	},
	"GameStatus": {
		"hunger_status": "Hunger Status\nThe village has insufficient food\nProduction efficiency reduced to 20%",
		"control_status_player": "Player Controlled\nThis village is under your control\nCan recruit units and manage resources",
		"control_status_enemy": "Enemy Controlled\nThis village is controlled by the enemy\nNo operations possible",
		"population_low": "Low Population\nCurrent population is low, recruitment needed\nClick recruit button to add new units",
		"population_normal": "Population Stable\nPopulation is at normal levels"
	},
	"Buttons": {
		"recruit_button": "Recruit Soldiers\nClick to recruit new rebel soldiers\nCost: 3 Potatoes",
		"end_turn_button": "End Turn\nEnd your action phase\nEnters auto phase (production, consumption, movement)",
		"pause_menu_button": "Menu\nOpen game menu\nView settings and save/load progress"
	}
}

# 游戏系统提示
var game_tooltips: Dictionary = {
	"TurnSystem": {
		"player_phase": "Player Action Phase\nYou can recruit and move units\nClick 'End Turn' to enter auto phase",
		"auto_phase": "Auto Phase\nSystem automatically executes:\n1. Resource production\n2. Resource consumption\n3. Unit movement\n4. Enemy actions"
	},
	"CombatSystem": {
		"combat_damage": "Combat Damage\nDamage = Attacker Power - Defender Defense\nMinimum damage cannot be less than 1",
		"combat_retreat": "Retreat\nUnits can choose to fight or retreat\nRetreating avoids casualties but loses control"
	},
	"ResourceSystem": {
		"production": "Resource Production\nEach turn, villages produce resources based on population and resource type\nNormal: Output = Population ÷ 100 × multiplier\nHungry: Output = Population ÷ 100 × multiplier × 0.2",
		"consumption": "Resource Consumption\nEach turn each village consumes food to feed population\nConsumption rate: Population × 0.01 food/turn\nPriority: Potato > Corn > Quinoa"
	}
}

# 控制提示
var control_tooltips: Dictionary = {
	"MapControls": {
		"pan_camera": "Move Camera\nDrag mouse or use arrow keys\nScroll wheel to zoom",
		"select_unit": "Select Unit\nLeft-click a unit to select it\nView detailed unit information",
		"move_unit": "Move Unit\nAfter selecting, click target location\nUnit will automatically pathfind and move"
	}
}

func get_tooltip(category: String, element_name: String) -> String:
	"""
	Get the tooltip text for a specific element
	Args:
		category: Category name (e.g., "ResourcePanel", "Buttons")
		element_name: Element name (e.g., "potato_icon", "recruit_button")
	Returns:
		Tooltip text, or default text if not found
	"""
	if category in ui_tooltips:
		if element_name in ui_tooltips[category]:
			return ui_tooltips[category][element_name]
	
	if category in game_tooltips:
		if element_name in game_tooltips[category]:
			return game_tooltips[category][element_name]
	
	if category in control_tooltips:
		if element_name in control_tooltips[category]:
			return control_tooltips[category][element_name]
	
	return "[Missing Tooltip]\nCategory: %s\nElement: %s" % [category, element_name]

func set_tooltip(category: String, element_name: String, text: String) -> void:
	"""
	Set tooltip text (for dynamic updates)
	Args:
		category: Category name
		element_name: Element name
		text: New tooltip text
	"""
	if category not in ui_tooltips:
		ui_tooltips[category] = {}
	ui_tooltips[category][element_name] = text

func get_all_categories() -> Array:
	"""Get all categories"""
	var categories = []
	categories.append_array(ui_tooltips.keys())
	categories.append_array(game_tooltips.keys())
	categories.append_array(control_tooltips.keys())
	return categories

func get_category_items(category: String) -> Dictionary:
	"""Get all items in a specific category"""
	if category in ui_tooltips:
		return ui_tooltips[category].duplicate()
	if category in game_tooltips:
		return game_tooltips[category].duplicate()
	if category in control_tooltips:
		return control_tooltips[category].duplicate()
	return {}

func print_all_tooltips() -> void:
	"""Print all tooltips (for debugging)"""
	print("\n=== All Tooltips ===")
	for category in get_all_categories():
		var items = get_category_items(category)
		print("\n[%s]" % category)
		for element_name in items:
			var text = items[element_name].replace("\n", " | ")
			print("  - %s: %s" % [element_name, text])
