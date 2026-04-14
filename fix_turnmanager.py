with open('Scripts/Systems/TurnManager.gd', 'r', encoding='utf-8') as f:
    text = f.read()

lines = text.split('\n')
for i, line in enumerate(lines):
    if 'game_map = get_tree().root.get_node("Main/MapContainer/SubViewport/Map")' in line:
        lines[i] = '\tgame_map = get_tree().root.get_node("Main/MapContainer/SubViewport/Map")'

with open('Scripts/Systems/TurnManager.gd', 'w', encoding='utf-8') as f:
    f.write('\n'.join(lines))
