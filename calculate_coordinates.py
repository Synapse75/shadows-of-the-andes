#!/usr/bin/env python3
"""
Calculate hardcoded screen coordinates for all nodes in each camera view.
This eliminates runtime coordinate mapping calculations.
"""

# World coordinates of all nodes (from main.tscn)
nodes_world_pos = {
    "tinta": (732, 960),
    "tungasuca": (682, 977),
    "pampamarca": (692, 963),
    "sicuani": (851, 1051),
    "urcos": (585, 638),
    "quiquijana": (640, 740),
    "paucartambo": (603, 372),
    "andahuaylillas": (547, 633),
    "marcapata": (1027, 574),
    "pilcopata": (737, 107),
    "cusco": (354, 532),
    "ocongate": (744, 598),
    "challabamba": (566, 310),
}

# Camera positions for each view (from CameraManager.gd)
cameras = {
    "tinta": (732, 960),
    "andahuaylillas": (547, 633),
    "marcapata": (1027, 574),
    "jungle": (670, 230),
}

# SubViewport configuration
# - SubViewport size: 500x350
# - SubViewportContainer offset: (140, 50)
# - So screen coordinate = viewport_coord + (140, 50)
# - And viewport_coord = world_pos - camera_pos + (250, 175) [viewport center]

VIEWPORT_SIZE = (500, 350)
VIEWPORT_CENTER = (VIEWPORT_SIZE[0] // 2, VIEWPORT_SIZE[1] // 2)  # (250, 175)
CONTAINER_OFFSET = (140, 50)  # SubViewportContainer offset_left, offset_top

def calculate_screen_pos(world_pos, camera_pos):
    """Convert world position to screen position given camera position"""
    # Relative position in viewport coordinate system
    relative_x = world_pos[0] - camera_pos[0]
    relative_y = world_pos[1] - camera_pos[1]
    
    # Viewport coordinate (from center)
    viewport_x = relative_x + VIEWPORT_CENTER[0]
    viewport_y = relative_y + VIEWPORT_CENTER[1]
    
    # Screen coordinate
    screen_x = viewport_x + CONTAINER_OFFSET[0]
    screen_y = viewport_y + CONTAINER_OFFSET[1]
    
    return (screen_x, screen_y)

def is_visible(screen_pos, margin=50):
    """Check if screen position is visible in viewport (with margin)"""
    # Visible range: (140, 50) to (640, 400)
    # With margin, consider visible if roughly in range
    min_x = CONTAINER_OFFSET[0] - margin
    max_x = CONTAINER_OFFSET[0] + VIEWPORT_SIZE[0] + margin
    min_y = CONTAINER_OFFSET[1] - margin
    max_y = CONTAINER_OFFSET[1] + VIEWPORT_SIZE[1] + margin
    
    return (min_x <= screen_pos[0] <= max_x and 
            min_y <= screen_pos[1] <= max_y)

# Generate hardcoded coordinates for each camera view
print("# Hardcoded node screen positions for each camera view")
print("var node_screen_positions_by_camera: Dictionary = {")

for camera_name, camera_pos in cameras.items():
    print(f"\t\"{camera_name}\": {{")
    
    visible_nodes = {}
    for node_id, world_pos in nodes_world_pos.items():
        screen_pos = calculate_screen_pos(world_pos, camera_pos)
        if is_visible(screen_pos, margin=100):  # Include nodes slightly outside
            visible_nodes[node_id] = screen_pos
            print(f"\t\t\"{node_id}\": Vector2({screen_pos[0]}, {screen_pos[1]}),")
    
    print("\t},")

print("}")

# Also generate which nodes are visible in each camera view
print("\n# Visible nodes per camera view")
print("var visible_nodes_per_camera: Dictionary = {")
for camera_name, camera_pos in cameras.items():
    visible = []
    for node_id, world_pos in nodes_world_pos.items():
        screen_pos = calculate_screen_pos(world_pos, camera_pos)
        if is_visible(screen_pos, margin=100):
            visible.append(node_id)
    
    print(f"\t\"{camera_name}\": {visible},")

print("}")

# Print coordinate mapping for debugging
print("\n# Detailed coordinate mapping for verification")
print("# Format: camera_name -> node_id: (world) -> (screen)")
for camera_name, camera_pos in cameras.items():
    print(f"\n# {camera_name.upper()} camera at {camera_pos}")
    for node_id, world_pos in nodes_world_pos.items():
        screen_pos = calculate_screen_pos(world_pos, camera_pos)
        visible = "✓" if is_visible(screen_pos, margin=100) else "✗"
        print(f"#  {visible} {node_id:20} {str(world_pos):15} -> {str(screen_pos):15}")
