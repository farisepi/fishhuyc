shader_type canvas_item;

uniform vec4 glint_color : source_color = vec4(1.0, 0.78, 0.45, 1.0);
uniform vec4 rim_color : source_color = vec4(1.0, 0.55, 0.2, 1.0);
uniform float glint_period = 5.5;
uniform float glint_width = 0.10;
uniform float glint_strength = 0.55;
uniform float grain_strength = 0.06;
uniform float rim_strength = 0.35;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	if (c.a < 0.01) {
		discard;
	}
	vec2 tex_px = 1.0 / TEXTURE_PIXEL_SIZE;
	vec2 cell = floor(UV * tex_px);
	float lum = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	float ph = fract(TIME / glint_period) * 1.6 - 0.3;
	float d = (UV.x + UV.y * 0.35) / 1.35 - ph;
	float band = smoothstep(glint_width, 0.0, abs(d));
	c.rgb += glint_color.rgb * band * glint_strength * (0.35 + lum);
	float g = hash(cell);
	c.rgb += (g - 0.5) * grain_strength;
	vec2 to_c = normalize(vec2(0.5) - UV + 1e-5) * TEXTURE_PIXEL_SIZE * 2.0;
	float inner = 1.0 - texture(TEXTURE, UV + to_c).a;
	c.rgb += rim_color.rgb * inner * rim_strength * 0.8;
	COLOR = c;
}
