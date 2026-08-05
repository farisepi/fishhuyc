shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

uniform float glass_alpha : hint_range(0.0, 1.0) = 0.2;
uniform float glare_brightness : hint_range(0.0, 1.0) = 0.5;
uniform float glass_tint : hint_range(0.0, 1.0) = 0.3;

void fragment() {
    vec2 uv = UV;
    float time = TIME;
    
    vec4 bg = texture(screen_texture, SCREEN_UV);
    
    // ==========================================
    // 1. БАЗОВЫЙ ОТТЕНОК СТЕКЛА
    // ==========================================
    vec3 glass = bg.rgb;
    
    // Лёгкое голубое затемнение
    glass = mix(glass, glass * vec3(0.9, 0.92, 1.0), glass_tint);
    
    // ==========================================
    // 2. ОСНОВНОЙ БЛИК (широкая диагональ)
    // ==========================================
    float glare1 = (uv.x - uv.y * 0.8);
    glare1 = exp(-glare1 * glare1 * 8.0);
    
    // ==========================================
    // 3. ТОНКИЙ БЛИК (узкая полоса)
    // ==========================================
    float glare2 = (uv.x - uv.y * 0.4 + 0.3);
    glare2 = exp(-glare2 * glare2 * 40.0) * 0.6;
    
    // ==========================================
    // 4. БЛИКИ ОТ ЛАМП (два пятна)
    // ==========================================
    float lamp1 = exp(-length(uv - vec2(0.25, 0.5)) * 5.0) * 0.15;
    float lamp2 = exp(-length(uv - vec2(0.75, 0.5)) * 5.0) * 0.15;
    
    // ==========================================
    // 5. СБОРКА
    // ==========================================
    float total_glare = (glare1 * 0.7 + glare2 * 0.3 + lamp1 + lamp2) * glare_brightness;
    glass += vec3(0.5, 0.8, 1.0) * total_glare;
    
    // ==========================================
    // 6. ФИНАЛ
    // ==========================================
    COLOR = vec4(glass, glass_alpha);
}