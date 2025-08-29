shader_type spatial;

// Only render shadows (plane will be invisible otherwise)
render_mode unshaded, shadows_only;

void fragment() {
    // No color needed, shadows will show automatically
}
