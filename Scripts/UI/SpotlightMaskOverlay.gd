extends CanvasLayer
class_name SpotlightMaskOverlay

@export var dim_alpha: float = 0.72
@export var highlight_radius_px: float = 48.0
@export var highlight_softness_px: float = 16.0
@export var block_input: bool = true

var mask_rect: ColorRect
var mask_material: ShaderMaterial
var center_tween: Tween
var fade_tween: Tween

func _ready() -> void:
	mask_rect = get_node_or_null("Mask") as ColorRect
	if not mask_rect:
		push_error("SpotlightMaskOverlay: Missing Mask ColorRect")
		return

	if mask_rect.material is ShaderMaterial:
		mask_material = mask_rect.material as ShaderMaterial
	else:
		mask_material = ShaderMaterial.new()
		mask_material.shader = load("res://Shaders/spotlight_mask.gdshader")
		mask_rect.material = mask_material

	mask_rect.mouse_filter = Control.MOUSE_FILTER_STOP if block_input else Control.MOUSE_FILTER_IGNORE
	mask_rect.visible = false
	mask_rect.modulate.a = 1.0
	if mask_rect.gui_input.is_connected(_on_mask_rect_gui_input):
		mask_rect.gui_input.disconnect(_on_mask_rect_gui_input)
	mask_rect.gui_input.connect(_on_mask_rect_gui_input)
	_apply_shader_parameters()
	var viewport = get_viewport()
	if viewport and not viewport.size_changed.is_connected(_apply_shader_parameters):
		viewport.size_changed.connect(_apply_shader_parameters)

func _apply_shader_parameters() -> void:
	if not mask_material:
		return

	var viewport_size = get_viewport().get_visible_rect().size
	mask_material.set_shader_parameter("dim_color", Color(0.0, 0.0, 0.0, dim_alpha))
	mask_material.set_shader_parameter("viewport_size", viewport_size)
	mask_material.set_shader_parameter("highlight_radius_px", highlight_radius_px)
	mask_material.set_shader_parameter("highlight_softness_px", highlight_softness_px)

	var default_center = viewport_size * 0.5
	mask_material.set_shader_parameter("highlight_center_px", default_center)

func show_mask() -> void:
	if mask_rect:
		if fade_tween:
			fade_tween.kill()
			fade_tween = null
		mask_rect.visible = true
		# When showing, restore mouse_filter according to block_input so mask can block input if intended
		mask_rect.mouse_filter = Control.MOUSE_FILTER_STOP if block_input else Control.MOUSE_FILTER_IGNORE
		if mask_material:
			mask_material.set_shader_parameter("mask_alpha", 1.0)
		_apply_shader_parameters()

func hide_mask(animate: bool = false, duration: float = 0.5) -> void:
	if center_tween:
		center_tween.kill()
		center_tween = null
	if fade_tween:
		fade_tween.kill()
		fade_tween = null
	if not mask_rect:
		return

	if animate:
		# Allow underlying UI to receive input during the fade-out by making mask ignore pointer events
		mask_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fade_tween = create_tween()
		fade_tween.tween_property(mask_material, "shader_parameter/mask_alpha", 0.0, duration).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
		fade_tween.tween_callback(func():
			mask_rect.visible = false
			mask_material.set_shader_parameter("mask_alpha", 1.0)
		)
	else:
		mask_rect.visible = false
		# Ensure mask no longer intercepts input
		mask_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mask_material.set_shader_parameter("mask_alpha", 1.0)
func set_highlight_position(screen_position: Vector2, animate: bool = false, duration: float = 0.25) -> void:
	show_mask()

	if center_tween:
		center_tween.kill()
		center_tween = null

	if animate:
		center_tween = create_tween()
		center_tween.tween_method(_set_highlight_center_px, _get_current_center_px(), screen_position, duration)
	else:
		_set_highlight_center_px(screen_position)

func focus_node(node: VillageNode, animate: bool = false, duration: float = 0.25) -> bool:
	if not node:
		return false

	var game_map = get_tree().root.get_node_or_null("Main/SubViewportContainer/SubViewport/Map") as GameMap
	if game_map:
		if game_map.current_camera_positions.has(node.node_id):
			var node_screen_position = game_map.get_node_screen_position(node)
			set_highlight_position(node_screen_position, animate, duration)
			return true

	return false

func _on_mask_rect_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		hide_mask(true, 0.5)
		get_tree().root.set_input_as_handled()

func _set_highlight_center_px(screen_position: Vector2) -> void:
	if not mask_material:
		return

	mask_material.set_shader_parameter("highlight_center_px", screen_position)

func _get_current_center_px() -> Vector2:
	if mask_material:
		var value = mask_material.get_shader_parameter("highlight_center_px")
		if value is Vector2:
			return value
	var viewport_size = get_viewport().get_visible_rect().size
	return viewport_size * 0.5
