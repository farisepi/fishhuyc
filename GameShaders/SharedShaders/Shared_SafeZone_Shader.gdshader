// Floor light for safe / work zones: lights the floor spot itself (an oval pool of light
// with a pulsing ring and moving marks on the floor line) - nothing is drawn above it.
// Put it on a thin ColorRect centred on the floor line; the ColorRect colour is the tint.
shader_type canvas_item;
render_mode unshaded, blend_add;

uniform vec2 rect_size = vec2(110.0, 26.0);   // set from code (pixels)
uniform float strength = 1.0;
uniform float pixel = 2.0;                    // chunky pixels to match the pixel art

void fragment() {
	vec2 p = floor(UV * rect_size / pixel) * pixel + pixel * 0.5;
	vec2 uv = p / rect_size;                  // 0..1
	vec2 q = (uv - 0.5) * 2.0;                // -1..1, floor line at q.y = 0
	float d = length(q * vec2(1.0, 1.0));
	// oval pool of light on the floor, brightest in the middle
	float pool = smoothstep(1.0, 0.0, d);
	pool = pow(pool, 1.6) * 0.55;
	// a ring that slowly breathes outward
	float ring_r = fract(TIME * 0.45);
	float ring = smoothstep(0.08, 0.0, abs(d - ring_r)) * (1.0 - ring_r) * 0.6;
	// moving marks along the floor line
	float line_band = smoothstep(0.35, 0.0, abs(q.y));
	float dash = step(0.55, fract((p.x - TIME * 18.0) / 10.0));
	float marks = line_band * dash * smoothstep(1.0, 0.6, abs(q.x)) * 0.35;
	// bright end caps on the floor
	float caps = smoothstep(0.86, 0.95, abs(q.x)) * smoothstep(0.5, 0.0, abs(q.y)) * (0.7 + 0.3 * sin(TIME * 4.0));
	float a = (pool + ring + marks + caps) * strength * COLOR.a;
	COLOR = vec4(COLOR.rgb * a, 1.0);
}
