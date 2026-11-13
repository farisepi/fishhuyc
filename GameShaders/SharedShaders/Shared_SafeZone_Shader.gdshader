shader_type canvas_item;
render_mode unshaded, blend_add;

uniform vec2 rect_size = vec2(110.0, 26.0);
uniform float strength = 1.0;
uniform float pixel = 2.0;

void fragment() {
	vec2 p = floor(UV * rect_size / pixel) * pixel + pixel * 0.5;
	vec2 uv = p / rect_size;
	vec2 q = (uv - 0.5) * 2.0;
	float d = length(q * vec2(1.0, 1.0));
	float pool = smoothstep(1.0, 0.0, d);
	pool = pow(pool, 1.6) * 0.55;
	float ring_r = fract(TIME * 0.45);
	float ring = smoothstep(0.08, 0.0, abs(d - ring_r)) * (1.0 - ring_r) * 0.6;
	float line_band = smoothstep(0.35, 0.0, abs(q.y));
	float dash = step(0.55, fract((p.x - TIME * 18.0) / 10.0));
	float marks = line_band * dash * smoothstep(1.0, 0.6, abs(q.x)) * 0.35;
	float caps = smoothstep(0.86, 0.95, abs(q.x)) * smoothstep(0.5, 0.0, abs(q.y)) * (0.7 + 0.3 * sin(TIME * 4.0));
	float a = (pool + ring + marks + caps) * strength * COLOR.a;
	COLOR = vec4(COLOR.rgb * a, 1.0);
}
