import re

with open('Scenes/main.tscn', 'r', encoding='utf-8') as f:
    content = f.read()

subviewport_nodes = """[node name="MapContainer" type="SubViewportContainer" parent="."]
offset_left = 150.0
offset_top = 40.0
offset_right = 480.0
offset_bottom = 300.0

[node name="SubViewport" type="SubViewport" parent="MapContainer"]
handle_input_locally = false
size = Vector2i(330, 260)
render_target_update_mode = 4

"""

# Insert MapContainer right before Map
content = re.sub(
    r'(\[node name="Map" type="Node2D" parent="\." unique_id=\w+\])',
    subviewport_nodes + r'\1',
    content
)

# Change parent of Map to MapContainer/SubViewport
content = re.sub(
    r'(\[node name="Map" type="Node2D" parent=")\.(")',
    r'\1MapContainer/SubViewport\2',
    content
)

# Change parent of Camera2D to MapContainer/SubViewport
content = re.sub(
    r'(\[node name="Camera2D" type="Camera2D" parent=")\.(")',
    r'\1MapContainer/SubViewport\2',
    content
)

with open('Scenes/main.tscn', 'w', encoding='utf-8') as f:
    f.write(content)
