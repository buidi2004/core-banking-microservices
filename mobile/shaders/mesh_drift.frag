#include <flutter/runtime_effect.glsl>

uniform vec2 uResolution;
uniform float uTime;

out vec4 fragColor;

// 4 hằng số màu Obsidian Monochrome: True OLED Black, Deep Charcoal, Dark Graphite, Soft Obsidian
const vec3 C0 = vec3(0.000, 0.000, 0.000);   // #000000 Pure OLED Black
const vec3 C1 = vec3(0.015, 0.015, 0.020);   // #040405 Deep Charcoal
const vec3 C2 = vec3(0.030, 0.032, 0.038);   // #08080A Dark Graphite
const vec3 C3 = vec3(0.010, 0.012, 0.016);   // #030304 Soft Obsidian

// Hằng số tạo hiệu ứng Obsidian sâu thẳm
const float SCALE = 1.0;
const float CONTRAST = 1.0;
const float BRIGHTNESS = 1.0;
const float VIGNETTE_STRENGTH = 0.50;
const float GRAIN_STRENGTH = 0.015;

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 uv = fragCoord / max(uResolution, vec2(1.0));
    
    // Đảm bảo tỷ lệ khung hình chuẩn
    float aspect = uResolution.x / max(uResolution.y, 1.0);
    vec2 p = uv;
    p.x *= aspect;

    // 4 tọa độ blob trôi dạt êm ái
    float t = uTime * 0.6;
    vec2 b0 = vec2(sin(t * 0.65) * 0.32 + 0.5 * aspect, cos(t * 0.50) * 0.32 + 0.5);
    vec2 b1 = vec2(cos(t * 0.55 + 1.2) * 0.32 + 0.5 * aspect, sin(t * 0.75 + 0.8) * 0.32 + 0.5);
    vec2 b2 = vec2(sin(t * 0.45 + 2.5) * 0.35 + 0.5 * aspect, cos(t * 0.65 + 1.9) * 0.35 + 0.5);
    vec2 b3 = vec2(cos(t * 0.70 + 3.7) * 0.35 + 0.5 * aspect, sin(t * 0.55 + 2.8) * 0.35 + 0.5);

    // Tính trọng số hòa trộn theo khoảng cách nghịch đảo (Metaball blending)
    float d0 = 1.0 / (pow(distance(p, b0), 1.6) * 3.8 + 0.28);
    float d1 = 1.0 / (pow(distance(p, b1), 1.6) * 3.8 + 0.28);
    float d2 = 1.0 / (pow(distance(p, b2), 1.6) * 3.8 + 0.28);
    float d3 = 1.0 / (pow(distance(p, b3), 1.6) * 3.8 + 0.28);

    float sum = d0 + d1 + d2 + d3;
    vec3 col = (C0 * d0 + C1 * d1 + C2 * d2 + C3 * d3) / max(sum, 0.001);

    // Tăng cường độ sâu đen thẳm
    col = (col - 0.5) * CONTRAST + 0.5;
    col *= BRIGHTNESS;

    // Hiệu ứng Vignette tối đen ở các cạnh và góc
    vec2 vigCoord = (uv - 0.5) * vec2(aspect, 1.0);
    float vig = 1.0 - smoothstep(0.40, 1.20, length(vigCoord) * 1.4) * VIGNETTE_STRENGTH;
    col *= vig;

    // Dither chống hiện tượng dải màu banding trên màn hình OLED
    float noise = fract(sin(dot(fragCoord, vec2(12.9898, 78.233))) * 43758.5453);
    col += (noise - 0.5) * GRAIN_STRENGTH;

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
