// The dream: things fade into the white the further they are from the fish's station
// (the conveyor runs out to both sides and melts away instead of ending with an edge).
shader_type canvas_item;

uniform float center_x = 0.0;
uniform float inner = 110.0;
uniform float outer = 340.0;
uniform vec3 mist = vec3(0.93, 0.95, 0.985);
varying vec2 wp;

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	float d = abs(wp.x - center_x);
	float k = smoothstep(inner, outer, d);
	c.rgb = mix(c.rgb, mist, smoothstep(inner * 0.4, outer, d) * 0.65);
	c.a *= 1.0 - k;
	COLOR = c;
}
