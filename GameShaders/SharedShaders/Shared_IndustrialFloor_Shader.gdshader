// Pixel-art steel floor / slab. Put it on a ColorRect whose top edge is the walking surface.
// Plates line up in world space, so floors split into segments still look continuous.
shader_type canvas_item;

uniform float pixel_size = 3.0;
uniform vec4 col_top : source_color = vec4(0.62, 0.58, 0.52, 1.0);    // worn top edge
uniform vec4 col_plate : source_color = vec4(0.30, 0.27, 0.25, 1.0);
uniform vec4 col_dark : source_color = vec4(0.09, 0.08, 0.08, 1.0);
uniform vec4 col_rust : source_color = vec4(0.36, 0.19, 0.10, 1.0);
uniform vec4 col_stripe : source_color = vec4(0.85, 0.62, 0.12, 1.0);
uniform float plate_width = 96.0;
// thickness of the plated surface layer; below it the slab is a darker girder face
uniform float plate_depth = 24.0;
uniform bool hazard_edge = false;      // yellow/black stripe along the girder face
uniform bool girder = true;            // draw a riveted I-beam face under the plate
uniform float rust_amount = 0.35;

varying vec2 world_pos;
varying vec2 local_pos;

void vertex() {
	local_pos = VERTEX;
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
	float ly = floor(local_pos.y / ps) * ps;           // pixel row from the top edge
	float wx = floor(world_pos.x / ps) * ps;
	vec2 px = vec2(wx, ly) / ps;
	vec3 c;

	if (ly < plate_depth) {
		// ---- tread plate --------------------------------------------------------
		float plate = floor(wx / plate_width);
		float fx = wx - plate * plate_width;
		c = col_plate.rgb * (0.9 + hash(vec2(plate, 1.0)) * 0.2);
		// diamond tread bumps
		vec2 t = mod(px, vec2(4.0, 4.0));
		if ((t.x == 1.0 && t.y == 1.0) || (t.x == 3.0 && t.y == 3.0)) c *= 1.22;
		// shading: darker towards the bottom of the plate layer
		c *= 1.0 - (ly / plate_depth) * 0.35;
		// wear + rust
		float n = vnoise(px * vec2(0.18, 0.5));
		c = mix(c, col_rust.rgb, smoothstep(0.66, 0.9, n) * rust_amount);
		// seams between plates
		if (fx < ps) c = col_dark.rgb;
		// bright worn walking edge
		if (ly < ps) c = col_top.rgb;
		else if (ly < ps * 2.0) c = mix(col_top.rgb, col_plate.rgb, 0.55);
		// bolts
		if (ly == ps * 3.0 && (fx == ps * 2.0 || fx == plate_width - ps * 3.0)) c = col_top.rgb * 0.9;
	} else {
		// ---- girder / slab face -----------------------------------------------
		float gy = ly - plate_depth;
		c = col_dark.rgb * 1.6;
		if (girder) {
			// flange line, web, rivet row
			if (gy < ps) c = col_dark.rgb;
			else if (gy < ps * 3.0) c = col_plate.rgb * 0.6;
			float rx = mod(wx, 48.0);
			if (gy >= ps * 5.0 && gy < ps * 6.0 && rx < ps) c = col_plate.rgb * 0.9;
			// lightening holes
			float hx = mod(wx + 24.0, 96.0) - 48.0;
			float hy = gy - ps * 10.0;
			if (hx * hx / 400.0 + hy * hy / 64.0 < 1.0 && hy > -ps * 3.0) c = col_dark.rgb * 0.45;
		}
		if (hazard_edge && gy >= ps * 2.0 && gy < ps * 5.0) {
			c = mod(px.x + px.y, 6.0) < 3.0 ? col_stripe.rgb : col_dark.rgb;
		}
		// fade the deep part of the slab into darkness
		c *= 1.0 - clamp((gy - ps * 6.0) / 120.0, 0.0, 0.7);
	}

	COLOR = vec4(c * COLOR.rgb, COLOR.a);
}
