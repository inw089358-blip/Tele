shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_linear;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float line_thickness : hint_range(0.0008, 0.03) = 0.004;
uniform float line_softness : hint_range(0.0005, 0.02) = 0.0025;
uniform float glow_intensity : hint_range(0.2, 8.0) = 1.35;
uniform float edge_thickness_factor : hint_range(0.15, 1.0) = 0.28;
uniform vec3 line_base_color = vec3(0.78, 0.83, 0.88);
uniform float outer_glow_scale : hint_range(1.2, 6.0) = 1.5;
uniform float noise_strength : hint_range(0.0, 0.08) = 0.014;
uniform float split_max_offset : hint_range(0.02, 0.24) = 0.11;
uniform float show_line : hint_range(0.0, 1.0) = 0.0;

float hash12(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float beam_mask(float y_dist, float half_h, float softness) {
    return 1.0 - smoothstep(half_h, half_h + softness, y_dist);
}

void fragment() {
    float p = clamp(progress, 0.0, 1.0);
    float collapse = smoothstep(0.0, 1.0, p);
    float open_t = 1.0 - collapse;

    // Screen reveal/collapse remains Y-only.
    float y_scale = max(1.0 - collapse, 0.0009);
    vec2 sample_uv = vec2(SCREEN_UV.x, ((SCREEN_UV.y - 0.5) / y_scale) + 0.5);
    vec4 src = textureLod(screen_tex, sample_uv, 0.0);
    float in_bounds = step(0.0, sample_uv.y) * step(sample_uv.y, 1.0);
    src *= in_bounds;

    // Thicker in the middle, thinner at left/right ends.
    float x_center_dist = abs(SCREEN_UV.x - 0.5) * 2.0;
    float center_weight = clamp(1.0 - pow(x_center_dist, 1.85), 0.0, 1.0);
    float thickness_profile = mix(edge_thickness_factor, 1.0, center_weight);

    // Keep line visible only very close to collapsed state to avoid white overlay.
    float line_phase = smoothstep(0.84, 1.0, collapse);

    // Never use a huge baseline thickness; keep line physically thin from start.
    float half_h = line_thickness * mix(1.7, 1.0, line_phase) * thickness_profile;
    float soft = line_softness * mix(1.35, 1.0, thickness_profile);

    // Startup look: one center line first, then split into two parallel lines.
    float split_phase = smoothstep(0.02, 0.28, open_t) * line_phase;
    float center_hold = 1.0 - smoothstep(0.04, 0.16, open_t);
    float split_offset = split_phase * split_max_offset;

    float y_dist_center = abs(SCREEN_UV.y - 0.5);
    float y_dist_up = abs(SCREEN_UV.y - (0.5 - split_offset));
    float y_dist_down = abs(SCREEN_UV.y - (0.5 + split_offset));

    float core_center = beam_mask(y_dist_center, half_h, soft) * center_hold;
    float core_up = beam_mask(y_dist_up, half_h, soft);
    float core_down = beam_mask(y_dist_down, half_h, soft);
    float core = max(core_center, max(core_up, core_down));

    float outer_half_h = half_h * outer_glow_scale;
    float outer_soft = soft * 1.8;
    float outer_center = beam_mask(y_dist_center, outer_half_h, outer_soft) * center_hold;
    float outer_up = beam_mask(y_dist_up, outer_half_h, outer_soft);
    float outer_down = beam_mask(y_dist_down, outer_half_h, outer_soft);
    float outer = max(outer_center, max(outer_up, outer_down));

    float flicker_noise = hash12(vec2(SCREEN_UV.x * 640.0, floor(TIME * 90.0)));
    float flicker = 1.0 + (flicker_noise - 0.5) * 2.0 * noise_strength * line_phase;

    float glow_phase = line_phase * line_phase;
    float core_intensity = (0.16 + 0.62 * glow_phase) * glow_intensity;
    float outer_intensity = (0.03 + 0.20 * glow_phase) * glow_intensity;
    vec3 beam_color = line_base_color * (core * core_intensity + outer * outer_intensity) * flicker * show_line;

    float blackout = smoothstep(0.03, 1.0, p);
    vec3 col = mix(src.rgb, vec3(0.0), blackout);
    col += beam_color;

    COLOR = vec4(min(col, vec3(1.0)), 1.0);
}
