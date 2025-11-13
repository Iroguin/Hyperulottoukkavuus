shader_type spatial;

uniform float w_distance = 3.0;
uniform float angle_xw = 0.0;
uniform float angle_yw = 0.0;
uniform float angle_zw = 0.0;
uniform float angle_xy = 0.0;
uniform float angle_xz = 0.0;
uniform float angle_yz = 0.0;
uniform float line_width : hint_range(0.01, 0.5) = 0.05;

// 4D rotation functions
vec4 rotate_xw(vec4 p, float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return vec4(p.x * c - p.w * s, p.y, p.z, p.x * s + p.w * c);
}

vec4 rotate_yw(vec4 p, float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return vec4(p.x, p.y * c - p.w * s, p.z, p.y * s + p.w * c);
}

vec4 rotate_zw(vec4 p, float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return vec4(p.x, p.y, p.z * c - p.w * s, p.z * s + p.w * c);
}

vec4 rotate_xy(vec4 p, float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return vec4(p.x * c - p.y * s, p.x * s + p.y * c, p.z, p.w);
}

vec4 rotate_xz(vec4 p, float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return vec4(p.x * c - p.z * s, p.y, p.x * s + p.z * c, p.w);
}

vec4 rotate_yz(vec4 p, float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return vec4(p.x, p.y * c - p.z * s, p.y * s + p.z * c, p.w);
}

vec3 project_4d_to_3d(vec4 p, float distance) {
    // Harmonized with GDScript: projection_distance / (projection_distance + w_offset)
    // where w_offset = p.w - distance
    // Using projection_distance = 2.0 to match dimension_manager_4d.gd
    float projection_distance = 2.0;
    float w_offset = p.w - distance;

    // Clamp to prevent going behind the 4D camera (matches GDScript near-plane clipping)
    float min_w_offset = -projection_distance + 0.1;
    w_offset = max(w_offset, min_w_offset);

    float w_factor = projection_distance / (projection_distance + w_offset);
    return vec3(p.x * w_factor, p.y * w_factor, p.z * w_factor);
}

void vertex() {
    // Extract 4D position (W coordinate stored in vertex color)
    vec4 pos_4d = vec4(VERTEX.xyz, COLOR.r * 2.0 - 1.0);

    // Apply all 4D rotations to local vertices
    pos_4d = rotate_xy(pos_4d, angle_xy);
    pos_4d = rotate_xz(pos_4d, angle_xz);
    pos_4d = rotate_yz(pos_4d, angle_yz);
    pos_4d = rotate_xw(pos_4d, angle_xw);
    pos_4d = rotate_yw(pos_4d, angle_yw);
    pos_4d = rotate_zw(pos_4d, angle_zw);

    // For local mesh vertices, don't apply perspective projection
    // The object's position is already projected in GDScript
    // We just keep the rotated XYZ coordinates
    VERTEX = pos_4d.xyz;

    // Color based on W coordinate for depth visualization
    float w_normalized = pos_4d.w * 0.5 + 0.5;
    COLOR = vec4(w_normalized, 0.5, 1.0 - w_normalized, 1.0);
}

void fragment() {
    ALBEDO = COLOR.rgb;
    EMISSION = COLOR.rgb * 0.4;
    ROUGHNESS = 0.3;
    METALLIC = 0.7;
}
