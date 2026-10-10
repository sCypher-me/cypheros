// Nebulosa: nuvens de gás coloridas girando devagar, com estrelas.
void main() {
    vec2 uv = qt_TexCoord0;
    float aspect = resolution.x / max(resolution.y, 1.0);
    vec2 p = (uv - 0.5) * vec2(aspect, 1.0) * 2.2;
    float t = time * 0.03;

    vec2 q = vec2(fbm(p + t), fbm(p + vec2(5.2, 1.3) - t));
    vec2 r = vec2(fbm(p + 3.0 * q + vec2(1.7, 9.2) + t * 0.5), fbm(p + 3.0 * q + vec2(8.3, 2.8)));
    float f = fbm(p + 3.0 * r);

    vec3 col = bg.rgb;
    col = mix(col, accent2.rgb * 0.55, clamp(f * f * 1.6, 0.0, 1.0));
    col = mix(col, accent.rgb * 0.6, clamp(length(q) * 0.5 - 0.1, 0.0, 1.0) * 0.85);
    col = mix(col, hot.rgb * 0.5, clamp(r.x * r.x * 0.5, 0.0, 1.0) * 0.35);
    col *= 0.55 + 0.45 * f;

    vec2 sp = uv * resolution / 3.0;
    float s = hash(floor(sp));
    col += vec3(step(0.997, s) * (0.6 + 0.4 * sin(time * 2.0 + s * 50.0))) * 0.6;

    col *= 1.0 - 0.4 * pow(length(uv - 0.5) * 1.3, 2.0);
    col = musicReact(col);
    fragColor = vec4(col, 1.0) * qt_Opacity;
}
