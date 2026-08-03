shader_type canvas_item;

// ==========================================
// ТЕКСТУРА ВОДЫ (поверхность)
// ==========================================
uniform sampler2D water_texture : filter_linear_mipmap;

// ==========================================
// ЗЕРКАЛЬНАЯ ВОДА С ПОДВОДНЫМ ВАЙБОМ
// ==========================================
uniform float depth : hint_range(0.0, 3.0) = 1.5;
uniform float water_alpha : hint_range(0.0, 1.0) = 0.6;
uniform float mirror_strength : hint_range(0.0, 1.0) = 0.5;
uniform float wave_speed : hint_range(0.0, 2.0) = 0.8;
uniform float reflection_intensity : hint_range(0.0, 1.0) = 0.7;
uniform float caustic_strength : hint_range(0.0, 1.0) = 0.6;

// ==========================================
// ЗЕРКАЛЬНЫЙ ШУМ
// ==========================================
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

// ==========================================
// ЗЕРКАЛЬНАЯ МАГИЯ
// ==========================================
void fragment() {
    vec2 uv = UV;
    float time = TIME * wave_speed;
    
    // ==========================================
    // ЗЕРКАЛЬНОЕ ОТРАЖЕНИЕ
    // ==========================================
    vec2 mirror_uv = vec2(1.0 - uv.x, uv.y);
    
    // Волны для искажения отражения
    vec2 wave_offset = vec2(
        sin(uv.y * 25.0 + time * 0.5) * 0.02,
        cos(uv.x * 30.0 + time * 0.4) * 0.02
    );
    vec2 uv_warp = uv + wave_offset;
    vec2 mirror_warp = mirror_uv + wave_offset * 0.5;
    
    // ==========================================
    // ГЛУБИНА
    // ==========================================
    float depth_factor = uv_warp.y * depth;
    depth_factor = clamp(depth_factor, 0.0, 2.5);
    
    // ==========================================
    // ЦВЕТА ВОДЫ
    // ==========================================
    vec3 water_surface = vec3(0.05, 0.2, 0.3);
    vec3 water_deep = vec3(0.01, 0.04, 0.08);
    vec3 water_color = mix(water_surface, water_deep, depth_factor);
    
    // ==========================================
    // ЗЕРКАЛЬНОЕ ОТРАЖЕНИЕ (НЕБО И ОБЪЕКТЫ)
    // ==========================================
    // Имитация неба
    vec3 sky_color = vec3(0.1, 0.15, 0.2);
    vec3 sky_top = vec3(0.05, 0.1, 0.15);
    vec3 sky = mix(sky_top, sky_color, mirror_warp.y);
    
    // Облака
    float clouds = fbm(mirror_warp * 2.0 + time * 0.02) * 0.3;
    sky += vec3(0.1, 0.12, 0.15) * clouds;
    
    // Солнечный блик
    float sun = exp(-pow(length(mirror_warp - vec2(0.7, 0.3)) * 8.0, 2.0)) * 0.5;
    sky += vec3(0.3, 0.25, 0.15) * sun;
    
    // ==========================================
    // СМЕШИВАНИЕ ВОДЫ И ОТРАЖЕНИЯ
    // ==========================================
    float reflection_mask = mirror_strength * (1.0 - depth_factor * 0.3);
    vec3 final_color = mix(water_color, sky, reflection_mask * reflection_intensity);
    
    // ==========================================
    // ТЕКСТУРА ПОВЕРХНОСТИ ВОДЫ
    // ==========================================
    vec2 tex_uv = uv_warp * 2.0 + time * 0.02;
    vec4 tex_color = texture(water_texture, tex_uv);
    
    // Накладываем текстуру поверх воды
    float tex_strength = 0.3;
    final_color = mix(final_color, tex_color.rgb, tex_strength * (1.0 - depth_factor * 0.2));
    
    // ==========================================
    // БЛИКИ НА ЗЕРКАЛЬНОЙ ПОВЕРХНОСТИ
    // ==========================================
    float spec = sin(uv_warp.x * 60.0 + uv_warp.y * 40.0 + time * 1.2) * 0.5 + 0.5;
    spec *= sin(uv_warp.x * 50.0 - uv_warp.y * 60.0 + time * 1.0) * 0.5 + 0.5;
    spec = pow(spec, 8.0) * 0.15 * reflection_intensity;
    final_color += vec3(0.15, 0.2, 0.25) * spec * (1.0 - depth_factor * 0.2);
    
    // ==========================================
    // КАУСТИКИ (световые узоры на дне)
    // ==========================================
    float c_time = time * 0.1;
    vec2 c_uv = uv_warp * 2.5;
    
    float c1 = sin(c_uv.x * 15.0 + c_uv.y * 12.0 + c_time) * 0.5 + 0.5;
    float c2 = sin(c_uv.x * 12.0 - c_uv.y * 15.0 - c_time * 0.8) * 0.5 + 0.5;
    float c3 = cos(c_uv.x * 18.0 + c_uv.y * 10.0 + c_time * 1.1) * 0.5 + 0.5;
    
    float caustics = (c1 * c2 * c3);
    caustics = pow(caustics, 2.5) * caustic_strength * 0.4;
    
    vec3 caustic_color = vec3(0.1, 0.2, 0.15) * (1.0 - depth_factor * 0.4);
    final_color += caustic_color * caustics;
    
    // ==========================================
    // ЛУЧИ СВЕТА (солнце сквозь воду)
    // ==========================================
    float ray_time = time * 0.08;
    
    float r1 = sin(uv_warp.x * 8.0 + uv_warp.y * 6.0 - ray_time) * 0.5 + 0.5;
    float r2 = sin(uv_warp.x * 6.0 - uv_warp.y * 8.0 + ray_time * 0.7) * 0.5 + 0.5;
    float r3 = cos(uv_warp.x * 10.0 + uv_warp.y * 5.0 + ray_time * 0.5) * 0.5 + 0.5;
    
    float rays = (r1 * r2 * r3);
    rays = pow(rays, 2.0) * 0.15;
    
    final_color += vec3(0.05, 0.08, 0.1) * rays * (1.0 - depth_factor * 0.2);
    
    // ==========================================
    // МЕРЦАНИЕ
    // ==========================================
    float shimmer = sin(uv_warp.x * 100.0 + uv_warp.y * 80.0 + time * 1.5) * 0.5 + 0.5;
    shimmer *= sin(uv_warp.x * 80.0 - uv_warp.y * 100.0 + time * 1.2) * 0.5 + 0.5;
    shimmer = shimmer * 0.03;
    final_color += vec3(0.02, 0.04, 0.06) * shimmer;
    
    // ==========================================
    // ТУМАН ГЛУБИНЫ
    // ==========================================
    float fog = depth_factor * 0.12;
    vec3 fog_color = vec3(0.02, 0.04, 0.06);
    final_color = mix(final_color, fog_color, clamp(fog, 0.0, 0.5));
    
    // ==========================================
    // ВИНЬЕТКА
    // ==========================================
    float vignette = 1.0 - pow(length(uv_warp - 0.5) * 0.8, 2.0);
    vignette = mix(vignette, 1.0, 0.3);
    final_color *= vignette;
    
    // ==========================================
    // НАСЫЩЕННОСТЬ
    // ==========================================
    float saturation = 1.2;
    vec3 gray = vec3(dot(final_color, vec3(0.299, 0.587, 0.114)));
    final_color = mix(gray, final_color, saturation);
    
    // ==========================================
    // ХРОМАТИЧЕСКАЯ АБЕРРАЦИЯ (эффект линзы)
    // ==========================================
    final_color.r += 0.005;
    final_color.b -= 0.005;
    
    // ==========================================
    // ПРОЗРАЧНОСТЬ
    // ==========================================
    float alpha = water_alpha + (depth_factor * 0.02);
    alpha = clamp(alpha, 0.2, 0.8);
    
    // ==========================================
    // ФИНАЛ - ЗЕРКАЛЬНАЯ КРАСОТА!
    // ==========================================
    COLOR = vec4(final_color, alpha);
}