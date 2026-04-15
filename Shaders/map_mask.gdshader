shader_type canvas_item;

uniform sampler2D mask_texture: hint_default_white;

void fragment() {
	vec4 mask_color = texture(mask_texture, UV);
	float mask_alpha = mask_color.r;
	COLOR.a *= mask_alpha;
}
