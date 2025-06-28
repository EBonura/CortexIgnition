shader_type spatial;
render_mode blend_mix, unshaded, cull_back;

uniform float model_height = 3.0;
uniform float dissolve_start : hint_range(0.0, 1.0) = 0.001;
uniform float dissolve_length : hint_range(0.0, 1.0) = 1.0;
uniform float gradient_bias : hint_range(0.1, 5.0) = 1.0;

// Noise parameters
uniform float noise_speed = 1.0;
uniform float noise_strength = 0.1;
uniform float stretch_factor = 0.6;
uniform sampler2D noise_texture;
uniform vec2 noise_direction = vec2(0.0, 1.0);

// Color parameters
uniform vec3 _color : source_color = vec3(1.0, 0.5, 0.0);
uniform float power_factor = 2.0;

// Fresnel parameters
uniform float fresnel_factor = 2.0;
uniform float fresnel_amplification = 1.0;
uniform float fresnel_power = 1.0;

// Alpha control
uniform float thrust_opacity : hint_range(0.0, 1.0) = 1.0;

varying float vert_height;
varying vec2 v_uv;

vec3 neon(float value, vec3 color) {
    float ramp = clamp(value, 0.0, 1.0);
    vec3 output_color = vec3(0.0);
    ramp = ramp * ramp;
    output_color += pow(color, vec3(4.0)) * ramp;
    ramp = ramp * ramp;
    output_color += color * ramp;
    ramp = ramp * ramp;
    output_color += vec3(1.0) * ramp;
    return output_color;
}

float fresnel(float amount, vec3 normal, vec3 view) {
    return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0)), amount);
}

void vertex() {
    vert_height = (VERTEX.y + (model_height / 2.0)) / model_height;
    v_uv = UV;
}

void fragment() {
    // Calculate gradient
    float gradient_height = vert_height - dissolve_start;
    gradient_height *= 1.0 / dissolve_length;

    // Add noise
    float time = TIME * noise_speed;
    vec2 moving_uv = v_uv + noise_direction * time;
    vec2 stretched_uv = vec2(moving_uv.x, moving_uv.y * stretch_factor);
    float noise_value = texture(noise_texture, stretched_uv).r * noise_strength;

    gradient_height = clamp(pow(gradient_height, gradient_bias) + noise_value, 0.0, 1.0);

    // Set alpha and color
    ALPHA = mix(1.0, 0.0, gradient_height);
    ALBEDO = neon(pow(ALPHA, power_factor), _color);

    // Apply fresnel effect and thrust opacity
    float fresnel_effect = 1.0 - fresnel(fresnel_factor, NORMAL, VIEW);
    fresnel_effect = pow(fresnel_effect * fresnel_amplification, fresnel_power);
    ALPHA *= fresnel_effect * thrust_opacity;
}