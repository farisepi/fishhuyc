shader_type canvas_item;

uniform vec4 src0 : source_color = vec4(0.0);
uniform vec4 src1 : source_color = vec4(0.0);
uniform vec4 src2 : source_color = vec4(0.0);
uniform vec4 src3 : source_color = vec4(0.0);
uniform vec4 src4 : source_color = vec4(0.0);
uniform vec4 src5 : source_color = vec4(0.0);
uniform vec4 dst0 : source_color = vec4(0.0);
uniform vec4 dst1 : source_color = vec4(0.0);
uniform vec4 dst2 : source_color = vec4(0.0);
uniform vec4 dst3 : source_color = vec4(0.0);
uniform vec4 dst4 : source_color = vec4(0.0);
uniform vec4 dst5 : source_color = vec4(0.0);
uniform float tolerance = 0.035;

vec3 swap(vec3 c, vec4 s, vec4 d, inout bool done) {
	if (!done && s.a > 0.5 && distance(c, s.rgb) < tolerance) {
		done = true;
		return d.rgb;
	}
	return c;
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec3 c = tex.rgb;
	bool done = false;
	c = swap(c, src0, dst0, done);
	c = swap(c, src1, dst1, done);
	c = swap(c, src2, dst2, done);
	c = swap(c, src3, dst3, done);
	c = swap(c, src4, dst4, done);
	c = swap(c, src5, dst5, done);
	if (done) {
		vec3 m = COLOR.rgb / max(tex.rgb, vec3(0.01));
		COLOR = vec4(c * m, COLOR.a);
	}
}
