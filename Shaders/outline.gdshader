shader_type canvas_item;

uniform vec4 line_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float line_thickness : hint_range(0, 10) = 1.0;
uniform bool is_hovered = false;

void fragment() {
    vec4 color = texture(TEXTURE, UV);
    
    if (is_hovered && color.a == 0.0) {
        vec2 size = TEXTURE_PIXEL_SIZE * line_thickness;
        
        float a = texture(TEXTURE, UV + vec2(0.0, size.y)).a;
        a += texture(TEXTURE, UV + vec2(0.0, -size.y)).a;
        a += texture(TEXTURE, UV + vec2(size.x, 0.0)).a;
        a += texture(TEXTURE, UV + vec2(-size.x, 0.0)).a;
        
        // optional: corners for a thicker outline
        a += texture(TEXTURE, UV + vec2(size.x, size.y)).a;
        a += texture(TEXTURE, UV + vec2(-size.x, size.y)).a;
        a += texture(TEXTURE, UV + vec2(size.x, -size.y)).a;
        a += texture(TEXTURE, UV + vec2(-size.x, -size.y)).a;
        
        a = min(a, 1.0);
        
        if (a > 0.0) {
            COLOR = vec4(line_color.rgb, line_color.a * a);
        } else {
            COLOR = color;
        }
    } else {
        COLOR = color;
    }
}
