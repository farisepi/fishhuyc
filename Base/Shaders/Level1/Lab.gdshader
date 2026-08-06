shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
    vec2 uv = UV;
    float time = TIME;
    
    vec4 col = texture(screen_texture, SCREEN_UV);
    vec3 lab = col.rgb;
    
    float lamp_x[8];
    lamp_x[0] = 64.0 / 1002.0;
    lamp_x[1] = 189.0 / 1002.0;
    lamp_x[2] = 314.0 / 1002.0;
    lamp_x[3] = 439.0 / 1002.0;
    lamp_x[4] = 563.0 / 1002.0;
    lamp_x[5] = 687.0 / 1002.0;
    lamp_x[6] = 813.0 / 1002.0;
    lamp_x[7] = 937.0 / 1002.0;
    
    float lamp_y = 0.20;
    float lamps_light = 0.0;
    
    for(int i = 0; i < 8; i++) {
        float dist_to_lamp = length(uv - vec2(lamp_x[i], lamp_y));
        float glow = exp(-dist_to_lamp * 4.0) * 0.25;
        
        float dist_down = uv.y - lamp_y;
        if (dist_down > 0.0) {
            float cone_width = 0.06 * (1.0 + dist_down * 1.2);
            float dist_x = abs(uv.x - lamp_x[i]);
            float in_cone = 1.0 - smoothstep(0.0, cone_width, dist_x);
            float falloff = exp(-dist_down * 1.8);
            glow += in_cone * falloff * 0.4;
        }
        
        float dist_up = lamp_y - uv.y;
        if (dist_up > 0.0) {
            glow += exp(-dist_up * 5.0) * 0.1;
        }
        
        float fi = float(i);
        float flicker = 1.0;
        flicker += sin(time * (2.0 + fi * 0.7) + fi * 1.5) * 0.02;
        flicker += sin(time * (5.0 + fi * 1.1) + fi * 2.3) * 0.015;
        
        lamps_light += glow * flicker;
    }
    
    lamps_light = clamp(lamps_light, 0.0, 1.0);
    
    float char1_dist = length(uv - vec2(0.726, 0.63));
    float char1_light = exp(-char1_dist * 3.0) * 0.5;
    
    float char2_dist = length(uv - vec2(0.616, 0.63));
    float char2_light = exp(-char2_dist * 3.0) * 0.5;
    
    float char_light = max(char1_light, char2_light);
    
    // ==========================================
    // ТЕНИ — все одинаковые, просто отзеркалены
    // ==========================================
    
    float dy = uv.y - 0.63;
    float edge_coef = 0.3;
    float falloff_coef = 2.1;
    float alpha = 0.7;
    float edge_blur = 0.04;
    float center_blur = 0.02;
    
    // Учёный — влево
    float d1 = uv.x - 0.616;
    float s1 = 0.0;
    if (dy > 0.0 && d1 < 0.0) {
        float edge = -dy * edge_coef;
        float in_tri = smoothstep(edge, edge + edge_blur, d1) * (1.0 - smoothstep(-center_blur, center_blur, d1));
        s1 = in_tri * exp(-dy * falloff_coef) * alpha;
    }
    
    // Учёный — вправо (отзеркалено)
    float d1r = -(uv.x - 0.616);
    float s1r = 0.0;
    if (dy > 0.0 && d1r < 0.0) {
        float edge = -dy * edge_coef;
        float in_tri = smoothstep(edge, edge + edge_blur, d1r) * (1.0 - smoothstep(-center_blur, center_blur, d1r));
        s1r = in_tri * exp(-dy * falloff_coef) * alpha;
    }
    
    // Механик — влево (отзеркалено)
    float d2 = uv.x - 0.726;
    float s2 = 0.0;
    if (dy > 0.0 && d2 < 0.0) {
        float edge = -dy * edge_coef;
        float in_tri = smoothstep(edge, edge + edge_blur, d2) * (1.0 - smoothstep(-center_blur, center_blur, d2));
        s2 = in_tri * exp(-dy * falloff_coef) * alpha;
    }
    
    // Механик — вправо (отзеркалено)
    float d2r = -(uv.x - 0.726);
    float s2r = 0.0;
    if (dy > 0.0 && d2r < 0.0) {
        float edge = -dy * edge_coef;
        float in_tri = smoothstep(edge, edge + edge_blur, d2r) * (1.0 - smoothstep(-center_blur, center_blur, d2r));
        s2r = in_tri * exp(-dy * falloff_coef) * alpha;
    }
    
    float total_shadow = max(max(s1, s1r), max(s2, s2r));
    
    float dust = 0.0;
    for(int j = 0; j < 12; j++) {
        float fj = float(j);
        vec2 dust_uv = uv * 5.0;
        dust_uv.x += sin(fj * 1.7 + time * 0.15) * 0.5;
        dust_uv.y += cos(fj * 1.3 + time * 0.2) * 0.5;
        dust_uv = fract(dust_uv);
        
        float d = exp(-length(dust_uv - 0.5) * 10.0);
        d *= 0.4 + sin(fj * 3.0 + time * 2.0) * 0.2;
        dust += d * 0.4;
    }
    
    float dark = 0.35;
    float light = dark + lamps_light * 0.5 + char_light * 0.4;
    light = light - total_shadow * 0.55;
    light = clamp(light, 0.15, 1.0);
    
    lab *= light;
    lab += vec3(1.0, 0.93, 0.8) * lamps_light * 0.12;
    lab += vec3(1.0, 0.95, 0.8) * char_light * 0.3;
    lab += vec3(0.5, 0.5, 0.5) * dust * 0.15;
    
    float vignette = 1.0 - pow(length(uv - 0.5) * 1.2, 3.0);
    vignette = mix(vignette, 1.0, 0.2);
    lab *= vignette;
    
    COLOR = vec4(lab, 1.0);
}