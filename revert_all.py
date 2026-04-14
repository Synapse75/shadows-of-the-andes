import re

with open('Scenes/main.tscn', 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Remove MapContainer and SubViewport nodes
text = re.sub(r'\[node name="MapContainer" type="SubViewportContainer" parent="\."\]\n.*?render_target_update_mode = 4\n\n', '', text, flags=re.DOTALL)

# 2. Change parent back for Map and Camera2D
text = text.replace('parent="MapContainer/SubViewport"', 'parent="."')

# 3. Restore Arrow positions
# ArrowUp
text = re.sub(
    r'(?s)(\[node name="ArrowUp" parent="UILayer"[^\]]+\]\s+offset_left = )311\.0(\s+offset_top = )36\.0(\s+offset_right = )319\.0(\s+offset_bottom = )44\.0',
    r'\g<1>233.0\g<2>-4.0\g<3>241.0\g<4>4.0',
    text
)
# ArrowDown
text = re.sub(
    r'(?s)(\[node name="ArrowDown" parent="UILayer"[^\]]+\]\s+offset_left = )311\.0(\s+offset_top = )288\.0(\s+offset_right = )319\.0(\s+offset_bottom = )296\.0',
    r'\g<1>233.0\g<2>288.0\g<3>241.0\g<4>296.0',
    text
)
# ArrowRight
text = re.sub(
    r'(?s)(\[node name="ArrowRight" parent="UILayer"[^\]]+\]\s+offset_left = )471\.0(\s+offset_top = )166\.0(\s+offset_right = )479\.0(\s+offset_bottom = )174\.0',
    r'\g<1>471.0\g<2>142.0\g<3>479.0\g<4>150.0',
    text
)
# ArrowLeft
text = re.sub(
    r'(?s)(\[node name="ArrowLeft" parent="UILayer"[^\]]+\]\s+offset_left = )150\.0(\s+offset_top = )166\.0\noffset_right = 158\.0(\s+offset_bottom = )174\.0',
    r'\g<1>-8.0\g<2>142.0\g<3>150.0',
    text
)

with open('Scenes/main.tscn', 'w', encoding='utf-8') as f:
    f.write(text)

# Fix GameMap.gd
with open('Scripts/GameMap.gd', 'r', encoding='utf-8') as f:
    text = f.read()
text = text.replace('ui_manager = get_tree().root.get_node("Main/Systems/UIManager")', 'ui_manager = get_parent().get_node("Systems/UIManager")')
text = text.replace('unit_manager = get_tree().root.get_node("Main/Systems/UnitManager")', 'unit_manager = get_parent().get_node("Systems/UnitManager")')
with open('Scripts/GameMap.gd', 'w', encoding='utf-8') as f:
    f.write(text)

# Fix TurnManager.gd
with open('Scripts/Systems/TurnManager.gd', 'r', encoding='utf-8') as f:
    text = f.read()
text = text.replace('get_tree().root.get_node("Main/MapContainer/SubViewport/Map")', 'get_tree().root.get_node("Main/Map")')
with open('Scripts/Systems/TurnManager.gd', 'w', encoding='utf-8') as f:
    f.write(text)

# Fix VillageUIManager.gd
with open('Scripts/Systems/VillageUIManager.gd', 'r', encoding='utf-8') as f:
    text = f.read()
text = text.replace('get_tree().root.get_node("Main/MapContainer/SubViewport/Map")', 'get_tree().root.get_node("Main/Map")')
with open('Scripts/Systems/VillageUIManager.gd', 'w', encoding='utf-8') as f:
    f.write(text)

# Fix ArrowButton.gd
with open('Scripts/UI/ArrowButton.gd', 'r', encoding='utf-8') as f:
    text = f.read()
text = text.replace('get_tree().root.get_node("Main/MapContainer/SubViewport/Camera2D")', 'get_tree().root.get_node("Main/Camera2D")')
with open('Scripts/UI/ArrowButton.gd', 'w', encoding='utf-8') as f:
    f.write(text)

# Fix CameraArrowManager.gd
with open('Scripts/UI/CameraArrowManager.gd', 'r', encoding='utf-8') as f:
    text = f.read()
text = text.replace('main_node.get_node("MapContainer/SubViewport/Camera2D")', 'main_node.get_node("Camera2D")')
with open('Scripts/UI/CameraArrowManager.gd', 'w', encoding='utf-8') as f:
    f.write(text)

