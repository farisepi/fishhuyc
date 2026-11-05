// Pulsing outline that follows the sprite's own pixels (for "can be inspected" objects).
// active = 0 -> the sprite is drawn exactly as usual.
shader_type canvas_item;

uniform float active = 0.0;
uniform vec4 outline_color : source_color = vec4(1.0, 0.85, 0.3, 1.0);
uniform float width = 1.0;      // in texture pixels
uniform float glow = 0.24;      // how much the sprite itself brightens

// 1 inside the texture, 0 outside (samplers can't be passed to functions on the
// Compatibility renderer, so the lookups stay inside fragment()).
float inside(vec2 uv) {
	return step(0.0, uv.x) * step(0.0, uv.y) * step(uv.x, 1.0) * step(uv.y, 1.0);
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
