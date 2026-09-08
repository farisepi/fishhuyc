shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
	vec4 col = texture(SCREEN_TEXTURE, SCREEN_UV);
	
	col.rgb *= 0.7;
	col.r *= 0.9;
	col.b *= 1.2;
	
	float vignette = 1.0 - length(SCREEN_UV - 0.5) * 1.2;
	col.rgb *= vignette;
	
	COLOR = col;
}