shader_type canvas_item;

uniform vec3 color: source_color = vec3(1.0);
uniform float threshold: hint_range(-1.0, 1.0, 0.01) = -1.0;

void fragment() {
	vec2 uv = 2.0 * (UV - vec2(0.5));
	COLOR.a = 1.0 - sqrt(uv.x * uv.x + uv.y * uv.y);
	if (threshold >= 0.0) {
		COLOR.a = step(threshold, COLOR.a);
	}
	COLOR.rgb = color;
}
