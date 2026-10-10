// Aurora: luzes ciano/violeta flutuando sobre o azul-noite, com a grade no horizonte.
void main() {
    vec2 uv = qt_TexCoord0;
    uv.y = 1.0 - uv.y;
    float aspect = resolution.x / max(resolution.y, 1.0);
    vec2 p = vec2(uv.x * aspect, uv.y);
    float t = time * 0.06;

    vec3 col = bg.rgb;

    // manchas de luz que passeiam devagar
    col += accent.rgb  * blob(p, vec2(0.15 * aspect + sin(t * 1.3) * 0.12, 1.05 + cos(t) * 0.05), 0.55) * 0.28;
    col += accent2.rgb * blob(p, vec2(0.92 * aspect + cos(t * 0.9) * 0.10, 0.70 + sin(t * 1.1) * 0.08), 0.60) * 0.32;
    col += hot.rgb     * blob(p, vec2(0.48 * aspect + sin(t * 0.7) * 0.15, -0.10), 0.45) * 0.16;

    // véus de aurora
    float n = fbm(vec2(p.x * 1.4 + t * 2.0, p.y * 3.0 - t));
    float band = smoothstep(0.35, 0.9, n) * smoothstep(0.25, 0.75, uv.y);
    vec3 auroraCol = mix(accent.rgb, accent2.rgb, smoothstep(0.2, 0.9, uv.x + n * 0.3));
    col += auroraCol * band * 0.2;

    // estrelas bem fracas
    vec2 sp = p * 140.0;
    float s = hash(floor(sp));
    float star = step(0.996, s) * (0.5 + 0.5 * sin(time * (1.0 + s * 3.0) + s * 40.0));
    col += vec3(star) * 0.35 * smoothstep(0.3, 1.0, uv.y);

    col += horizonGrid(uv, aspect, time * 0.05, 0.33);

    // vinheta
    col *= 1.0 - 0.35 * pow(length(qt_TexCoord0 - 0.5) * 1.3, 2.0);
    col = musicReact(col);
    fragColor = vec4(col, 1.0) * qt_Opacity;
}
