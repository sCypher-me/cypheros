// Ondas: linhas de luz ondulando como fibra ótica.
void main() {
    vec2 uv = qt_TexCoord0;
    uv.y = 1.0 - uv.y;
    float aspect = resolution.x / max(resolution.y, 1.0);
    vec3 col = bg.rgb;
    col += accent2.rgb * blob(vec2(uv.x * aspect, uv.y), vec2(aspect * 0.5, 0.45), 0.6) * 0.12;

    for (int i = 0; i < 9; i++) {
        float fi = float(i);
        float y = 0.30 + fi * 0.022
                + 0.06 * sin(uv.x * 3.0 + time * 0.25 + fi * 0.45)
                + 0.03 * sin(uv.x * 7.0 - time * 0.35 + fi);
        float d = abs(uv.y - y);
        float w = 0.0015 + 0.0006 * fi;
        float line = smoothstep(w * 2.0, 0.0, d) + exp(-d * 90.0) * 0.12;
        vec3 c = mix(accent.rgb, accent2.rgb, fi / 8.0);
        float fade = smoothstep(0.0, 0.2, uv.x) * smoothstep(1.0, 0.8, uv.x);
        col += c * line * fade * 0.55;
    }
    col *= 1.0 - 0.35 * pow(length(qt_TexCoord0 - 0.5) * 1.3, 2.0);
    col = musicReact(col);
    fragColor = vec4(col, 1.0) * qt_Opacity;
}
