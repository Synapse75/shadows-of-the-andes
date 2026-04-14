import glob

files_to_check = [
    'Scripts/Systems/TurnManager.gd',
    'Scripts/Systems/VillageUIManager.gd',
    'Scripts/UI/ArrowButton.gd'
]

for filename in files_to_check:
    with open(filename, 'r', encoding='utf-8') as f:
        text = f.read()
    
    lines = text.split('\n')
    for i, line in enumerate(lines):
        if 'game_map = get_tree().root.get_node("Main/MapContainer/SubViewport/Map")' in line and not line.startswith('\t') and not line.startswith(' '):
            lines[i] = '\tgame_map = get_tree().root.get_node("Main/MapContainer/SubViewport/Map")'
        elif 'camera_manager = get_tree().root.get_node("Main/MapContainer/SubViewport/Camera2D") as CameraManager' in line and not line.startswith('\t') and not line.startswith(' '):
            lines[i] = '\tcamera_manager = get_tree().root.get_node("Main/MapContainer/SubViewport/Camera2D") as CameraManager'

    with open(filename, 'w', encoding='utf-8') as f:
        f.write('\n'.join(lines))
