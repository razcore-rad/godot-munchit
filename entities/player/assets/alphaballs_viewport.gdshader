shader_type canvas_item;

uniform float threshold: hint_range(0.0, 1.0, 0.01) = 0.1;
uniform vec3 color: source_color = vec3(1.0);

void fragment() {
	float alpha = texture(TEXTURE, UV).a;
	COLOR.a = step(threshold, alpha);
	COLOR.rgb = color;
}

