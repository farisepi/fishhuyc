shader_type canvas_item;
// A light band that sweeps diagonally over an interface element now and then (pixel-stepped),
// the same idea as the shimmer on the HP bar. Works on sprites and on code-drawn panels.
uniform vec2 rect_min = vec2(0.0);      // element rectangle in its local coordinates
uniform vec2 rect_size = vec2(32.0);
uniform float pixel = 1.0;              // local units per art pixel (bands move in whole pixels)
uniform float period = 3.2;             // seconds between two sweeps
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
	float t = fract(TIME / period + phase) * 2.0 - 0.45;     // the band crosses during the first ~third
	float d = (p.x * 0.75 + p.y * 0.25) - t;
	float k = 1.0 - smoothstep(band * 0.4, band, abs(d));
	float edge = 1.0 - smoothstep(band, band * 2.2, abs(d));
	c.rgb = c.rgb + vec3(1.0, 0.97, 0.9) * (k * strength + edge * strength * 0.25) * c.a;
	COLOR = c;
}
