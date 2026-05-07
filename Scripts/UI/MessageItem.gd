extends PanelContainer
class_name MessageItem

# Individual message item with text and styling

@onready var label: Label = $MarginContainer/Label

func _ready() -> void:
	# Setup styling - black semi-transparent panel
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color(0, 0, 0, 0.8)  # Black with 80% opacity
	stylebox.set_corner_radius_all(4)
	stylebox.border_width_left = 1
	stylebox.border_width_top = 1
	stylebox.border_width_right = 1
	stylebox.border_width_bottom = 1
	stylebox.border_color = Color(1, 1, 1, 0.08)
	add_theme_stylebox_override("panel", stylebox)
	
	# Ensure visibility
	visible = true
	modulate.a = 1.0
	
	# Fade-in animation
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)

func set_message(text: String, msg_type: String = "info") -> void:
	"""Set the message text and type"""
	if label:
		label.text = text
		# Color based on type
		match msg_type:
			"success":
				label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))  # Light green
			"error":
				label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))  # Light red
			_:
				label.add_theme_color_override("font_color", Color.WHITE)
	
func get_message_text() -> String:
	"""Get the message text"""
	return label.text if label else ""
