shader_type canvas_item;
render_mode unshaded, blend_add;

uniform vec2 rect_size = vec2(170.0, 90.0);
uniform float floor_h = 6.0;
uniform float strength = 1.0;
uniform float pixel = 2.0;

float hash(float n) { return fract(sin(n * 12.9898) * 43758.5453); }

void fragment() {
	vec2 p = floor(UV * rect_size / pixel) * pixel + pixel * 0.5;
	float fy = rect_size.y - floor_h;
	float up = fy - p.y;
	float x = (p.x / rect_size.x - 0.5) * 2.0;
	float side = smoothstep(1.0, 0.62, abs(x));
	float breathe = 0.85 + 0.15 * sin(TIME * 2.4);
	float a = 0.0;
	if (up >= 0.0) {
		float h = clamp(up / max(1.0, fy), 0.0, 1.0);
		float band = floor((1.0 - h) * 7.0) / 7.0;
		float narrow = smoothstep(1.0 - 0.25 * h, 0.55 - 0.3 * h, abs(x));
		a += pow(band, 1.8) * 0.5 * narrow * breathe;
		float col = floor(p.x / (pixel * 3.0));
		float r = hash(col);
		if (r > 0.72) {
			float sp = 22.0 + 30.0 * hash(col + 3.1);
			float y = fract((up + TIME * sp) / (26.0 + 30.0 * r));
			a += step(0.78, y) * (1.0 - h) * 0.32 * side;
		}
	} else {
		float d = -up / max(1.0, floor_h);
		a += (1.0 - d) * 0.45 * side;
	}
	a += smoothstep(pixel * 1.5, 0.0, abs(up)) * 0.55 * side * (0.75 + 0.25 * sin(TIME * 4.0));
	a *= strength * COLOR.a;
	COLOR = vec4(COLOR.rgb * a, 1.0);
}
