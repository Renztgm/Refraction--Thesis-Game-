shader_type sky;

uniform vec3 emerald : source_color = vec3(0.31, 0.78, 0.47);
uniform vec3 dull_gray : source_color = vec3(0.66, 0.66, 0.66);
uniform float flicker = 0.0; // 0 = emerald, 1 = dull gray

void sky() {
    vec3 color = mix(emerald, dull_gray, flicker);
    COLOR = color; // <-- must be vec3, not vec4
}
