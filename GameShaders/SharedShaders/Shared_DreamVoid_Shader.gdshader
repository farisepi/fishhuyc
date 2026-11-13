shader_type canvas_item;

uniform float floor_y = 380.0;
uniform float pixel = 2.0;
uniform float fade = 1.0;
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
	vec3 hi = vec3(0.90, 0.93, 0.975);
	vec3 lo = vec3(0.985, 0.99, 1.0);
	vec3 c = mix(hi, lo, exp(-abs(dy) / 260.0));
	if (dy > 0.0) {
		c = mix(vec3(0.93, 0.945, 0.965), vec3(0.88, 0.9, 0.93), clamp(dy / 300.0, 0.0, 1.0));
		c -= 0.06 * exp(-dy / 10.0);
		float tx = mod(w.x + 40.0, 160.0);
		c += 0.012 * step(tx, 2.0) * exp(-dy / 120.0);
	}
	c -= 0.05 * exp(-abs(dy) / 1.5);
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
			c -= vec3(0.10, 0.08, 0.04) * step(d, pixel * 0.9) * tw * 0.6;
			c += vec3(0.02, 0.025, 0.03) * smoothstep(8.0, 0.0, d) * tw;
		}
	}
	c += breath;
	COLOR = vec4(clamp(c, 0.0, 1.0), 1.0);
}
