shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float strength = 1.0;
uniform float blur = 1.3;
uniform float mix_blur = 0.55;
uniform float dim = 0.88;

void fragment() {
	vec2 px = SCREEN_PIXEL_SIZE * blur;
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	vec3 b = c * 0.25;
	b += texture(screen_tex, SCREEN_UV + vec2(px.x, 0.0)).rgb * 0.125;
	b += texture(screen_tex, SCREEN_UV - vec2(px.x, 0.0)).rgb * 0.125;
	b += texture(screen_tex, SCREEN_UV + vec2(0.0, px.y)).rgb * 0.125;
	b += texture(screen_tex, SCREEN_UV - vec2(0.0, px.y)).rgb * 0.125;
	b += texture(screen_tex, SCREEN_UV + px).rgb * 0.0625;
	b += texture(screen_tex, SCREEN_UV - px).rgb * 0.0625;
	b += texture(screen_tex, SCREEN_UV + vec2(px.x, -px.y)).rgb * 0.0625;
	b += texture(screen_tex, SCREEN_UV + vec2(-px.x, px.y)).rgb * 0.0625;
	vec3 o = mix(c, b, mix_blur);
	vec2 d = SCREEN_UV - 0.5;
	float vig = 1.0 - 0.18 * smoothstep(0.25, 0.75, length(d * vec2(1.3, 1.0)));
	o *= dim * vig;
	COLOR = vec4(mix(c, o, strength), 1.0);
}
