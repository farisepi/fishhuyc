shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float amount = 0.0;
uniform vec2 size = vec2(200.0, 40.0);
uniform vec2 mouse = vec2(0.5, 0.5);
uniform float radius = 6.0;
uniform float pixel = 2.0;

float sd_round_box(vec2 p, vec2 b, float r) {
	vec2 q = abs(p) - b + vec2(r);
	return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

void fragment() {
	vec2 p = UV * size;
	vec2 pq = floor(p / pixel) * pixel + pixel * 0.5;
	vec2 c = size * 0.5;
	float d = sd_round_box(pq - c, c, radius);
	if (d > 0.0) {
		discard;
	}
	float edge_w = min(size.y * 0.45, 14.0);
	float e = 1.0 - clamp(-d / edge_w, 0.0, 1.0);
	vec2 n = normalize((p - c) / max(c, vec2(1.0)) + vec2(0.0001));
	vec2 px = SCREEN_PIXEL_SIZE;
	vec2 mag = -(p - c) * 0.035 * amount;
	vec2 bend = -n * e * e * 3.5 * amount;
	vec2 base = SCREEN_UV + (mag + bend) * px;
	vec2 split = n * e * 1.6 * amount * px;
	vec3 col;
	col.r = texture(screen_tex, base + split).r;
	col.g = texture(screen_tex, base).g;
	col.b = texture(screen_tex, base - split).b;
	col = mix(col, vec3(0.92, 0.96, 1.0), 0.07);
	vec2 m = mouse * size;
	float s = exp(-dot(pq - m, pq - m) / (2.0 * pow(size.y * 0.85, 2.0)));
	col += vec3(0.85, 0.93, 1.0) * s * 0.16;
	float rim = smoothstep(-pixel * 1.5, 0.0, d);
	float top = clamp(1.0 - pq.y / size.y * 1.6, 0.0, 1.0);
	float bot = clamp(pq.y / size.y * 1.6 - 0.6, 0.0, 1.0);
	col += vec3(1.0) * rim * top * 0.45;
	col -= vec3(0.25, 0.22, 0.18) * rim * bot * 0.35;
	float inner = smoothstep(-edge_w, -edge_w * 0.4, d) * (1.0 - rim);
	col += vec3(0.6, 0.8, 1.0) * inner * 0.06;
	COLOR = vec4(clamp(col, 0.0, 1.0), amount * 0.92);
}
