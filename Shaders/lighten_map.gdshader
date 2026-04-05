shader_type canvas_item;

// 将颜色变浅50%
void fragment() {
	vec4 original_color = texture(TEXTURE, UV);
	
	// 将颜色变浅：RGB值 * 0.5 + 0.5(白色的一半) = 向白色方向调整50%
	vec3 lightened = original_color.rgb * 0.5 + vec3(0.5);
	
	COLOR = vec4(lightened, original_color.a);
}
