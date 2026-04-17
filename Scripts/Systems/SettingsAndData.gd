extends Node
class_name SettingsAndData

# Village Population Configuration
# Based on historical importance and modern city sizes
# Population is scaled down (e.g., 2200 → 220)

const VILLAGE_POPULATIONS = {
	# Capital - Most important, historically major city
	"cusco": 300,  # Historical capital, largest settlement
	
	# High Altitude Villages (Mountain strongholds)
	"tinta": 150,  # Birthplace of rebellion, major agricultural center
	"tungasuca": 120,  # Rebellion center under Tupac Amaru II
	"pampamarca": 80,  # Fortress location
	"sicuani": 95,  # Eastern highland pass
	"ocongate": 85,  # Highland town
	
	# Medium Altitude Villages (Mixed agriculture)
	"urcos": 110,  # Corn farming center
	"quiquijana": 100,  # Agricultural zone
	"andahuaylillas": 130,  # Ancient community, important settlement
	
	# Low Altitude Villages (Jungle/lowland transitions)
	"paucartambo": 75,  # Gateway to jungle
	"marcapata": 70,  # Lowland transition
	"pilcopata": 60,  # Amazon frontier settlement
	"challabamba": 65,  # Lowland settlement
}

# Resource Types by Altitude
const ALTITUDE_RESOURCES = {
	"high": ["potato", "llama"],      # High altitude: Potato, Llama
	"medium": ["corn", "quinoa"],     # Medium altitude: Corn, Quinoa
	"low": ["coca"]                   # Low altitude: Coca
}

# Initial Resources Configuration
# Format: {"village_id": ["resource1", "resource2"]}
const INITIAL_RESOURCES = {
	# High Altitude (2+ resources if pop >= 100, otherwise 1)
	"tinta": ["potato", "llama"],          # 150 pop → 2 resources
	"tungasuca": ["potato", "llama"],      # 120 pop → 2 resources
	"pampamarca": ["potato"],              # 80 pop → 1 resource
	"sicuani": ["llama"],                  # 95 pop → 1 resource
	"ocongate": ["potato"],                # 85 pop → 1 resource
	
	# Medium Altitude
	"cusco": ["corn", "quinoa"],           # 300 pop → 2 resources
	"urcos": ["corn"],                     # 110 pop → 1 resource (only corn)
	"quiquijana": ["quinoa"],              # 100 pop → 1 resource (only quinoa)
	"andahuaylillas": ["corn", "quinoa"],  # 130 pop → 2 resources
	
	# Low Altitude (only coca available)
	"paucartambo": ["coca"],               # 75 pop → 1 resource
	"marcapata": ["coca"],                 # 70 pop → 1 resource
	"pilcopata": ["coca"],                 # 60 pop → 1 resource
	"challabamba": ["coca"],               # 65 pop → 1 resource
}

# Resource Production Speed: population / 100 = base resources per turn
# Then multiplied by resource type multiplier
# E.g. 150 pop potato → (150/100) * 2.0 = 3.0 resources/turn
const RESOURCE_PRODUCTION_RATES = {
	# High Altitude
	"tinta": 1.5,          # 150 / 100
	"tungasuca": 1.2,      # 120 / 100
	"pampamarca": 0.8,     # 80 / 100
	"sicuani": 0.95,       # 95 / 100
	"ocongate": 0.85,      # 85 / 100
	
	# Medium Altitude
	"cusco": 3.0,          # 300 / 100
	"urcos": 1.1,          # 110 / 100
	"quiquijana": 1.0,     # 100 / 100
	"andahuaylillas": 1.3, # 130 / 100
	
	# Low Altitude
	"paucartambo": 0.75,   # 75 / 100
	"marcapata": 0.7,      # 70 / 100
	"pilcopata": 0.6,      # 60 / 100
	"challabamba": 0.65,   # 65 / 100
}

# Resource Type Multipliers for production speed
# Applied to base production rate to get final production speed
const RESOURCE_TYPE_MULTIPLIERS = {
	"potato": 2.0,   # Potatoes grow fast
	"llama": 0.5,    # Llamas are harder to breed
	"corn": 1.0,     # Standard corn
	"quinoa": 1.0,   # Standard quinoa
	"coca": 1.0      # Standard coca
}

# Enemy Units Garrison Configuration
# Population <= 100: 1 enemy unit
# Population > 100: 2 enemy units
# Cusco special: 4 enemy units
const ENEMY_GARRISON = {
	"tinta": 2,            # 150 > 100
	"tungasuca": 2,        # 120 > 100
	"pampamarca": 1,       # 80 <= 100
	"sicuani": 1,          # 95 <= 100
	"ocongate": 1,         # 85 <= 100
	
	"cusco": 4,            # Special case
	"urcos": 2,            # 110 > 100
	"quiquijana": 2,       # 100 > 100
	"andahuaylillas": 2,   # 130 > 100
	
	"paucartambo": 1,      # 75 <= 100
	"marcapata": 1,        # 70 <= 100
	"pilcopata": 1,        # 60 <= 100
	"challabamba": 1,      # 65 <= 100
}

# Camera distribution (corrected based on actual game layout)
const CAMERA_NODES = {
	"tinta": ["tinta", "tungasuca", "pampamarca", "sicuani", "ocongate"],
	"andahuaylillas": ["andahuaylillas", "cusco", "urcos", "ocongate", "quiquijana"],
	"marcapata": ["marcapata"],
	"jungle": ["paucartambo", "pilcopata", "challabamba"]
}

# Transport time configuration
# Same camera: 2 turns
# Different camera: 4 turns (no stacking)
const TRANSPORT_TIME = {
	"same_camera": 2,
	"different_camera": 4
}

func get_village_population(village_id: String) -> int:
	"""Get population for a specific village"""
	if village_id in VILLAGE_POPULATIONS:
		return VILLAGE_POPULATIONS[village_id]
	return 0

func get_all_populations() -> Dictionary:
	"""Return all village populations"""
	return VILLAGE_POPULATIONS.duplicate()

func get_initial_resources(village_id: String) -> Array:
	"""Get initial resources for a village"""
	if village_id in INITIAL_RESOURCES:
		return INITIAL_RESOURCES[village_id].duplicate()
	return []

func get_production_rate(village_id: String) -> float:
	"""Get production rate (resources per turn) for a village"""
	if village_id in RESOURCE_PRODUCTION_RATES:
		return RESOURCE_PRODUCTION_RATES[village_id]
	return 0.0

func get_resource_type_multiplier(resource_type: String) -> float:
	"""Get production multiplier for a specific resource type"""
	return RESOURCE_TYPE_MULTIPLIERS.get(resource_type, 1.0)

func get_enemy_garrison_count(village_id: String) -> int:
	"""Get number of enemy units garrisoned at a village"""
	if village_id in ENEMY_GARRISON:
		return ENEMY_GARRISON[village_id]
	return 0

func get_camera_for_village(village_id: String) -> String:
	"""Get which camera view a village belongs to"""
	for camera in CAMERA_NODES:
		if village_id in CAMERA_NODES[camera]:
			return camera
	return ""

func get_transport_time(from_village: String, to_village: String) -> int:
	"""Calculate transport time between two villages"""
	var from_camera = get_camera_for_village(from_village)
	var to_camera = get_camera_for_village(to_village)
	
	if from_camera == to_camera:
		return TRANSPORT_TIME["same_camera"]
	else:
		return TRANSPORT_TIME["different_camera"]

func get_villages_in_camera(camera_name: String) -> Array:
	"""Get all villages in a specific camera view"""
	if camera_name in CAMERA_NODES:
		return CAMERA_NODES[camera_name].duplicate()
	return []

func get_altitude_for_village(village_id: String) -> String:
	"""Get altitude classification for a village"""
	# High altitude villages
	var high_altitude = ["tinta", "tungasuca", "pampamarca", "sicuani", "ocongate"]
	if village_id in high_altitude:
		return "high"
	
	# Low altitude villages
	var low_altitude = ["paucartambo", "marcapata", "pilcopata", "challabamba"]
	if village_id in low_altitude:
		return "low"
	
	# Medium altitude (default for the rest)
	return "medium"

func get_camera_for_node(village_name: String) -> String:
	"""Get which camera view a village node belongs to (wrapper for get_camera_for_village)"""
	return get_camera_for_village(village_name.to_lower())
