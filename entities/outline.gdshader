shader_type canvas_item;

uniform vec3 line_color: source_color = vec3(1.0);
uniform int line_thickness: hint_range(0, 10) = 1;

void fragment() {
	vec2 size = TEXTURE_PIXEL_SIZE * float(line_thickness);
	float line_alpha = 0.0;
	for (float i = -size.x; i <= size.x; i += TEXTURE_PIXEL_SIZE.x) {
		for (float j = -size.y; j <= size.y; j += TEXTURE_PIXEL_SIZE.y) {
			line_alpha += texture(TEXTURE, UV + vec2(i, j)).a;
		}
	}
	vec4 outline = vec4(line_color, min(line_alpha, 1.0));
	COLOR = mix(outline, COLOR, COLOR.a);
}
