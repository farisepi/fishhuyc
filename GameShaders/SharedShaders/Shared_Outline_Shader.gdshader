shader_type canvas_item;

uniform float active = 0.0;
uniform vec4 outline_color : source_color = vec4(1.0, 0.85, 0.3, 1.0);
uniform float width = 1.0;
uniform float glow = 0.24;
uniform float wrap_x = 0.0;

float inside(vec2 uv) {
	float in_x = wrap_x > 0.5 ? 1.0 : step(0.0, uv.x) * step(uv.x, 1.0);
	return in_x * step(0.0, uv.y) * step(uv.y, 1.0);
}

void fragment() {
	if (active > 0.5) {
		float pulse = 0.6 + 0.4 * sin(TIME * 5.0);
		vec4 tex = texture(TEXTURE, UV);
		if (tex.a < 0.1) {
			vec2 px = TEXTURE_PIXEL_SIZE * width;
			float a = 0.0;
			a = max(a, texture(TEXTURE, UV + vec2(px.x, 0.0)).a * inside(UV + vec2(px.x, 0.0)));
			a = max(a, texture(TEXTURE, UV - vec2(px.x, 0.0)).a * inside(UV - vec2(px.x, 0.0)));
			a = max(a, texture(TEXTURE, UV + vec2(0.0, px.y)).a * inside(UV + vec2(0.0, px.y)));
			a = max(a, texture(TEXTURE, UV - vec2(0.0, px.y)).a * inside(UV - vec2(0.0, px.y)));
			a = max(a, texture(TEXTURE, UV + px).a * inside(UV + px));
			a = max(a, texture(TEXTURE, UV - px).a * inside(UV - px));
			a = max(a, texture(TEXTURE, UV + vec2(px.x, -px.y)).a * inside(UV + vec2(px.x, -px.y)));
			a = max(a, texture(TEXTURE, UV + vec2(-px.x, px.y)).a * inside(UV + vec2(-px.x, px.y)));
			if (a > 0.1) {
				COLOR = vec4(outline_color.rgb * (1.6 + 0.8 * pulse), min(1.0, outline_color.a * (0.75 + 0.25 * pulse)));
			}
		} else {
			COLOR.rgb += outline_color.rgb * glow * pulse;
		}
	}
}
