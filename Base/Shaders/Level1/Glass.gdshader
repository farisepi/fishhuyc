shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

// Границы стекла
uniform float glass_top : hint_range(0.0, 1.0) = 0.0;
uniform float glass_bottom : hint_range(0.0, 1.0) = 0.0;
uniform float glass_left : hint_range(0.0, 1.0) = 0.0;
uniform float glass_right : hint_range(0.0, 1.0) = 0.0;

// Параметры стекла
uniform float glass_glow : hint_range(0.0, 1.0) = 0.35;
uniform float glass_distortion : hint_range(0.0, 0.02) = 0.005;
uniform float crack_intensity : hint_range(0.0, 1.0) = 0.3;

// Шум для текстуры стекла
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

float fbm(vec2 p) {
    float value = 0.0;
    float amp = 0.5;
    for(int i = 0; i < 4; i++) {
        value += amp * noise(p);
        p *= 2.0;
        amp *= 0.5;
    }
    return value;
}

void fragment() {
    vec2 uv = UV;
    float time = TIME;
    
    // Маска стекла
    float in_glass_x = step(glass_left, uv.x) * step(uv.x, glass_right);
    float in_glass_y = step(glass_top, uv.y) * step(uv.y, glass_bottom);
    float glass_mask = in_glass_x * in_glass_y;
    
    vec4 col = texture(screen_texture, SCREEN_UV);
    vec4 final_col = col;
    
    if (glass_mask > 0.5) {
        // ==========================================
        // 1. БАЗОВЫЙ ЦВЕТ СТЕКЛА (холодный голубой)
        // ==========================================
        vec4 glass_base = col;
        glass_base.rgb *= 0.85;
        glass_base.rgb += vec3(0.05, 0.1, 0.15);
        
        // ==========================================
        // 2. ИСКАЖЕНИЕ ЗА СТЕКЛОМ
        // ==========================================
        float distort = fbm(uv * 15.0 + time * 0.1) * glass_distortion;
        vec2 distorted_uv = SCREEN_UV + vec2(distort, distort * 0.5);
        vec4 background = texture(screen_texture, distorted_uv);
        
        // ==========================================
        // 3. СВЕЧЕНИЕ ПО КРАЯМ
        // ==========================================
        float edge_left = exp(-pow((uv.x - glass_left) * 60.0, 2.0));
        float edge_right = exp(-pow((uv.x - glass_right) * 60.0, 2.0));
        float edge_top = exp(-pow((uv.y - glass_top) * 60.0, 2.0));
        float edge_bottom = exp(-pow((uv.y - glass_bottom) * 60.0, 2.0));
        
        float edge_glow = (edge_left + edge_right + edge_top + edge_bottom) * 0.25;
        edge_glow *= glass_glow;
        
        // ==========================================
        // 4. БЛИКИ НА СТЕКЛЕ
        // ==========================================
        // Основной блик (диагональный)
        float glare1 = sin(uv.x * 50.0 - uv.y * 30.0 + time * 0.3) * 0.5 + 0.5;
        glare1 = pow(glare1, 8.0) * 0.15;
        
        // Второй блик (вертикальный)
        float glare2 = sin(uv.x * 80.0 + time * 0.5) * 0.5 + 0.5;
        glare2 *= exp(-abs(uv.y - (glass_top + glass_bottom) * 0.5) * 10.0);
        glare2 = pow(glare2, 6.0) * 0.1;
        
        // Шумовой блик (неровности стекла)
        float glare3 = fbm(uv * 20.0 + time * 0.05) * 0.08;
        
        float total_glare = glare1 + glare2 + glare3;
        
        // ==========================================
        // 5. ТРЕЩИНА
        // ==========================================
        float crack = 0.0;
        
        // Основная трещина
        float crack_x = uv.x + sin(uv.y * 5.0) * 0.1;
        float crack_line = exp(-abs(crack_x - 0.6) * 30.0);
        crack_line *= 0.5 + noise(vec2(uv.y * 10.0, 0.0)) * 0.5;
        
        // Ответвления трещины
        float branch1 = exp(-abs(uv.x - 0.6 - uv.y * 0.2) * 20.0) * exp(-uv.y * 3.0);
        float branch2 = exp(-abs(uv.x - 0.45 + uv.y * 0.15) * 25.0) * exp(-(1.0 - uv.y) * 3.0);
        
        crack = (crack_line + branch1 * 0.4 + branch2 * 0.3) * crack_intensity;
        
        // ==========================================
        // 6. ПЫЛЬ НА СТЕКЛЕ
        // ==========================================
        float dust = 0.0;
        for(int i = 0; i < 5; i++) {
            float fi = float(i);
            vec2 dust_uv = uv * 8.0;
            dust_uv.x += sin(fi * 3.0) * 0.5;
            dust_uv.y += cos(fi * 2.0) * 0.5;
            float d = fbm(dust_uv);
            d = step(0.85, d) * 0.05;
            dust += d;
        }
        
        // ==========================================
        // 7. СБОРКА
        // ==========================================
        
        // Начинаем с искажённого фона
        final_col.rgb = background.rgb;
        
        // Добавляем базовый оттенок стекла
        final_col.rgb = mix(final_col.rgb, glass_base.rgb, 0.3);
        
        // Свечение по краям
        final_col.rgb += vec3(0.2, 0.5, 0.8) * edge_glow;
        
        // Блики
        final_col.rgb += vec3(0.6, 0.8, 1.0) * total_glare;
        
        // Трещина (тёмная)
        final_col.rgb = mix(final_col.rgb, vec3(0.02, 0.03, 0.05), crack);
        
        // Пыль
        final_col.rgb += vec3(0.3, 0.4, 0.5) * dust;
        
        // Лёгкое затемнение стекла
        final_col.rgb *= 0.9;
    }
    
    COLOR = final_col;
}