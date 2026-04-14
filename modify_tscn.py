import sys

tscn_path = 'D:/Github/shadows-of-the-andes/Scenes/main.tscn'
with open(tscn_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

new_lines = []
for line in lines:
    if line.startswith('[node name=\ Map\ type=\Node2D\') and 'parent=\.\' in line:
        new_lines.append('[node name=\SubViewportContainer\ type=\SubViewportContainer\ parent=\.\]\n')
        new_lines.append('offset_left = 270.0\n')
        new_lines.append('offset_top = 480.0\n')
        new_lines.append('offset_right = 1080.0\n')
        new_lines.append('offset_bottom = 1920.0\n')
        new_lines.append('[node name=\SubViewport\ type=\SubViewport\ parent=\SubViewportContainer\]\n')
        new_lines.append('disable_3d = true\n')
        new_lines.append('transparent_bg = true\n')
        new_lines.append('handle_input_locally = false\n')
        new_lines.append('size = Vector2i(810, 1440)\n')
        new_lines.append('render_target_update_mode = 4\n')
        line = line.replace('parent=\.\', 'parent=\SubViewportContainer/SubViewport\')
        new_lines.append(line)
        
    elif line.startswith('[node name=\Camera2D\ type=\Camera2D\') and 'parent=\.\' in line:
        line = line.replace('parent=\.\', 'parent=\SubViewportContainer/SubViewport\')
        new_lines.append(line)
        
    elif line.startswith('[node name=\CameraArrowManager\ type=\Node\') and 'parent=\.\' in line:
        line = line.replace('parent=\.\', 'parent=\SubViewportContainer/SubViewport\')
        new_lines.append(line)
        
    else:
        new_lines.append(line)

with open(tscn_path, 'w', encoding='utf-8') as f:
    f.writelines(new_lines)
print('Updated main.tscn structure.')
