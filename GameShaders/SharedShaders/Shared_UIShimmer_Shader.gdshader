shader_type canvas_item;
uniform vec2 rect_min = vec2(0.0);
uniform vec2 rect_size = vec2(32.0);
uniform float pixel = 1.0;
uniform float period = 3.2;
uniform float phase = 0.0;
uniform float strength = 0.38;
uniform float band = 0.10;
varying vec2 lp;

void vertex() {
	lp = VERTEX;
}

void fragment() {
	vec4 c = COLOR;
	vec2 q = floor(lp / pixel) * pixel;
	vec2 p = (q - rect_min) / max(rect_size, vec2(1.0));
	float t = fract(TIME / period + phase) * 2.0 - 0.45;
	float d = (p.x * 0.75 + p.y * 0.25) - t;
	float k = 1.0 - smoothstep(band * 0.4, band, abs(d));
	float edge = 1.0 - smoothstep(band, band * 2.2, abs(d));
	c.rgb = c.rgb + vec3(1.0, 0.97, 0.9) * (k * strength + edge * strength * 0.25) * c.a;
	COLOR = c;
}
