shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture;
uniform float strength : hint_range(0.0, 1.0) = 0.25;
uniform float time_scale : hint_range(0.1, 5.0) = 1.0;
uniform float noise_amount : hint_range(0.0, 1.0) = 0.15;
uniform float scanlines : hint_range(0.0, 400.0) = 120.0;

float rnd(vec2 co) {
    return fract(sin(dot(co, vec2(12.9898,78.233))) * 43758.5453);
}

void fragment() {
    vec2 uv = SCREEN_UV;
    float t = TIME * time_scale;

    // wavy distortion
    uv.y += sin(uv.x * 20.0 + t * 10.0) * 0.01 * strength;
    uv.x += cos(uv.y * 15.0 + t * 7.0) * 0.01 * strength;

    // subtle noise shift (keeps distortion organic)
    float n = rnd(uv * (10.0 + t));
    uv += (n - 0.5) * 0.002 * noise_amount;

    // sample the (screen) texture
    vec4 screen_col = texture(SCREEN_TEXTURE, uv);

    // simple scanline / flicker overlay
    float line = sin((SCREEN_UV.y + t * 0.05) * scanlines) * 0.5 + 0.5;
    screen_col.rgb += (line - 0.5) * 0.06 * noise_amount;

    COLOR = screen_col;
}
