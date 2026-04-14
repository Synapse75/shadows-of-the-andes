with open('Scripts/GameMap.gd', 'r', encoding='utf-8') as f:
    text = f.read()

lines = text.split('\n')
for i, line in enumerate(lines):
    if 'ui_manager = get_tree().root.get_node("Main/Systems/UIManager")' in line:
        lines[i] = '\tui_manager = get_tree().root.get_node("Main/Systems/UIManager")'
    elif 'unit_manager = get_tree().root.get_node("Main/Systems/UnitManager")' in line:
        lines[i] = '\tunit_manager = get_tree().root.get_node("Main/Systems/UnitManager")'

with open('Scripts/GameMap.gd', 'w', encoding='utf-8') as f:
    f.write('\n'.join(lines))
