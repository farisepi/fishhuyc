shader_type canvas_item;

// ==========================================
// ТЕКСТУРЫ И ПАРАМЕТРЫ
// ==========================================
uniform sampler2D water_texture : filter_linear_mipmap;

// Основные параметры воды
uniform float depth : hint_range(0.0, 3.0) = 1.5;
uniform float water_alpha : hint_range(0.0, 1.0) = 0.7;
uniform float wave_speed : hint_range(0.0, 2.0) = 0.6;

// Цвет воды (темный аквариум)
uniform vec3 water_color_shallow : source_color = vec3(0.03, 0.08, 0.12);
uniform vec3 water_color_deep : source_color = vec3(0.005, 0.015, 0.03);

// Свет
uniform float light_intensity : hint_range(0.0, 2.0) = 1.0;
uniform float caustic_strength : hint_range(0.0, 1.0) = 0.5;

// Шум для волн
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float smooth_noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f*f*(3.0-2.0*f);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
    float value = 0.0;
    float amp = 0.5;
    for(int i = 0; i < 5; i++) {
        value += amp * smooth_noise(p);
        p *= 2.0;
        amp *= 0.5;
    }
    return value;
}

void fragment() {
    vec2 uv = UV;
    float time = TIME * wave_speed;
    
    // ==========================================
    // ВОЛНЫ НА ПОВЕРХНОСТИ (искажение UV)
    // ==========================================
    vec2 wave_offset = vec2(
        sin(uv.y * 20.0 + time * 0.5) * 0.015,
        cos(uv.x * 25.0 + time * 0.4) * 0.015
    );
    
    // Добавляем мелкие волны
    float small_wave = fbm(vec2(uv.x * 5.0, uv.y * 5.0 + time * 0.2)) * 0.01;
    wave_offset += vec2(small_wave, small_wave * 0.7);
    
    vec2 uv_warp = uv + wave_offset;
    
    // ==========================================
    // ГЛУБИНА (чем ниже - тем темнее)
    // ==========================================
    float depth_factor = uv_warp.y * depth;
    depth_factor = clamp(depth_factor, 0.0, 2.5);
    
    // ==========================================
    // ОСНОВНОЙ ЦВЕТ ВОДЫ (темный аквариум)
    // ==========================================
    vec3 water_color = mix(water_color_shallow, water_color_deep, depth_factor);
    
    // ==========================================
    // СВЕТ СВЕРХУ (источник света на поверхности)
    // ==========================================
    // Световое пятно сверху, как будто свет падает через поверхность
    float light_spot = exp(-pow(length(uv_warp - vec2(0.5, 0.1)) * 3.5, 2.0));
    light_spot *= (1.0 - depth_factor * 0.15);
    light_spot = clamp(light_spot, 0.0, 1.0);
    
    vec3 light_color = vec3(0.3, 0.35, 0.4) * light_intensity;
    vec3 final_color = water_color + light_color * light_spot * 0.5;
    
    // ==========================================
    // ТЕКСТУРА ПОВЕРХНОСТИ (рябь на воде)
    // ==========================================
    vec2 tex_uv = uv_warp * 2.0 + time * 0.02;
    vec4 tex_color = texture(water_texture, tex_uv);
    
    // Текстура только сверху, становится прозрачнее в глубине
    float tex_strength = 0.25 * (1.0 - depth_factor * 0.3);
    final_color = mix(final_color, tex_color.rgb, tex_strength);
    
    // ==========================================
    // КАУСТИКИ (световые узоры на дне)
    // ==========================================
    float c_time = time * 0.1;
    vec2 c_uv = uv_warp * 3.0;
    
    float c1 = sin(c_uv.x * 12.0 + c_uv.y * 10.0 + c_time) * 0.5 + 0.5;
    float c2 = sin(c_uv.x * 10.0 - c_uv.y * 12.0 - c_time * 0.7) * 0.5 + 0.5;
    float c3 = cos(c_uv.x * 14.0 + c_uv.y * 8.0 + c_time * 1.1) * 0.5 + 0.5;
    
    float caustics = (c1 * c2 * c3);
    caustics = pow(caustics, 3.0) * caustic_strength * 0.5;
    
    // Каустики усиливаются на дне
    float caustic_fade = 1.0 - depth_factor * 0.6;
    vec3 caustic_color = vec3(0.15, 0.2, 0.15) * caustic_fade;
    final_color += caustic_color * caustics;
    
    // ==========================================
    // МЕРЦАНИЕ (блики на поверхности)
    // ==========================================
    float shimmer = sin(uv_warp.x * 80.0 + uv_warp.y * 60.0 + time * 1.5) * 0.5 + 0.5;
    shimmer *= sin(uv_warp.x * 60.0 - uv_warp.y * 80.0 + time * 1.2) * 0.5 + 0.5;
    shimmer = pow(shimmer, 4.0) * 0.04 * (1.0 - depth_factor * 0.3);
    final_color += vec3(0.08, 0.1, 0.12) * shimmer;
    
    // ==========================================
    // РАССЕЯНИЕ СВЕТА (томление)
    // ==========================================
    float light_scatter = exp(-pow(length(uv_warp - vec2(0.5, 0.2)) * 2.0, 2.0));
    light_scatter *= (1.0 - depth_factor * 0.2);
    final_color += vec3(0.02, 0.03, 0.04) * light_scatter * 0.3;
    
    // ==========================================
    // ТУМАН ГЛУБИНЫ (темнеет к низу)
    // ==========================================
    float fog = depth_factor * 0.15;
    vec3 fog_color = vec3(0.005, 0.01, 0.02);
    final_color = mix(final_color, fog_color, clamp(fog, 0.0, 0.6));
    
    // ==========================================
    // ВИНЬЕТКА (эффект объектива, темнее по краям)
    // ==========================================
    float vignette = 1.0 - pow(length(uv_warp - 0.5) * 1.1, 2.0);
    vignette = mix(vignette, 1.0, 0.3);
    final_color *= vignette;
    
    // ==========================================
    // ХРОМАТИЧЕСКАЯ АБЕРРАЦИЯ (подводный эффект)
    // ==========================================
    float abberation = 0.003;
    final_color.r = mix(final_color.r, final_color.g, abberation * 2.0);
    final_color.b = mix(final_color.b, final_color.g, abberation * 2.0);
    
    // ==========================================
    // ПРОЗРАЧНОСТЬ (делаем почти непрозрачным)
    // ==========================================
    float alpha = water_alpha + (depth_factor * 0.03);
    alpha = clamp(alpha, 0.5, 0.9);
    
    // ==========================================
    // ФИНАЛ
    // ==========================================
    COLOR = vec4(final_color, alpha);
}