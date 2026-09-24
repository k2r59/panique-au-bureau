shader_type canvas_item;
uniform float radius = 0.18;
void fragment() {
    vec4 portrait = texture(TEXTURE, UV);
    vec2 corner = abs(UV - vec2(0.5)) - vec2(0.5 - radius);
    float edge = length(max(corner, vec2(0.0))) + min(max(corner.x, corner.y), 0.0) - radius;
    portrait.a *= 1.0 - smoothstep(-0.006, 0.006, edge);
    COLOR = portrait;
}
