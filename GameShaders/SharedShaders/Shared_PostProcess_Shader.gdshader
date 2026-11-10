// World-space post-process: put it on a huge ColorRect with a high z_index (mouse_filter = Ignore).
// It only reads what the world drew below it, so CanvasLayer UI stays untouched.
shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;

uniform float vignette_strength = 0.55;
uniform float vignette_radius = 0.78;
uniform vec4 shadow_tint : source_color = vec4(0.10, 0.14, 0.20, 1.0);   // colour pushed into the darks
uniform vec4 highlight_tint : source_color = vec4(1.0, 0.86, 0.66, 1.0); // colour of the brights
uniform float grade_amount = 0.55;
uniform float contrast = 1.12;
uniform float saturation = 0.92;
uniform float aberration = 0.0;
uniform float grain_amount = 0.045;
uniform float grain_pixel = 3.0;      // grain cell size in screen pixels
uniform float scanline_amount = 0.035;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 cc = uv - 0.5;
	float r2 = dot(cc, cc);

	// chromatic aberration grows towards the edges
	vec2 off = cc * aberration * (0.4 + r2 * 4.0);
	vec3 col;
	col.r = texture(screen_tex, uv + off).r;
	col.g = texture(screen_tex, uv).g;
	col.b = texture(screen_tex, uv - off).b;

	// contrast + saturation
	col = (col - 0.5) * contrast + 0.5;
	float lum = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(vec3(lum), col, saturation);

	// split-tone: cool shadows, warm highlights
	lum = clamp(dot(col, vec3(0.299, 0.587, 0.114)), 0.0, 1.0);
	vec3 graded = mix(col + shadow_tint.rgb * (1.0 - lum) * 0.35, col * highlight_tint.rgb, smoothstep(0.35, 1.0, lum));
	col = mix(col, graded, grade_amount);

	// vignette
	float v = 1.0 - smoothstep(0.2, vignette_radius, length(cc * vec2(1.25, 1.0)));
	col *= mix(1.0 - vignette_strength, 1.0, v);

	// no moving grain or scanlines (they tire the eyes): the air instead gets a calm depth -
	// the darkest parts lift a little towards the shadow tint, like dust in the lamp light
	// (it does not move or flicker)
	float deep = 1.0 - smoothstep(0.0, 0.22, dot(col, vec3(0.299, 0.587, 0.114)));
	col += shadow_tint.rgb * deep * 0.12;

	COLOR = vec4(clamp(col, 0.0, 1.0), 1.0);
}
