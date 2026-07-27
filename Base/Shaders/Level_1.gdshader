shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
	vec4 col = texture(SCREEN_TEXTURE, SCREEN_UV);
	
	// Слегка затемняем
	col.rgb *= 0.6;
	
	// Сине-зелёный подводный оттенок
	col.r *= 0.7;
	col.g *= 0.95;
	col.b *= 1.3;
	
	// Свет с поверхности
	float surface_light = 1.0 - SCREEN_UV.y;
	col.rgb += vec3(0.08, 0.15, 0.2) * surface_light;
	
	// Лёгкая виньетка
	float vignette = 1.0 - length(SCREEN_UV - 0.5) * 0.5;
	col.rgb *= vignette;
	
	COLOR = col;
}