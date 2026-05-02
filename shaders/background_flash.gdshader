shader_type canvas_item;

// Compile-time max — script PULSE_COUNT must not exceed this
const int MAX_PULSES = 32;

uniform int active_pulse_count = 8;

uniform vec2 pulse_center[MAX_PULSES];
uniform float pulse_progress[MAX_PULSES];    // 0 = spawned, 1 = dead
uniform float pulse_sign[MAX_PULSES];        // +1 correct, -1 wrong, 0 inactive
uniform float pulse_hue_shift[MAX_PULSES];   // per-ripple hue variation
uniform float pulse_fade_scale[MAX_PULSES];  // per-ripple fade speed randomizer
uniform float aspect_ratio = 1.0;
uniform float max_radius = 0.8;
uniform float ring_width = 0.05;
uniform float fade_speed = 3.0;
uniform float wobble_amount = 0.08;   // max radial distortion (0 = perfect circle)
uniform float expansion_ease = 0.5;  // lower = faster start, slower finish (1.0 = linear)

uniform vec3 color_neutral = vec3(0.11, 0.11, 0.14);
uniform vec3 color_correct = vec3(0.15, 0.30, 0.15);
uniform vec3 color_wrong = vec3(0.30, 0.12, 0.12);


vec3 rgb_to_hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv_to_rgb(vec3 c) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec3 shift_hue(vec3 rgb, float amount) {
	vec3 hsv = rgb_to_hsv(rgb);
	hsv.x = fract(hsv.x + amount);
	return hsv_to_rgb(hsv);
}


void fragment() {
	vec3 color = color_neutral;

	for (int i = 0; i < active_pulse_count; i++) {
		float progress = pulse_progress[i];
		if (progress <= 0.0 || progress >= 1.0) continue;

		vec2 corrected_uv = UV * vec2(aspect_ratio, 1.0);
		vec2 corrected_center = pulse_center[i] * vec2(aspect_ratio, 1.0);
		float dist = distance(corrected_uv, corrected_center);

		// Angle from center — used for organic distortion
		float angle = atan(corrected_uv.y - corrected_center.y, corrected_uv.x - corrected_center.x);

		// Sine harmonics: different frequencies, phases derived from center (per-ripple unique)
		// Animate phase with progress so the wobble evolves as ring expands
		float seed1 = pulse_center[i].x * 17.31 + pulse_center[i].y * 43.17;
		float seed2 = pulse_center[i].x * 31.71 + pulse_center[i].y * 13.37;
		float wobble = 0.0;
		wobble += sin(angle * 3.0 + progress * 5.0 + seed1) * 0.50;
		wobble += sin(angle * 5.0 - progress * 3.0 + seed2) * 0.30;
		wobble += sin(angle * 7.0 + progress * 7.0 + seed1 * 2.0) * 0.20;
		wobble *= wobble_amount;

		// Ease-out expansion: fast at start, decelerates toward edges
		float eased = pow(progress, expansion_ease);

		// Ring expands with eased curve, distorted by wobble
		float ring_r = eased * max_radius * (1.0 + wobble);

		float half_w = ring_width * 0.5;
		float ring = smoothstep(ring_r - half_w, ring_r, dist)
		           * (1.0 - smoothstep(ring_r, ring_r + half_w, dist));

		// Exponential fade — per-ripple variation via fade_scale
		float fade = exp(-fade_speed * pulse_fade_scale[i] * progress);
		float intensity = ring * fade;
		if (intensity < 0.001) continue;

		vec3 flash_color = color_correct;
		if (pulse_sign[i] < 0.0) {
			flash_color = color_wrong;
		}

		flash_color = shift_hue(flash_color, pulse_hue_shift[i]);

		color = mix(color, flash_color, clamp(intensity, 0.0, 1.0));
	}

	COLOR = vec4(color, 1.0);
}
