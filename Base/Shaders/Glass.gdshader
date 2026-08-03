shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

uniform float glass_top : hint_range(0.0, 1.0) = 0.0;
uniform float glass_bottom : hint_range(0.0, 1.0) = 0.0;
uniform float glass_left : hint_range(0.0, 1.0) = 0.0;
uniform float glass_right : hint_range(0.0, 1.0) = 0.0;
uniform float glass_glow : hint_range(0.0, 1.0) = 0.35;

void fragment() {
    vec2 uv = SCREEN_UV;
    vec4 col = texture(screen_texture, uv);
    
    float in_glass_x = 1.0 - step(glass_left, uv.x) * step(uv.x, glass_right);
    in_glass_x = 1.0 - in_glass_x;
    
    float in_glass_y = 1.0 - step(glass_top, uv.y) * step(uv.y, glass_bottom);
    in_glass_y = 1.0 - in_glass_y;
    
    float glass_mask = in_glass_x * in_glass_y;
    
    vec4 final_col = col;
    
    if (glass_mask > 0.5) {
        float edge_left = exp(-pow((uv.x - glass_left) * 90.0, 2.0));
        float edge_right = exp(-pow((uv.x - glass_right) * 90.0, 2.0));
        float edge_top = exp(-pow((uv.y - glass_top) * 90.0, 2.0));
        float edge_bottom = exp(-pow((uv.y - glass_bottom) * 90.0, 2.0));
        
        float edge_glow = (edge_left + edge_right + edge_top + edge_bottom) * 0.25;
        edge_glow = edge_glow * glass_glow;
        
        final_col.rgb += vec3(0.2, 0.5, 0.8) * edge_glow * glass_mask;
    }
    
    COLOR = final_col;
}