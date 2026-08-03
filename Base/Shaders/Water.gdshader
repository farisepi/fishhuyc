shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

// ==========================================
// ЭКРАННЫЕ КООРДИНАТЫ (будут обновляться из кода)
// ==========================================
uniform float water_top : hint_range(0.0, 1.0) = 0.0;
uniform float water_bottom : hint_range(0.0, 1.0) = 1.0;
uniform float water_left : hint_range(0.0, 1.0) = 0.0;
uniform float water_right : hint_range(0.0, 1.0) = 1.0;

// ==========================================
// НАСТРОЙКИ ВОДЫ
// ==========================================
uniform float water_darkness : hint_range(0.0, 1.0) = 0.45;
uniform float blue_intensity : hint_range(0.0, 2.0) = 0.7;
uniform float ripple_speed : hint_range(0.0, 3.0) = 0.8;
uniform float ripple_amount : hint_range(0.0, 0.03) = 0.02;

void fragment() {
    vec2 uv = SCREEN_UV;
    vec4 col = texture(screen_texture, uv);
    
    // Маска аквариума
    float in_water_x = 1.0 - step(water_left, uv.x) * step(uv.x, water_right);
    in_water_x = 1.0 - in_water_x;
    
    float in_water_y = 1.0 - step(water_top, uv.y) * step(uv.y, water_bottom);
    in_water_y = 1.0 - in_water_y;
    
    float water_mask = in_water_x * in_water_y;
    
    // ==========================================
    // ЕСЛИ ПИКСЕЛЬ ВНЕ АКВАРИУМА — ОРИГИНАЛ
    // ==========================================
    vec4 final_col = col;
    
    // Считаем эффект воды только если пиксель внутри аквариума
    if (water_mask > 0.5) {
        // Стены аквариума
        float dist_left = uv.x - water_left;
        float dist_right = water_right - uv.x;
        float wall_shadow = 1.0 - smoothstep(0.0, 0.08, min(dist_left, dist_right));
        wall_shadow = wall_shadow * 0.35;
        
        float dist_top = uv.y - water_top;
        float dist_bottom = water_bottom - uv.y;
        float edge_shadow = 1.0 - smoothstep(0.0, 0.06, min(dist_top, dist_bottom));
        edge_shadow = edge_shadow * 0.2;
        
        float wall_factor = 1.0 - wall_shadow - edge_shadow;
        
        // Вода
        vec4 water = col;
        
        float depth = 0.2 + 0.8 * (1.0 - uv.y);
        float dark_factor = 1.0 - water_darkness * depth;
        water.rgb *= dark_factor;
        
        water.r *= 0.5;
        water.g *= 0.8;
        water.b *= 1.0 + blue_intensity * 0.4;
        
        water.rgb *= wall_factor;
        
        float vignette = 1.0 - pow(length(uv - 0.5) * 0.7, 2.0);
        water.rgb *= vignette;
        
        float fog = (1.0 - uv.y) * 0.06;
        water.rgb += vec3(0.01, 0.03, 0.05) * fog;
        
        // Рябь
        float time = TIME * ripple_speed;
        
        float wave1 = sin(uv.x * 55.0 + uv.y * 35.0 + time) * 0.35;
        float wave2 = cos(uv.x * 40.0 - uv.y * 50.0 + time * 0.65) * 0.3;
        float wave3 = sin(uv.x * 70.0 + uv.y * 25.0 + time * 0.45) * 0.2;
        float wave4 = cos(uv.x * 30.0 + uv.y * 60.0 + time * 0.9) * 0.15;
        
        float ripple = (wave1 + wave2 + wave3 + wave4) * ripple_amount;
        
        vec2 ripple_uv = uv;
        ripple_uv.x += ripple;
        ripple_uv.y += ripple * 0.35;
        
        vec4 ripple_col = texture(screen_texture, ripple_uv);
        ripple_col.rgb *= dark_factor;
        ripple_col.r *= 0.5;
        ripple_col.g *= 0.8;
        ripple_col.b *= 1.0 + blue_intensity * 0.4;
        ripple_col.rgb *= wall_factor;
        ripple_col.rgb *= vignette;
        ripple_col.rgb += vec3(0.01, 0.03, 0.05) * fog;
        
        water = mix(water, ripple_col, 0.5);
        
        // Мелкая рябь
        float fine = sin(uv.x * 120.0 + uv.y * 80.0 + time * 1.5) * 0.005;
        fine += cos(uv.x * 100.0 - uv.y * 90.0 + time * 1.2) * 0.005;
        
        vec2 fine_uv = uv;
        fine_uv.x += fine;
        fine_uv.y += fine * 0.3;
        
        vec4 fine_col = texture(screen_texture, fine_uv);
        fine_col.rgb *= dark_factor;
        fine_col.r *= 0.5;
        fine_col.g *= 0.8;
        fine_col.b *= 1.0 + blue_intensity * 0.4;
        fine_col.rgb *= wall_factor;
        fine_col.rgb *= vignette;
        
        water = mix(water, fine_col, 0.25);
        
        // Свет сверху
        float top_light = pow(1.0 - uv.y, 2.5) * 0.06;
        water.rgb += vec3(0.02, 0.05, 0.08) * top_light;
        
        water.r *= 0.96;
        water.g *= 0.99;
        
        final_col = water;
    }
    
    COLOR = final_col;
}