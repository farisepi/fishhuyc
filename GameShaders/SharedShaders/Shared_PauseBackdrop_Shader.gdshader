// Pause backdrop: the frozen game behind the pause menu goes soft and cold - blurred,
// desaturated and tinted, with a faint colour split, thin scanlines, a slow light sweep and a
// vignette. `amount` 0..1 is animated when the menu opens / closes.
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 tint : source_color = vec4(1.0, 0.62, 0.25, 1.0);
uniform float blur_px = 2.5;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 px = SCREEN_PIXEL_SIZE * blur_px * amount;
	// 9-tap blur
	vec3 c = texture(screen_tex, uv).rgb * 0.2;
	c += texture(screen_tex, uv + vec2(px.x, 0.0)).rgb * 0.1;
	c += texture(screen_tex, uv - vec2(px.x, 0.0)).rgb * 0.1;
	c += texture(screen_tex, uv + vec2(0.0, px.y)).rgb * 0.1;
	c += texture(screen_tex, uv - vec2(0.0, px.y)).rgb * 0.1;
	c += texture(screen_tex, uv + px).rgb * 0.1;
	c += texture(screen_tex, uv - px).rgb * 0.1;
	c += texture(screen_tex, uv + vec2(px.x, -px.y)).rgb * 0.1;
	c += texture(screen_tex, uv + vec2(-px.x, px.y)).rgb * 0.1;
	// faint colour split at the edges
	vec2 cc = uv - 0.5;
	float edge = dot(cc, cc);
	float split = 0.004 * amount * edge * 4.0;
	c.r = mix(c.r, texture(screen_tex, uv + vec2(split, 0.0)).r, 0.6);
	c.b = mix(c.b, texture(screen_tex, uv - vec2(split, 0.0)).b, 0.6);
	// cold and grey with a hint of the menu colour
	float g = dot(c, vec3(0.299, 0.587, 0.114));
	vec3 grey = mix(vec3(g), tint.rgb * g * 1.2, 0.35);
	c = mix(c, grey, 0.8 * amount);
	// a slow diagonal light sweep (no scanlines)
	float sweep = smoothstep(0.08, 0.0, abs(fract(TIME * 0.12) * 1.6 - 0.3 - (uv.x * 0.7 + uv.y * 0.3)));
	c += tint.rgb * sweep * 0.07 * amount;
	// vignette
	float vig = smoothstep(0.85, 0.25, length(cc * vec2(1.25, 1.0)));
	c *= mix(1.0, 0.55 + 0.45 * vig, amount);
	COLOR = vec4(c, amount);
}
