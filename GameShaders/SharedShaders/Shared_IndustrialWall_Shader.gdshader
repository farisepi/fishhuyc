shader_type canvas_item;

uniform float pixel_size = 3.0;
uniform vec4 col_seam : source_color = vec4(0.045, 0.040, 0.050, 1.0);
uniform vec4 col_base : source_color = vec4(0.110, 0.100, 0.115, 1.0);
uniform vec4 col_light : source_color = vec4(0.175, 0.165, 0.180, 1.0);
uniform vec4 col_rust : source_color = vec4(0.260, 0.140, 0.080, 1.0);
uniform vec4 col_pipe : source_color = vec4(0.210, 0.230, 0.250, 1.0);
uniform vec4 col_stripe : source_color = vec4(0.420, 0.300, 0.080, 1.0);
uniform vec2 panel_size = vec2(96.0, 72.0);
uniform float column_spacing = 480.0;
uniform float column_width = 30.0;
uniform float pipe_y1 = -99999.0;
uniform float pipe_y2 = -99999.0;
uniform float pipe_radius = 9.0;
uniform float stripe_y = -99999.0;
uniform float stripe_height = 18.0;
uniform float gloom_y = -99999.0;
uniform float gloom_length = 260.0;
uniform float rust_amount = 0.45;

varying vec2 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void fragment() {
	float ps = pixel_size;
	vec2 px = floor(world_pos / ps);
	vec2 w = px * ps + ps * 0.5;

	vec2 cell = floor(w / panel_size);
	vec2 f = w - cell * panel_size;
	float tint = hash(cell) * 0.35;
	vec3 c = mix(col_base.rgb, col_light.rgb, tint);
	float bev = (1.0 - f.y / panel_size.y) * 0.08 - (f.x / panel_size.x) * 0.03;
	c += bev;
	float streak = vnoise(vec2(px.x * 0.9, px.y * 0.04 + cell.x * 3.0));
	c *= 0.82 + streak * 0.3;
	float r = vnoise(px * 0.09 + vec2(17.0, 3.0)) * 0.7 + vnoise(px * 0.31) * 0.3;
	c = mix(c, col_rust.rgb, smoothstep(0.62, 0.86, r) * rust_amount);
	if (f.x < ps || f.y < ps) {
		c = col_seam.rgb;
	} else if (f.y < ps * 2.0 || f.x < ps * 2.0) {
		c = mix(c, col_light.rgb * 1.25, 0.55);
	}
	vec2 rf = mod(f - ps * 3.0, vec2(panel_size.x - ps * 6.0, panel_size.y - ps * 6.0));
	if (all(lessThan(rf, vec2(ps))) && f.x > ps * 2.0 && f.y > ps * 2.0) {
		c = col_light.rgb * 1.5;
	}

	float cx = mod(w.x + column_width * 0.5, column_spacing);
	if (cx < column_width) {
		float t = cx / column_width;
		float shade = 0.55 + 0.6 * sin(t * 3.14159);
		vec3 col = mix(col_seam.rgb, col_light.rgb * 1.1, shade);
		if (t < 0.12 || t > 0.88) col = col_seam.rgb;
		float by = mod(w.y, 72.0);
		if (by < ps * 2.0) col = col_seam.rgb * 0.8;
		if (by > ps * 3.0 && by < ps * 4.0 && (abs(t - 0.3) < 0.08 || abs(t - 0.7) < 0.08)) col = col_light.rgb * 1.6;
		c = col;
	}

	float sy = w.y - stripe_y;
	if (sy >= 0.0 && sy < stripe_height) {
		float diag = mod(px.x + px.y, 8.0);
		c = diag < 4.0 ? col_stripe.rgb : col_seam.rgb * 1.4;
		if (sy < ps || sy >= stripe_height - ps) c = col_seam.rgb;
	}

	for (int i = 0; i < 2; i++) {
		float py = i == 0 ? pipe_y1 : pipe_y2;
		float d = (w.y - py) / pipe_radius;
		if (abs(d) < 1.0) {
			float light = 1.0 - (d + 0.35) * (d + 0.35);
			vec3 pc = col_pipe.rgb * (0.45 + 0.75 * max(light, 0.0));
			if (abs(d) > 0.82) pc = col_seam.rgb;
			float fx = mod(w.x, 168.0);
			if (fx < ps * 3.0) pc = col_pipe.rgb * (abs(d) < 0.9 ? 0.75 : 0.4);
			c = pc;
		}
		float sd = w.y - (py + pipe_radius);
		if (sd > 0.0 && sd < ps * 3.0) c *= 0.55;
	}

	float g = clamp((gloom_y - w.y) / gloom_length, 0.0, 1.0);
	c *= 1.0 - g * 0.85;

	COLOR = vec4(c * COLOR.rgb, COLOR.a);
}
