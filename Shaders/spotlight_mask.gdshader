shader_type canvas_item;

uniform vec4 dim_color : source_color = vec4(0.0, 0.0, 0.0, 0.72);
uniform vec2 viewport_size = vec2(640.0, 400.0);
uniform vec2 highlight_center_px = vec2(320.0, 200.0);
uniform float highlight_radius_px = 96.0;
uniform float highlight_softness_px = 48.0;
uniform float mask_alpha : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec2 fragment_px = SCREEN_UV * viewport_size;
	float distance_to_center = distance(fragment_px, highlight_center_px);
	float inner_edge = max(highlight_radius_px - highlight_softness_px, 0.0);
	float outer_edge = highlight_radius_px + highlight_softness_px;
	float fade = smoothstep(inner_edge, outer_edge, distance_to_center);
	COLOR = vec4(dim_color.rgb, dim_color.a * fade * mask_alpha);
}