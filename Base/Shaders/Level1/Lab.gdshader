shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

uniform float lamp_strength : hint_range(0.0, 2.0) = 0.8;
uniform float lamp_width : hint_range(0.0, 0.5) = 0.04;
uniform float flicker_amount : hint_range(0.0, 0.1) = 0.02;

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
    
    lab *= 0.5;
    
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
            
            total_light += (in_cone * 0.6 + hotspot) * falloff;
        }
    }
    
    total_light = clamp(total_light, 0.0, 1.0);
    
    vec3 light_color = vec3(1.0, 0.93, 0.82);
    vec3 lit_area = bg.rgb * 1.3 + light_color * lamp_strength * 0.5;
    
    lab = mix(lab, lit_area, total_light * lamp_strength);
    
    float flicker = 1.0;
    flicker += sin(time * 3.0 + 1.0) * 0.02;
    flicker += sin(time * 5.0 + 2.0) * 0.015;
    flicker += noise(vec2(time * 4.0, 0.0)) * flicker_amount;
    
    lab = mix(lab, lab * flicker, total_light * 0.4);
    
    float crack_line = abs((uv.x - 0.5) - uv.y * 0.3);
    crack_line = exp(-crack_line * 35.0);
    crack_line *= noise(vec2(uv.y * 15.0, 0.0)) * 0.5 + 0.5;
    crack_line *= smoothstep(1.0, 0.0, uv.y);
    
    float crack = crack_line * 0.35;
    lab = mix(lab, vec3(0.0, 0.0, 0.0), crack);
    lab += vec3(0.05, 0.1, 0.2) * crack;
    
    float particles = 0.0;
    for(int j = 0; j < 8; j++) {
        float fj = float(j);
        vec2 particle_uv = uv * 5.0;
        particle_uv.x += sin(fj * 1.7 + time * 0.15) * 0.4;
        particle_uv.y += cos(fj * 1.3 + time * 0.2) * 0.4;
        particle_uv = fract(particle_uv);
        
        float particle = exp(-length(particle_uv - 0.5) * 12.0);
        particle *= 0.5 + sin(fj * 3.0 + time * 2.0) * 0.3;
        particles += particle * 0.5;
    }
    lab += vec3(0.7, 0.8, 0.9) * particles * 0.5 * total_light;
    
    float vignette = 1.0 - pow(length(uv - 0.5) * 1.0, 2.5);
    vignette = mix(vignette, 1.0, 0.3);
    lab *= vignette;
    
    COLOR = vec4(lab, 1.0);
}