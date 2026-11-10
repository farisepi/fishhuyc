// Factory hall back wall (the factory level only; built on the industrial wall). On top of the
// panels, columns, pipes and the hazard stripe it adds life without stealing attention:
//  - up in the dark: roof trusses, hanging chains with hooks that sway, far machine lights
//    (a touch of parallax from cam_pos so the depth reads when the camera moves);
//  - in every bay between columns: an exhaust fan in its housing turning slowly (not in the
//    clock's bay), sagging cables, blinking status lamps on the columns;
//  - valve wheels on the pipes and now and then a puff of steam from a joint;
//  - behind the presses: corrugated sheet metal, a cable duct and junction boxes with LEDs.
shader_type canvas_item;

uniform float pixel_size = 3.0;
uniform vec4 col_seam : source_color = vec4(0.045, 0.040, 0.050, 1.0);
uniform vec4 col_base : source_color = vec4(0.110, 0.100, 0.115, 1.0);
uniform vec4 col_light : source_color = vec4(0.175, 0.165, 0.180, 1.0);
uniform vec4 col_rust : source_color = vec4(0.260, 0.140, 0.080, 1.0);
uniform vec4 col_pipe : source_color = vec4(0.210, 0.230, 0.250, 1.0);
uniform vec4 col_stripe : source_color = vec4(0.420, 0.300, 0.080, 1.0);
// size of one wall panel in world units
uniform vec2 panel_size = vec2(96.0, 72.0);
// vertical support columns
uniform float column_spacing = 480.0;
uniform float column_width = 30.0;
// horizontal pipes (world y of their centre, very negative = off)
uniform float pipe_y1 = -99999.0;
uniform float pipe_y2 = -99999.0;
uniform float pipe_radius = 9.0;
// dark hazard stripe band (world y of its top, very negative = off)
uniform float stripe_y = -99999.0;
uniform float stripe_height = 18.0;
// the wall fades into darkness above this world y (ceiling gloom)
uniform float gloom_y = -99999.0;
uniform float gloom_length = 260.0;
uniform float rust_amount = 0.45;
uniform vec2 cam_pos = vec2(600.0, 300.0);   // set every frame by the level (parallax)
uniform float floor_y = 380.0;
uniform float lower_wall_y = 250.0;          // corrugated metal from here down to the floor
uniform float fan_y = 92.0;                   // centre of the exhaust fans
uniform float skip_bay_x = 600.0;             // no fan in the bay that holds this x (the clock)
uniform float truss_y = -30.0;               // roof trusses (top chord)

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

float seg_dist(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * h);
}

void fragment() {
	float ps = pixel_size;
	vec2 px = floor(world_pos / ps);          // art-pixel grid
	vec2 w = px * ps + ps * 0.5;              // world pos snapped to pixel centre

	// --- panels -------------------------------------------------------------
	vec2 cell = floor(w / panel_size);
	vec2 f = w - cell * panel_size;           // position inside panel
	float tint = hash(cell) * 0.35;
	vec3 c = mix(col_base.rgb, col_light.rgb, tint);
	// soft bevel: lighter top-left, darker bottom-right of each panel
	float bev = (1.0 - f.y / panel_size.y) * 0.08 - (f.x / panel_size.x) * 0.03;
	c += bev;
	// vertical grime streaks running down from seams
	float streak = vnoise(vec2(px.x * 0.9, px.y * 0.04 + cell.x * 3.0));
	c *= 0.82 + streak * 0.3;
	// rust blotches
	float r = vnoise(px * 0.09 + vec2(17.0, 3.0)) * 0.7 + vnoise(px * 0.31) * 0.3;
	c = mix(c, col_rust.rgb, smoothstep(0.62, 0.86, r) * rust_amount);
	// seams + highlight under seams
	if (f.x < ps || f.y < ps) {
		c = col_seam.rgb;
	} else if (f.y < ps * 2.0 || f.x < ps * 2.0) {
		c = mix(c, col_light.rgb * 1.25, 0.55);
	}
	// rivets near panel corners
	vec2 rf = mod(f - ps * 3.0, vec2(panel_size.x - ps * 6.0, panel_size.y - ps * 6.0));
	if (all(lessThan(rf, vec2(ps))) && f.x > ps * 2.0 && f.y > ps * 2.0) {
		c = col_light.rgb * 1.5;
	}

	// --- support columns ----------------------------------------------------
	float cx = mod(w.x + column_width * 0.5, column_spacing);
	if (cx < column_width) {
		float t = cx / column_width;           // 0..1 across the column
		float shade = 0.55 + 0.6 * sin(t * 3.14159);
		vec3 col = mix(col_seam.rgb, col_light.rgb * 1.1, shade);
		if (t < 0.12 || t > 0.88) col = col_seam.rgb;
		// bolt plates every 72 world units
		float by = mod(w.y, 72.0);
		if (by < ps * 2.0) col = col_seam.rgb * 0.8;
		if (by > ps * 3.0 && by < ps * 4.0 && (abs(t - 0.3) < 0.08 || abs(t - 0.7) < 0.08)) col = col_light.rgb * 1.6;
		c = col;
	}

	// --- hazard stripe band ---------------------------------------------------
	float sy = w.y - stripe_y;
	if (sy >= 0.0 && sy < stripe_height) {
		float diag = mod(px.x + px.y, 8.0);
		c = diag < 4.0 ? col_stripe.rgb : col_seam.rgb * 1.4;
		if (sy < ps || sy >= stripe_height - ps) c = col_seam.rgb;
	}

	// --- pipes ------------------------------------------------------------------
	for (int i = 0; i < 2; i++) {
		float py = i == 0 ? pipe_y1 : pipe_y2;
		float d = (w.y - py) / pipe_radius;     // -1..1 across the pipe
		if (abs(d) < 1.0) {
			float light = 1.0 - (d + 0.35) * (d + 0.35);
			vec3 pc = col_pipe.rgb * (0.45 + 0.75 * max(light, 0.0));
			if (abs(d) > 0.82) pc = col_seam.rgb;
			// flanges
			float fx = mod(w.x, 168.0);
			if (fx < ps * 3.0) pc = col_pipe.rgb * (abs(d) < 0.9 ? 0.75 : 0.4);
			c = pc;
		}
		// pipe shadow on the wall just below
		float sd = w.y - (py + pipe_radius);
		if (sd > 0.0 && sd < ps * 3.0) c *= 0.55;
	}

	// --- behind the presses: corrugated metal, a duct, junction boxes --------
	if (w.y > lower_wall_y && w.y < floor_y) {
		float rib = mod(w.x, 8.0);
		vec3 lc = mix(col_seam.rgb * 1.6, col_base.rgb * 0.95, step(ps * 1.0, rib));
		if (rib > ps * 2.0 && rib < ps * 3.0) lc = col_light.rgb * 0.9;
		lc *= 0.86 + 0.14 * vnoise(vec2(px.x * 0.05, px.y * 0.3));
		float duct = w.y - (lower_wall_y + 40.0);
		if (duct >= 0.0 && duct < 10.0) {
			lc = col_pipe.rgb * 0.55;
			if (duct < ps || duct >= 10.0 - ps) lc = col_seam.rgb;
		}
		float bx = mod(w.x + 30.0, 136.0);
		float byy = w.y - (lower_wall_y + 30.0);
		if (bx < 22.0 && byy > 0.0 && byy < 26.0) {
			lc = col_light.rgb * 0.75;
			if (bx < ps || bx >= 22.0 - ps || byy < ps || byy >= 26.0 - ps) lc = col_seam.rgb;
			// a little LED blinking on each box (its own rhythm)
			float id = floor((w.x + 30.0) / 136.0);
			if (bx > 14.0 && bx < 18.0 && byy > 4.0 && byy < 8.0) {
				float on = step(0.5, fract(TIME * (0.4 + hash(vec2(id, 2.0)) * 0.7) + hash(vec2(id, 5.0))));
				lc = mix(vec3(0.08, 0.25, 0.1), vec3(0.3, 1.0, 0.4), on);
				if (hash(vec2(id, 9.0)) > 0.75) lc = mix(vec3(0.25, 0.05, 0.04), vec3(1.0, 0.25, 0.15), on);
			}
		}
		if (cx >= column_width) c = lc;   // the columns stay in front
	}

	// --- bays: exhaust fans, sagging cables, column lamps --------------------
	float bay = floor(w.x / column_spacing);
	float bay_x0 = bay * column_spacing + column_width * 0.5;
	float bay_x1 = (bay + 1.0) * column_spacing - column_width * 0.5;
	float bay_c = (bay + 0.5) * column_spacing;
	bool clock_bay = abs(bay_c - skip_bay_x) < column_spacing * 0.5;
	if (!clock_bay && cx >= column_width) {
		vec2 fd = w - vec2(bay_c, fan_y);
		float box = max(abs(fd.x), abs(fd.y));
		if (box < 40.0) {
			vec3 fc = col_seam.rgb * 1.3;
			float rr = length(fd);
			if (rr < 33.0) {
				// dark shaft, faint warm light deep inside, blades turning
				fc = mix(vec3(0.02, 0.02, 0.025), vec3(0.16, 0.11, 0.06), smoothstep(30.0, 0.0, rr) * 0.6);
				float ang = atan(fd.y, fd.x) + TIME * (0.9 + hash(vec2(bay, 1.0)) * 0.6);
				float blade = smoothstep(0.55, 0.35, abs(sin(ang * 3.0)));
				if (rr > 6.0 && rr < 31.0) fc = mix(fc, col_light.rgb * 0.75, blade);
				if (rr < 6.0) fc = col_light.rgb * 0.9;
				// grille bars over it
				if (mod(w.y, 8.0) < ps) fc *= 0.45;
			}
			if (rr >= 33.0 && rr < 35.0) fc = col_seam.rgb;
			if (box > 38.0) fc = col_seam.rgb;
			if (box > 35.0 && box <= 38.0) fc = col_light.rgb * 0.8;
			c = fc;
		}
	}
	// sagging cables between the columns
	for (int k = 0; k < 2; k++) {
		float y0 = 128.0 + float(k) * 9.0;
		float t = clamp((w.x - bay_x0) / max(1.0, bay_x1 - bay_x0), 0.0, 1.0);
		float sag = (18.0 + float(k) * 6.0) * 4.0 * t * (1.0 - t);
		float cy = y0 + sag;
		if (abs(w.y - cy) < ps * 0.75 + float(k) * 0.5 && cx >= column_width) {
			c = col_seam.rgb * 0.7;
		}
	}
	// status lamps on the columns
	if (cx < column_width) {
		float lyy = w.y - 168.0;
		float t = cx / column_width;
		if (lyy > 0.0 && lyy < 6.0 && abs(t - 0.5) < 0.16) {
			float on = step(0.6, fract(TIME * 0.8 + hash(vec2(bay, 7.0))));
			c = mix(vec3(0.3, 0.06, 0.04), vec3(1.0, 0.3, 0.15), on);
		}
	}

	// --- valve wheels on the pipes, puffs of steam --------------------------
	for (int i = 0; i < 2; i++) {
		float py = i == 0 ? pipe_y1 : pipe_y2;
		float vx = mod(w.x + 84.0 + float(i) * 120.0, 336.0) - 168.0;
		vec2 vd = vec2(vx, w.y - (py - pipe_radius - 7.0));
		float vr = length(vd);
		if (vr > 4.0 && vr < 7.0) c = vec3(0.30, 0.10, 0.07);
		if (abs(vd.y) < 1.0 && abs(vd.x) < 6.0) c = vec3(0.24, 0.08, 0.06);
		if (abs(vd.x) < 1.0 && vd.y > 0.0 && vd.y < 8.0) c = col_pipe.rgb * 0.6;
		// steam from the joints (flanges every 168): a soft rising puff now and then
		float jx = mod(w.x, 168.0) - ps;
		float jid = floor(w.x / 168.0) + float(i) * 31.0;
		float cyc = fract(TIME * 0.11 + hash(vec2(jid, 3.0)));
		if (hash(vec2(jid, 4.0)) > 0.55 && cyc < 0.35) {
			float k2 = cyc / 0.35;
			vec2 sp = vec2(jx, w.y - (py - pipe_radius - 4.0 - k2 * 40.0));
			float puff = vnoise(w * 0.12 + vec2(0.0, TIME * 1.5)) * smoothstep(14.0 + k2 * 10.0, 0.0, length(sp * vec2(1.0, 0.8)));
			c = mix(c, vec3(0.55, 0.55, 0.6), puff * (1.0 - k2) * 0.55);
		}
	}

	// --- up in the dark: roof trusses, chains, far lights (parallax) ---------
	if (w.y < pipe_y1 - 30.0) {
		vec2 q = vec2(w.x - (cam_pos.x - 600.0) * 0.25, w.y);
		// above the wall top (the truss's bottom chord): the open, dark depth of the hall
		if (q.y < truss_y + 30.0) {
			float depth = clamp((truss_y + 30.0 - q.y) / 300.0, 0.0, 1.0);
			c = mix(vec3(0.065, 0.068, 0.085), vec3(0.025, 0.027, 0.04), depth);
			c += (vnoise(vec2(px.x * 0.03 + TIME * 0.05, px.y * 0.06)) - 0.5) * 0.025;   // haze
			// far machine blocks, a little lighter than the void
			float mb = floor(q.x / 150.0);
			float mh = 60.0 + hash(vec2(mb, 21.0)) * 140.0;
			if (q.y > truss_y + 30.0 - mh && mod(q.x, 150.0) > 18.0) c = mix(c, vec3(0.05, 0.052, 0.065), 0.8);
		}
		// far machine lights
		vec2 fl = floor(q / vec2(44.0, 36.0));
		float h1 = hash(fl + 13.0);
		if (h1 > 0.93 && q.y < truss_y + 80.0) {
			vec2 lp = fract(q / vec2(44.0, 36.0)) * vec2(44.0, 36.0);
			if (lp.x < 4.0 && lp.y < 4.0) {
				float bl = 0.4 + 0.6 * step(0.3, fract(TIME * (0.3 + h1) + h1 * 7.0));
				c = mix(c, h1 > 0.975 ? vec3(1.0, 0.3, 0.2) : vec3(0.9, 0.7, 0.35), 0.8 * bl);
			}
		}
		// truss: top + bottom chord and diagonals
		float ty = q.y - truss_y;
		if (ty > -2.0 && ty < 32.0) {
			bool chord = (ty > -2.0 && ty < 3.0) || (ty > 27.0 && ty < 32.0);
			float dxp = mod(q.x, 60.0);
			float dg = abs(dxp - (ty / 30.0) * 60.0);
			float dg2 = abs(dxp - (1.0 - ty / 30.0) * 60.0);
			if (chord || dg < 2.5 || dg2 < 2.5 || dxp < 3.0) {
				c = vec3(0.17, 0.165, 0.18) * (chord ? 1.0 : 0.8);
				if (ty > -2.0 && ty < 0.0) c = vec3(0.26, 0.24, 0.24);   // lit top edge
				if (ty > 29.0) c = col_seam.rgb;
			}
		}
		// chains hanging from the truss, swaying, with a hook
		float chx = mod(q.x + 70.0, 230.0);
		float cid = floor((q.x + 70.0) / 230.0);
		if (hash(vec2(cid, 11.0)) > 0.35) {
			float clen = 50.0 + hash(vec2(cid, 12.0)) * 60.0;
			float yy = q.y - (truss_y + 32.0);
			if (yy > 0.0 && yy < clen + 10.0) {
				float sway = sin(TIME * 0.7 + cid) * 3.0 * (yy / clen);
				float xx = chx - 115.0 - sway;
				if (yy < clen) {
					float link = mod(yy, 6.0);
					bool ring = (abs(xx) < 2.5 && (link < 1.0 || link > 5.0)) || (abs(abs(xx) - 2.0) < 0.8 && link < 6.0);
					if (ring) c = vec3(0.2, 0.19, 0.2);
				} else {
					// the hook
					vec2 hd = vec2(xx - 2.0, yy - clen - 4.0);
					float hr = length(hd);
					if (hr > 3.0 && hr < 5.5 && hd.y > -1.0) c = col_light.rgb;
					if (abs(xx) < 1.5 && yy - clen < 3.0) c = col_light.rgb;
				}
			}
		}
	}

	// --- ceiling gloom -------------------------------------------------------
	float g = clamp((gloom_y - w.y) / gloom_length, 0.0, 1.0);
	c *= 1.0 - g * 0.85;

	COLOR = vec4(c * COLOR.rgb, COLOR.a);
}
