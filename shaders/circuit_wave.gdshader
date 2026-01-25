shader_type canvas_item;

// Distortion parameters
uniform float distortion : hint_range(0.0, 1.0) = 0.2;
uniform float audio_pulse : hint_range(0.0, 1.0) = 0.0;

// Wave properties
uniform float wave_speed : hint_range(0.5, 5.0) = 2.0;
uniform float wave_frequency : hint_range(1.0, 20.0) = 8.0;
uniform float wave_amplitude : hint_range(0.0, 20.0) = 6.0;

// Noise properties for organic feel
uniform float noise_scale : hint_range(1.0, 10.0) = 4.0;
uniform float noise_speed : hint_range(0.1, 2.0) = 0.5;

// Color modulation - white/light colors for visibility
uniform vec4 base_color : source_color = vec4(0.8, 0.85, 0.95, 0.6);
uniform vec4 stress_color : source_color = vec4(1.0, 0.7, 0.8, 0.8);
uniform vec4 pulse_color : source_color = vec4(0.9, 0.95, 1.0, 0.95);

// Simple noise function
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);

    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));

    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Fractal noise for more organic movement
float fbm(vec2 p) {
    float f = 0.0;
    f += 0.5 * noise(p); p *= 2.02;
    f += 0.25 * noise(p); p *= 2.03;
    f += 0.125 * noise(p);
    return f / 0.875;
}

void vertex() {
    // Only apply vertex displacement when there's distortion
    if (distortion > 0.01) {
        float time = TIME * wave_speed;

        // Get position along the line (UV.x = 0 at start, 1 at end)
        float line_pos = UV.x;

        // Primary wave - sine based
        float primary_wave = sin(line_pos * wave_frequency + time) * wave_amplitude;

        // Secondary wave - different frequency for complexity
        float secondary_wave = sin(line_pos * wave_frequency * 1.7 - time * 0.7) * wave_amplitude * 0.5;

        // Organic noise displacement
        vec2 noise_coord = vec2(line_pos * noise_scale, TIME * noise_speed);
        float organic_offset = (fbm(noise_coord) - 0.5) * wave_amplitude * 1.5;

        // Combine waves with distortion intensity
        float total_displacement = (primary_wave + secondary_wave + organic_offset) * distortion;

        // Audio pulse adds extra "breathing" effect
        total_displacement += sin(time * 3.0) * audio_pulse * wave_amplitude * 0.5;

        // Apply perpendicular displacement (assuming line is mostly horizontal)
        // For more accurate perpendicular, you'd need to pass tangent info
        VERTEX.y += total_displacement;

        // Add subtle x displacement for more organic feel
        VERTEX.x += organic_offset * 0.3 * distortion;
    }
}

void fragment() {
    // Use the vertex color (from Line2D default_color) as base
    vec4 final_color = COLOR;

    // Blend toward stress color based on distortion level
    final_color.rgb = mix(final_color.rgb, stress_color.rgb, distortion * 0.4);

    // Add pulse glow - brightens the line
    if (audio_pulse > 0.01) {
        float pulse_glow = audio_pulse * 0.6;
        final_color.rgb = mix(final_color.rgb, pulse_color.rgb, pulse_glow);
        final_color.a = min(final_color.a + pulse_glow * 0.2, 1.0);
    }

    COLOR = final_color;
}
