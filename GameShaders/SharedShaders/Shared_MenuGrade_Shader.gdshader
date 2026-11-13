shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform vec4 shadow_tint : source_color = vec4(0.62, 0.70, 0.86, 1.0);
uniform vec4 light_tint : source_color = vec4(1.0, 0.86, 0.66, 1.0);
uniform vec4 haze_color : source_color = vec4(0.10, 0.11, 0.14, 1.0);
uniform float strength : hint_range(0.0, 1.0) = 1.0;
uniform float desat = 0.12;
uniform float vignette = 0.38;
uniform float grain = 0.035;
uniform float haze = 0.06;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec3 src = texture(screen_tex, uv).rgb;
	vec3 c = src;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(c, vec3(l), desat);
	c *= mix(shadow_tint.rgb, light_tint.rgb, smoothstep(0.15, 0.75, l));
	c = mix(src, c, 0.55);
	float lamp = 1.0 - 0.18 * smoothstep(0.2, 1.0, uv.y) + 0.06 * (1.0 - smoothstep(0.0, 0.45, abs(uv.x - 0.5))) * (1.0 - uv.y);
	c *= lamp;
	c = c + haze_color.rgb * haze * (1.0 - l);
	vec2 d = (uv - 0.5) * vec2(1.15, 1.0);
	c *= 1.0 - vignette * smoothstep(0.35, 0.85, length(d));
	COLOR = vec4(mix(src, c, strength), 1.0);
}
