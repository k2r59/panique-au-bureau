shader_type canvas_item;
void fragment() {
    vec4 portrait = texture(TEXTURE, UV);
    vec2 corner = abs(UV - vec2(0.5)) - vec2(0.32);
    float edge = length(max(corner, vec2(0.0))) + min(max(corner.x, corner.y), 0.0) - 0.18;
    portrait.a *= 1.0 - smoothstep(-0.006, 0.006, edge);
    COLOR = portrait;
}
