shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform vec2 light_position = vec2(0.5, 0.5); // position of your sun on screen
uniform float density : hint_range(0.0, 1.0) = 0.5;
uniform float decay : hint_range(0.0, 1.0) = 0.95;
uniform float weight : hint_range(0.0, 1.0) = 0.05;
uniform int samples = 20;

void fragment() {
    vec2 tc = SCREEN_UV;
    vec2 delta_tex_coord = tc - light_position;
    delta_tex_coord *= 1.0 / float(samples) * density;
    
    vec4 color = texture(screen_texture, tc);
    float illumination_decay = 1.0;
    
    // radial blur loop to stretch bright pixels
    for(int i = 0; i < samples; i++) {
        tc -= delta_tex_coord;
        vec4 sample_color = texture(screen_texture, tc);
        sample_color *= illumination_decay * weight;
        color += sample_color;
        illumination_decay *= decay;
    }
    COLOR = color;
}