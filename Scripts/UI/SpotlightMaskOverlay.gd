extends CanvasLayer
class_name SpotlightMaskOverlay

@export var dim_alpha: float = 0.72
@export var highlight_radius_px: float = 48.0
@export var highlight_softness_px: float = 16.0
@export var block_input: bool = true

var mask_rect: ColorRect
var mask_material: ShaderMaterial
var label: Label
var center_tween: Tween
var fade_tween: Tween
var on_hide_callback: Callable = Callable()
var on_click_callback: Callable = Callable()
var has_clicked_once: bool = false

func _ready() -> void:
	mask_rect = get_node_or_null("Mask") as ColorRect
	label = get_node_or_null("Label") as Label
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

func set_label_text(text: String) -> void:
	"""设置spotlight标签的文本内容"""
	if label:
		label.text = text

func show_mask() -> void:
	if mask_rect:
		if fade_tween:
			fade_tween.kill()
			fade_tween = null
		mask_rect.visible = true
		mask_rect.modulate.a = 1.0
		# When showing, restore mouse_filter according to block_input so mask can block input if intended
		mask_rect.mouse_filter = Control.MOUSE_FILTER_STOP if block_input else Control.MOUSE_FILTER_IGNORE
		if mask_material:
			mask_material.set_shader_parameter("mask_alpha", 1.0)
		if label:
			label.visible = true
			label.modulate.a = 1.0
			_update_label_position()
		_apply_shader_parameters()

func _update_label_position() -> void:
	if not label:
		return
	var center = _get_current_center_px()
	var viewport_size = get_viewport().get_visible_rect().size
	var label_size = label.size
	
	var label_pos = center + Vector2(0, -highlight_radius_px - 20)
	label_pos.x = clamp(label_pos.x - label_size.x / 2, 10, viewport_size.x - label_size.x - 10)
	label_pos.y = clamp(label_pos.y - label_size.y / 2, 10, viewport_size.y - label_size.y - 10)
	
	label.position = label_pos

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
		mask_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fade_tween = create_tween()
		fade_tween.tween_property(mask_material, "shader_parameter/mask_alpha", 0.0, duration).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
		fade_tween.tween_callback(func():
			mask_rect.visible = false
			mask_material.set_shader_parameter("mask_alpha", 1.0)
			if label:
				label.visible = false
				label.modulate.a = 1.0
			if on_hide_callback and on_hide_callback.is_valid():
				on_hide_callback.call()
		)
		if label:
			var label_tween = create_tween()
			label_tween.tween_property(label, "modulate:a", 0.0, duration).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	else:
		mask_rect.visible = false
		mask_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mask_material.set_shader_parameter("mask_alpha", 1.0)
		if label:
			label.visible = false
			label.modulate.a = 1.0
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

func move_to(screen_position: Vector2, duration: float = 0.5) -> void:
	print("DEBUG move_to: mask_rect=", mask_rect, " visible=", mask_rect.visible if mask_rect else "N/A")
	if not mask_rect or not mask_rect.visible:
		show_mask()
		_set_highlight_center_px(screen_position)
		return

	if center_tween:
		center_tween.kill()
		center_tween = null

	center_tween = create_tween()
	center_tween.set_trans(Tween.TRANS_QUART)
	center_tween.set_ease(Tween.EASE_OUT)
	center_tween.tween_method(_set_highlight_center_px, _get_current_center_px(), screen_position, duration)
	print("DEBUG move_to: started tween to ", screen_position)

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
	print("DEBUG gui_input: has_clicked_once=", has_clicked_once, " callback_valid=", on_click_callback.is_valid())
	if event is InputEventMouseButton and event.pressed:
		if not has_clicked_once and on_click_callback.is_valid():
			has_clicked_once = true
			on_click_callback.call()
			has_clicked_once = false
		else:
			print("DEBUG gui_input: going to hide_mask")
			has_clicked_once = false
			hide_mask(true, 0.5)
		get_tree().root.set_input_as_handled()

func _set_highlight_center_px(screen_position: Vector2) -> void:
	if not mask_material:
		return

	mask_material.set_shader_parameter("highlight_center_px", screen_position)
	_update_label_position()

func _get_current_center_px() -> Vector2:
	if mask_material:
		var value = mask_material.get_shader_parameter("highlight_center_px")
		if value is Vector2:
			return value
	var viewport_size = get_viewport().get_visible_rect().size
	return viewport_size * 0.5
