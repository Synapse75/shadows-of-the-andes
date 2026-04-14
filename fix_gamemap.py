import re

with open('Scripts/GameMap.gd', 'r', encoding='utf-8') as f:
    text = f.read()

fixed = re.sub(
    r'func _ready\(\) -> void:\n\s*# 自动查找所有节点\n\s*_collect_all_nodes\(\)\n\s*_setup_connections\(\)\nui_manager = get_tree\(\)\.root\.get_node\("Main/Systems/UIManager"\)\n\s*unit_manager = get_tree\(\)\.root\.get_node\("Main/Systems/UnitManager"\)\n\n\s*# 等待 UnitManager 收集单位后，将单位分配到节点',
    'func _ready() -> void:\n\t# 自动查找所有节点\n\t_collect_all_nodes()\n\t_setup_connections()\n\tui_manager = get_tree().root.get_node("Main/Systems/UIManager")\n\tunit_manager = get_tree().root.get_node("Main/Systems/UnitManager")\n\n\t# 等待 UnitManager 收集单位后，将单位分配到节点',
    text
)

with open('Scripts/GameMap.gd', 'w', encoding='utf-8') as f:
    f.write(fixed)
