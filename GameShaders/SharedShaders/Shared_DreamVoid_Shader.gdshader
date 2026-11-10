// The dream: an empty white place, as if the fish had died. Soft white with a breath of blue,
// a faint horizon where the floor would be, the floor a little greyer with a soft line, slow
// motes of light drifting up and a very slow brightness "breath". Drawn in world space on a big
// rect behind everything (the factory Background swaps to this while dreaming).
shader_type canvas_item;

uniform float floor_y = 380.0;
uniform float pixel = 2.0;
uniform float fade = 1.0;     // 0 = the old picture shows through (not used by the void itself)
varying vec2 wp;

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 w = floor(wp / pixel) * pixel;
	float dy = w.y - floor_y;
	float breath = 0.006 * sin(TIME * 0.6);
	// sky of the void: whiter near the horizon, a touch bluer far up
	vec3 hi = vec3(0.90, 0.93, 0.975);
	vec3 lo = vec3(0.985, 0.99, 1.0);
	vec3 c = mix(hi, lo, exp(-abs(dy) / 260.0));
	if (dy > 0.0) {
		// the floor: slightly greyer, darker just under the line (a soft contact shadow)
		c = mix(vec3(0.93, 0.945, 0.965), vec3(0.88, 0.9, 0.93), clamp(dy / 300.0, 0.0, 1.0));
		c -= 0.06 * exp(-dy / 10.0);
		// faint tiles of light on the floor, far apart
		float tx = mod(w.x + 40.0, 160.0);
		c += 0.012 * step(tx, 2.0) * exp(-dy / 120.0);
	}
	// the horizon line
	c -= 0.05 * exp(-abs(dy) / 1.5);
	// motes of light drifting slowly up and sideways
	for (int i = 0; i < 2; i++) {
		float sz = i == 0 ? 36.0 : 58.0;
		vec2 q = w + vec2(TIME * (6.0 + float(i) * 4.0), TIME * (14.0 + float(i) * 9.0));
		vec2 cell = floor(q / sz);
		float h = hash(cell + float(i) * 13.0);
		if (h > 0.86) {
			vec2 f = mod(q, sz);
			vec2 at = vec2(hash(cell + 2.0), hash(cell + 5.0)) * (sz - 6.0) + 3.0;
			float d = length(f - at);
			float tw = 0.5 + 0.5 * sin(TIME * (1.0 + h * 2.0) + h * 30.0);
			c -= vec3(0.10, 0.08, 0.04) * step(d, pixel * 0.9) * tw * 0.6;   // tiny dark-gold specks
			c += vec3(0.02, 0.025, 0.03) * smoothstep(8.0, 0.0, d) * tw;
		}
	}
	c += breath;
	COLOR = vec4(clamp(c, 0.0, 1.0), 1.0);
}
