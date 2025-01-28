shader_type canvas_item;
render_mode light_only;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

void fragment() {
	COLOR = texture(screen_texture, SCREEN_UV);
}
