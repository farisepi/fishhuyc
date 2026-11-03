// Pixel-art underwater overlay for the aquarium tank (ColorRect covering the water).
// Tints with depth, draws a moving caustic web, slanted god rays from the surface,
// a wobbling surface line and a faint glass glare. Unshaded so CanvasModulate does not kill it.
shader_type canvas_item;
render_mode unshaded;

uniform vec2 rect_size = vec2(640.0, 330.0);
uniform float pixel_size = 2.0;
uniform vec4 shallow_color : source_color = vec4(0.10, 0.32, 0.42, 1.0);
uniform vec4 deep_color : source_color = vec4(0.01, 0.05, 0.10, 1.0);
uniform float tint_alpha_top = 0.18;
uniform float tint_alpha_bottom = 0.42;
uniform vec4 caustic_color : source_color = vec4(0.55, 0.95, 1.0, 1.0);
uniform float caustic_strength = 0.30;
uniform float caustic_scale = 72.0;     // size of caustic cells in world units
uniform vec4 ray_color : source_color = vec4(0.65, 0.90, 1.0, 1.0);
uniform float ray_strength = 0.16;
uniform float surface_y = 0.11;        // UV y of the water surface line
uniform float glare_strength = 0.06;
uniform float speed = 1.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

vec2 hash2(vec2 p) {
	return vec2(hash(p), hash(p + 19.19));
}

// distance to the nearest cell border of an animated voronoi -> thin bright web
float caustic_web(vec2 p, float t) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float d1 = 8.0;
	float d2 = 8.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 g = vec2(float(x), float(y));
			vec2 o = hash2(i + g);
			o = 0.5 + 0.42 * sin(t + 6.2831 * o);
			float d = length(g + o - f);
			if (d < d1) { d2 = d1; d1 = d; }
			else if (d < d2) { d2 = d; }
		}
	}
	return d2 - d1;
}

void fragment() {
	vec2 px = floor(UV * rect_size / pixel_size);
	vec2 wp = px * pixel_size;                 // local pixel position in world units
	vec2 uv = wp / rect_size;
	float t = TIME * speed;

	// depth tint
	float depth = clamp((uv.y - surface_y) / (1.0 - surface_y), 0.0, 1.0);
	vec3 col = mix(shallow_color.rgb, deep_color.rgb, depth);
	float alpha = mix(tint_alpha_top, tint_alpha_bottom, depth);

	// caustics: two layers of voronoi web, strongest near the surface and on the bottom sand
	vec2 cp = wp / caustic_scale;
	float w1 = caustic_web(cp + vec2(t * 0.07, t * 0.05), t * 0.9);
	float w2 = caustic_web(cp * 1.7 + vec2(-t * 0.05, t * 0.08), t * 1.3 + 2.0);
	float web = (1.0 - smoothstep(0.02, 0.22, w1)) * 0.7 + (1.0 - smoothstep(0.02, 0.16, w2)) * 0.4;
	// patchy: light gathers in drifting pools instead of a uniform net
	float pool = 0.5 + 0.5 * sin(wp.x * 0.011 + t * 0.21) * sin(wp.y * 0.017 - t * 0.17 + wp.x * 0.004);
	web *= smoothstep(0.15, 0.85, pool);
	float cfade = mix(1.0, 0.35, smoothstep(0.0, 0.7, depth)) + smoothstep(0.82, 1.0, depth) * 0.6;
	float c = floor(web * cfade * 4.0) / 4.0 * caustic_strength;
	if (uv.y < surface_y) c = 0.0;

	// god rays: slanted moving shafts that fade with depth
	float slant = uv.x * rect_size.x + uv.y * rect_size.y * 0.45;
	float rays = sin(slant * 0.030 + t * 0.35) * sin(slant * 0.057 - t * 0.22 + 1.3);
	rays = smoothstep(0.35, 0.95, rays) * (1.0 - depth) * ray_strength;
	if (uv.y < surface_y) rays = 0.0;
	rays = floor(rays * 12.0) / 12.0;

	// surface line with small waves
	float wave = surface_y * rect_size.y + sin(wp.x * 0.06 + t * 1.6) * 2.0 + sin(wp.x * 0.13 - t * 1.1) * 1.0;
	float sd = wp.y - floor(wave / pixel_size) * pixel_size;
	float surface = 0.0;
	if (sd >= 0.0 && sd < pixel_size) surface = 0.55;
	else if (sd >= pixel_size && sd < pixel_size * 3.0) surface = 0.18;
	if (wp.y < wave) { alpha *= 0.25; }        // air above the water line

	// faint diagonal glare on the front glass
	float g = fract((uv.x * 0.9 - uv.y * 0.55) * 1.6 + 0.12);
	float glare = (step(0.06, g) - step(0.11, g) + (step(0.15, g) - step(0.165, g)) * 0.6) * glare_strength;

	vec3 light = caustic_color.rgb * c + ray_color.rgb * rays + vec3(0.8, 0.95, 1.0) * (surface + glare);
	float la = max(max(c, rays), surface + glare);
	col = col + light;
	alpha = clamp(alpha + la * 0.9, 0.0, 1.0);
	COLOR = vec4(col, alpha);
}
