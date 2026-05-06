extends Control
class_name TooltipPanel

var label: Label
var root_hbox: Control
var inventory_vbox: VBoxContainer
var tween: Tween
var is_visible_tooltip: bool = false

const FADE_DURATION = 0.15
const PANEL_MARGIN = 10
const SLOT_SIZE = Vector2(32, 32)

const RESOURCE_ICONS := {
	"potato": "res://Sprites/potato.png",
	"llama": "res://Sprites/llama.png",
	"corn": "res://Sprites/corn.png",
	"quinoa": "res://Sprites/quinoa.png",
	"coca": "res://Sprites/coca.png"
}

func _ready() -> void:
	root_hbox = get_node_or_null("RootHBox") as Control
	label = get_node_or_null("RootHBox/Label") as Label
	if label == null:
		label = get_node_or_null("Label")
	inventory_vbox = get_node_or_null("RootHBox/InventoryVBox") as VBoxContainer
	if inventory_vbox == null:
		inventory_vbox = get_node_or_null("InventoryVBox") as VBoxContainer
	_configure_label()
	if inventory_vbox:
		inventory_vbox.visible = false

	hide()
	modulate.a = 0.0

func _configure_label() -> void:
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = ""
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

func _process(_delta: float) -> void:
	if is_visible_tooltip and visible:
		_update_position_to_mouse()

func show_tooltip(text: String, position_override: Vector2 = Vector2.ZERO) -> void:
	if tween:
		tween.kill()

	label.text = text
	if inventory_vbox:
		inventory_vbox.visible = false
	_clear_inventory_slots()

	await _show_with_layout(position_override)

func show_unit_tooltip_with_inventory(text: String, inventory: Dictionary, capacity: int = 5, position_override: Vector2 = Vector2.ZERO) -> void:
	if tween:
		tween.kill()

	label.text = text
	if inventory_vbox:
		inventory_vbox.visible = true
	_rebuild_inventory_slots(inventory, capacity)

	await _show_with_layout(position_override)

func _show_with_layout(position_override: Vector2) -> void:
	await get_tree().process_frame

	is_visible_tooltip = position_override == Vector2.ZERO
	if is_visible_tooltip:
		_update_position_to_mouse()
	else:
		global_position = position_override

	show()
	tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, FADE_DURATION)

func _rebuild_inventory_slots(inventory: Dictionary, capacity: int) -> void:
	_clear_inventory_slots()

	var filled_types: Array[String] = []
	for key in inventory.keys():
		if str(key) in RESOURCE_ICONS:
			filled_types.append(str(key))

	filled_types.sort()

	for resource_type in filled_types:
		var amount := int(inventory[resource_type])
		inventory_vbox.add_child(_create_resource_slot(resource_type, amount))

	var empty_count: int = capacity - filled_types.size()
	if empty_count < 0:
		empty_count = 0
	for i in range(empty_count):
		inventory_vbox.add_child(_create_empty_slot())

func _create_resource_slot(resource_type: String, amount: int) -> Control:
	var slot := Panel.new()
	slot.custom_minimum_size = SLOT_SIZE
	slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.11, 0.11, 0.11, 0.92)
	style.border_color = Color(0.75, 0.75, 0.75, 0.9)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	slot.add_theme_stylebox_override("panel", style)

	var icon := TextureRect.new()
	icon.anchor_left = 0.0
	icon.anchor_top = 0.0
	icon.anchor_right = 1.0
	icon.anchor_bottom = 1.0
	icon.offset_left = 0
	icon.offset_top = 0
	icon.offset_right = 0
	icon.offset_bottom = 0
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var icon_path: String = RESOURCE_ICONS[resource_type]
	if ResourceLoader.exists(icon_path):
		icon.texture = ResourceLoader.load(icon_path)

	slot.add_child(icon)

	var count_label := Label.new()
	count_label.anchor_left = 0.0
	count_label.anchor_top = 0.0
	count_label.anchor_right = 1.0
	count_label.anchor_bottom = 1.0
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	count_label.offset_left = 0
	count_label.offset_top = 0
	count_label.offset_right = -1
	count_label.offset_bottom = -1
	count_label.text = str(amount)
	count_label.add_theme_color_override("font_color", Color.WHITE)
	count_label.add_theme_font_size_override("font_size", 10)
	count_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	count_label.add_theme_constant_override("shadow_outline_size", 1)
	count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(count_label)

	return slot

func _create_empty_slot() -> Control:
	var slot := Panel.new()
	slot.custom_minimum_size = SLOT_SIZE
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.08, 0.45)
	style.border_color = Color(0.55, 0.55, 0.55, 0.35)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	slot.add_theme_stylebox_override("panel", style)

	return slot

func _clear_inventory_slots() -> void:
	if inventory_vbox == null:
		return
	for child in inventory_vbox.get_children():
		child.queue_free()

func _update_position_to_mouse() -> void:
	if not visible:
		return

	var mouse_pos = get_global_mouse_position()
	var panel_size = size
	var final_position = mouse_pos - Vector2(0, panel_size.y)
	var screen_size = get_viewport_rect().size

	if final_position.x + panel_size.x > screen_size.x:
		final_position.x = screen_size.x - panel_size.x - PANEL_MARGIN
	if final_position.x < 0:
		final_position.x = PANEL_MARGIN
	if final_position.y < 0:
		final_position.y = PANEL_MARGIN
	if final_position.y + panel_size.y > screen_size.y:
		final_position.y = screen_size.y - panel_size.y - PANEL_MARGIN

	global_position = final_position

func hide_tooltip() -> void:
	is_visible_tooltip = false
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, FADE_DURATION)
	tween.tween_callback(func(): hide())

func hide_immediately() -> void:
	is_visible_tooltip = false
	if tween:
		tween.kill()
	modulate.a = 0.0
	hide()
