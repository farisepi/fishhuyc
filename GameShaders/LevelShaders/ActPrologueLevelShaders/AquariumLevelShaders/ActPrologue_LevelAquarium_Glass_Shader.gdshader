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
    vec4 bg = texture(screen_texture, SCREEN_UV);
    
    // Градиент стекла — синий
    vec3 top_color = vec3(0.1, 0.3, 0.6);
    vec3 bottom_color = vec3(0.03, 0.15, 0.4);
    vec3 glass_tint = mix(top_color, bottom_color, uv.y);
    vec3 glass = mix(bg.rgb, glass_tint, 0.55);
    
    // Толстая рамка-фаска по краям — как у настоящего стекла
    float border_top = exp(-uv.y * 25.0) * 0.9;
    float border_bottom = exp(-(1.0 - uv.y) * 25.0) * 0.9;
    float border_left = exp(-uv.x * 25.0) * 0.9;
    float border_right = exp(-(1.0 - uv.x) * 25.0) * 0.9;
    
    float border = max(max(border_top, border_bottom), max(border_left, border_right));
    
    // Шум на рамке — неровности стекла
    float edge_noise = noise(uv * 80.0) * 0.1;
    border += edge_noise;
    border = clamp(border, 0.0, 1.0);
    
    // Рамка светлая — как торец стекла
    vec3 edge_color = vec3(0.7, 0.85, 1.0);
    glass = mix(glass, edge_color, border * 0.9);
    
    // Внутренняя тень у рамки — фаска
    float inner_shadow_top = exp(-uv.y * 8.0) * 0.5 * (1.0 - border_top);
    float inner_shadow_bottom = exp(-(1.0 - uv.y) * 8.0) * 0.5 * (1.0 - border_bottom);
    glass = mix(glass, vec3(0.0, 0.0, 0.0), inner_shadow_top * 0.3);
    glass = mix(glass, vec3(0.0, 0.0, 0.0), inner_shadow_bottom * 0.3);
    
    // Белый блик сверху
    float reflection = exp(-uv.y * 3.0);
    glass = mix(glass, vec3(0.8, 0.9, 1.0), reflection * 0.4);
    
    COLOR = vec4(glass, 1.0);
}