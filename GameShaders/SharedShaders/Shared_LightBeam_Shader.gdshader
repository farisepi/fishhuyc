// Volumetric light cone for hanging lamps. ColorRect: apex at the top centre,
// set rect_size to the ColorRect size. Additive and unshaded, so it glows in dark scenes.
shader_type canvas_item;
render_mode blend_add, unshaded;

uniform vec4 light_color : source_color = vec4(1.0, 0.78, 0.45, 1.0);
uniform float intensity = 0.28;
uniform float top_width = 0.10;      // cone width at the top (fraction of rect width)
uniform float bottom_width = 0.95;   // cone width at the bottom
uniform float falloff = 1.4;
uniform vec2 rect_size = vec2(240.0, 300.0);
uniform float pixel_size = 3.0;
uniform float flicker_amount = 0.10;
uniform float flicker_speed = 6.0;
uniform float dropout_chance = 0.012; // chance per tick that the lamp stutters
uniform float seed = 0.0;
uniform float dust_density = 0.012;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void fragment() {
	vec2 px = floor(UV * rect_size / pixel_size);
	vec2 uv = (px * pixel_size + pixel_size * 0.5) / rect_size;

	float half_w = mix(top_width, bottom_width, uv.y) * 0.5;
	float dx = abs(uv.x - 0.5);
	float cone = 1.0 - smoothstep(half_w * 0.45, half_w, dx);
	float core = 1.0 - smoothstep(0.0, half_w * 0.5, dx);
	float fall = pow(clamp(1.0 - uv.y, 0.0, 1.0), falloff);

	float t = TIME * flicker_speed + seed * 13.7;
	float flick = 1.0 - flicker_amount * (0.5 + 0.5 * sin(t) * sin(t * 2.3 + 1.7));
	float tick = floor(TIME * 10.0);
	if (hash(vec2(tick, seed)) < dropout_chance) flick *= 0.35;

	float a = (cone * 0.75 + core * 0.35) * fall * intensity * flick;

	// slowly drifting dust motes inside the beam
	vec2 dp = px + vec2(floor(sin(TIME * 0.4 + px.y * 0.05) * 2.0), floor(TIME * 4.0));
	if (hash(floor(dp)) < dust_density) a += cone * 0.35 * intensity * 3.0 * (0.4 + fall);

	// banded brightness for a pixel-art look
	a = floor(a * 14.0) / 14.0;
	COLOR = vec4(light_color.rgb, a);
}
