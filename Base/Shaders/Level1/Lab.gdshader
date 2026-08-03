shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

uniform float lab_top : hint_range(0.0, 1.0) = 0.0;
uniform float lab_bottom : hint_range(0.0, 1.0) = 0.0;
uniform float lab_left : hint_range(0.0, 1.0) = 0.0;
uniform float lab_right : hint_range(0.0, 1.0) = 0.0;

uniform float lab_brightness : hint_range(0.0, 2.0) = 1.1;
uniform float lab_warmth : hint_range(0.0, 2.0) = 1.15;

void fragment() {
    vec2 uv = SCREEN_UV;
    vec4 col = texture(screen_texture, uv);
    
    float in_lab_x = 1.0 - step(lab_left, uv.x) * step(uv.x, lab_right);
    in_lab_x = 1.0 - in_lab_x;
    
    float in_lab_y = 1.0 - step(lab_top, uv.y) * step(uv.y, lab_bottom);
    in_lab_y = 1.0 - in_lab_y;
    
    float lab_mask = in_lab_x * in_lab_y;
    
    vec4 final_col = col;
    
    if (lab_mask > 0.5) {
        vec4 lab = col;
        lab.rgb *= lab_brightness;
        lab.r *= lab_warmth;
        lab.g *= 0.95;
        lab.b *= 0.85;
        final_col = lab;
    }
    
    COLOR = final_col;
}