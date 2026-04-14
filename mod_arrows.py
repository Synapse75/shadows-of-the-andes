import re

with open('Scenes/main.tscn', 'r', encoding='utf-8') as f:
    content = f.read()

# ArrowUp (x: 233 -> 311, y: -4 -> 36)
content = re.sub(
    r'(?s)(\[node name="ArrowUp" parent="UILayer"[^\]]+\]\s+offset_left = )233\.0(\s+offset_top = )-4\.0(\s+offset_right = )241\.0(\s+offset_bottom = )4\.0',
    r'\g<1>311.0\g<2>36.0\g<3>319.0\g<4>44.0',
    content
)

# ArrowDown (x: 233 -> 311, y: 288 -> 288)
content = re.sub(
    r'(?s)(\[node name="ArrowDown" parent="UILayer"[^\]]+\]\s+offset_left = )233\.0(\s+offset_top = )288\.0(\s+offset_right = )241\.0(\s+offset_bottom = )296\.0',
    r'\g<1>311.0\g<2>288.0\g<3>319.0\g<4>296.0',
    content
)

# ArrowRight (x: 471 -> 471, y: 142 -> 166)
content = re.sub(
    r'(?s)(\[node name="ArrowRight" parent="UILayer"[^\]]+\]\s+offset_left = )471\.0(\s+offset_top = )142\.0(\s+offset_right = )479\.0(\s+offset_bottom = )150\.0',
    r'\g<1>471.0\g<2>166.0\g<3>479.0\g<4>174.0',
    content
)

# ArrowLeft (x: -8 -> 150, y: 142 -> 166)
content = re.sub(
    r'(?s)(\[node name="ArrowLeft" parent="UILayer"[^\]]+\]\s+offset_left = )-8\.0(\s+offset_top = )142\.0(\s+offset_bottom = )150\.0',
    r'\g<1>150.0\g<2>166.0\noffset_right = 158.0\g<3>174.0',
    content
)

with open('Scenes/main.tscn', 'w', encoding='utf-8') as f:
    f.write(content)
