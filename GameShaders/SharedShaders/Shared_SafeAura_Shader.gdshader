// Aura rising from the floor (safe / work zones): a column of light that is brightest at the
// floor line and fades upward in stepped bands (like the aquarium glass hint), soft at the
// sides, with thin streaks drifting up and a bright breathing line on the floor itself.
// Put it on a ColorRect whose bottom edge sits a few px under the floor; the colour is the tint.
shader_type canvas_item;
render_mode unshaded, blend_add;

uniform vec2 rect_size = vec2(170.0, 90.0);   // set from code (pixels)
uniform float floor_h = 6.0;                  // px of the rect under the floor line
uniform float strength = 1.0;
uniform float pixel = 2.0;                    // chunky pixels to match the pixel art

float hash(float n) { return fract(sin(n * 12.9898) * 43758.5453); }

void fragment() {
	vec2 p = floor(UV * rect_size / pixel) * pixel + pixel * 0.5;
	float fy = rect_size.y - floor_h;               // floor line (px from top)
	float up = fy - p.y;                            // height above the floor
	float x = (p.x / rect_size.x - 0.5) * 2.0;      // -1..1
	float side = smoothstep(1.0, 0.62, abs(x));
	float breathe = 0.85 + 0.15 * sin(TIME * 2.4);
	float a = 0.0;
	if (up >= 0.0) {
		float h = clamp(up / max(1.0, fy), 0.0, 1.0);
		// stepped bands: 7 layers that get fainter upward and a little narrower
		float band = floor((1.0 - h) * 7.0) / 7.0;
		float narrow = smoothstep(1.0 - 0.25 * h, 0.55 - 0.3 * h, abs(x));
		a += pow(band, 1.8) * 0.5 * narrow * breathe;
		// thin streaks drifting up
		float col = floor(p.x / (pixel * 3.0));
		float r = hash(col);
		if (r > 0.72) {
			float sp = 22.0 + 30.0 * hash(col + 3.1);
			float y = fract((up + TIME * sp) / (26.0 + 30.0 * r));
			a += step(0.78, y) * (1.0 - h) * 0.32 * side;
		}
	} else {
		// glow on the floor in front of the aura
		float d = -up / max(1.0, floor_h);
		a += (1.0 - d) * 0.45 * side;
	}
	// the bright floor line
	a += smoothstep(pixel * 1.5, 0.0, abs(up)) * 0.55 * side * (0.75 + 0.25 * sin(TIME * 4.0));
	a *= strength * COLOR.a;
	COLOR = vec4(COLOR.rgb * a, 1.0);
}
