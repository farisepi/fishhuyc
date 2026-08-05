shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

uniform float lamp_strength : hint_range(0.0, 2.0) = 0.8;
uniform float lamp_width : hint_range(0.0, 0.5) = 0.04;
uniform float flicker_amount : hint_range(0.0, 0.1) = 0.04;

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
    
    vec4 bg = texture(screen_texture, SCREEN_UV);
    vec3 lab = bg.rgb;
    
    lab *= 0.65;
    
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
    
    float total_light = 0.0;
    
    for(int i = 0; i < 8; i++) {
        float dist_down = uv.y - lamp_y;
        
        if (dist_down > 0.0) {
            float cone_width = lamp_width * (1.0 + dist_down * 1.5);
            float dist_x = abs(uv.x - lamp_x[i]);
            float in_cone = 1.0 - smoothstep(0.0, cone_width, dist_x);
            float falloff = exp(-dist_down * 3.0);
            float hotspot = exp(-dist_down * 15.0) * exp(-dist_x * 60.0) * 0.6;
            
            // Каждая лампа мерцает независимо
            float fi = float(i);
            float lamp_flicker = 1.0;
            lamp_flicker += sin(time * (2.0 + fi * 0.7) + fi * 1.5) * 0.03;
            lamp_flicker += sin(time * (5.0 + fi * 1.1) + fi * 2.3) * 0.02;
            lamp_flicker += noise(vec2(time * (3.0 + fi * 0.5), fi * 10.0)) * flicker_amount;
            lamp_flicker += step(0.97, noise(vec2(time * (6.0 + fi), fi * 20.0 + 1.0))) * 0.15;
            
            float lamp_light = (in_cone * 0.6 + hotspot) * falloff * lamp_flicker;
            total_light += lamp_light;
        }
    }
    
    total_light = clamp(total_light, 0.0, 1.0);
    
    vec3 light_color = vec3(1.0, 0.93, 0.82);
    vec3 lit_area = bg.rgb * 1.3 + light_color * lamp_strength * 0.5;
    
    lab = mix(lab, lit_area, total_light * lamp_strength);
    
    float crack_line = abs((uv.x - 0.5) - uv.y * 0.3);
    crack_line = exp(-crack_line * 35.0);
    crack_line *= noise(vec2(uv.y * 15.0, 0.0)) * 0.5 + 0.5;
    crack_line *= smoothstep(1.0, 0.0, uv.y);
    
    float crack2 = abs((uv.x - 0.35) - uv.y * 0.5);
    crack2 = exp(-crack2 * 30.0);
    crack2 *= noise(vec2(uv.y * 12.0, 2.0)) * 0.5 + 0.5;
    crack2 *= smoothstep(0.6, 0.0, uv.y) * 0.5;
    
    float crack = (crack_line * 0.6 + crack2 * 0.4) * 0.4;
    lab = mix(lab, vec3(0.0, 0.0, 0.0), crack);
    lab += vec3(0.08, 0.15, 0.3) * crack;
    
    float smoke = 0.0;
    smoke += noise(uv * 3.0 + time * 0.08) * 0.4;
    smoke += noise(uv * 6.0 - time * 0.05) * 0.3;
    smoke += noise(uv * 12.0 + time * 0.03) * 0.2;
    smoke = smoke * 0.05;
    lab += vec3(0.5, 0.45, 0.4) * smoke;
    
    float vignette = 1.0 - pow(length(uv - 0.5) * 1.0, 2.5);
    vignette = mix(vignette, 1.0, 0.3);
    lab *= vignette;
    
    COLOR = vec4(lab, 1.0);
}