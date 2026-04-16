shader_type canvas_item;

uniform float line_density: hint_range(120.0, 900.0) = 420.0;
uniform float line_strength: hint_range(0.0, 1.0) = 0.14;
uniform float vignette_strength: hint_range(0.0, 1.0) = 0.36;
uniform float noise_strength: hint_range(0.0, 1.0) = 0.06;
uniform float postprocess_mode: hint_range(0.0, 1.0) = 0.0;
uniform float curvature: hint_range(0.0, 1.0) = 0.0;
uniform float clamp_edges: hint_range(0.0, 1.0) = 0.0;
uniform sampler2D screen_texture: hint_screen_texture, repeat_disable, filter_linear;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 345.45));
	p += dot(p, p + 34.345);
	return fract(p.x * p.y);
}

void fragment() {
	if (postprocess_mode < 0.5) {
		vec2 uv_overlay = UV;
		float scan_overlay = 0.5 + 0.5 * sin((uv_overlay.y * line_density + TIME * 65.0));
		float flicker_overlay = 0.97 + 0.03 * sin(TIME * 8.0);
		vec2 centered_overlay = uv_overlay - vec2(0.5);
		float radius_overlay = length(centered_overlay * vec2(1.08, 1.0));
		float vignette_overlay = smoothstep(0.22, 0.88, radius_overlay);
		float noise_overlay = hash(uv_overlay * vec2(1280.0, 720.0) + TIME * 3.0) - 0.5;

		float darken_overlay = (1.0 - scan_overlay) * line_strength;
		darken_overlay += vignette_overlay * vignette_strength;
		darken_overlay += noise_overlay * noise_strength;

		vec3 tint_overlay = vec3(0.05, 0.12, 0.09);
		float alpha_overlay = clamp(darken_overlay, 0.0, 0.62) * flicker_overlay;
		COLOR = vec4(tint_overlay, alpha_overlay);
	} else {
		vec2 uv = SCREEN_UV;
		vec2 centered = uv * 2.0 - 1.0;
		float dist = length(centered);
		float distortion = 1.0 + dist * dist * curvature;
		centered = centered * distortion;
		vec2 warped_uv = centered * 0.5 + 0.5;

		bool in_range = warped_uv.x >= 0.0 && warped_uv.x <= 1.0 && warped_uv.y >= 0.0 && warped_uv.y <= 1.0;
		vec3 color = vec3(0.0);
		if (!in_range && clamp_edges <= 0.5) {
			color = vec3(0.0);
		} else {
			vec3 scene_col = vec3(0.0);
			if (clamp_edges > 0.5) {
				vec2 clamped_uv = clamp(warped_uv, vec2(0.0), vec2(1.0));
				scene_col = texture(screen_texture, clamped_uv).rgb;
			} else {
				scene_col = texture(screen_texture, warped_uv).rgb;
			}

			float scan = 0.5 + 0.5 * sin((warped_uv.y * line_density + TIME * 65.0));
			float flicker = 0.97 + 0.03 * sin(TIME * 8.0);
			float radius = length((warped_uv - vec2(0.5)) * vec2(1.08, 1.0));
			float vignette = smoothstep(0.22, 0.88, radius);
			float noise = hash(warped_uv * vec2(1280.0, 720.0) + TIME * 3.0) - 0.5;

			float darken = (1.0 - scan) * line_strength + vignette * vignette_strength;
			color = scene_col * (1.0 - clamp(darken, 0.0, 0.75));
			color += vec3(noise * noise_strength * 0.12);
			color *= vec3(0.96, 1.0, 0.97) * flicker;
		}
		COLOR = vec4(clamp(color, 0.0, 1.0), 1.0);
	}
}
