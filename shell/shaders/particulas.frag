// Partículas: pontos de luz subindo devagar, como poeira brilhante.
void main() {
    vec2 uv = qt_TexCoord0;
    uv.y = 1.0 - uv.y;
    float aspect = resolution.x / max(resolution.y, 1.0);
    vec2 p = vec2(uv.x * aspect, uv.y);
    vec3 col = bg.rgb;
    col += accent2.rgb * blob(p, vec2(aspect * 0.8, 0.8), 0.7) * 0.18;
    col += accent.rgb * blob(p, vec2(aspect * 0.15, 0.15), 0.6) * 0.14;

    for (int layer = 0; layer < 3; layer++) {
        float fl = float(layer);
        float scale = 6.0 + fl * 5.0;
        vec2 g = p * scale + vec2(0.0, -time * (0.05 + fl * 0.03) * scale * 0.2);
        vec2 id = floor(g);
        vec2 f = fract(g) - 0.5;
        float h = hash(id + fl * 17.0);
        vec2 off = vec2(hash(id + 3.1), hash(id + 7.7)) - 0.5;
        off += 0.15 * vec2(sin(time * 0.4 + h * 20.0), cos(time * 0.3 + h * 12.0));
        float d = length(f - off * 0.7);
        float size = 0.02 + 0.04 * h;
        float tw = 0.6 + 0.4 * sin(time * (0.8 + h) + h * 30.0);
        float light = smoothstep(size * 4.0, 0.0, d) * 0.25 + smoothstep(size, 0.0, d);
        vec3 c = mix(accent.rgb, accent2.rgb, h);
        if (h > 0.9) c = hot.rgb;
        col += c * light * tw * step(0.45, h) * (0.5 / (1.0 + fl * 0.6));
    }
    col *= 1.0 - 0.35 * pow(length(qt_TexCoord0 - 0.5) * 1.3, 2.0);
    col = musicReact(col);
    fragColor = vec4(col, 1.0) * qt_Opacity;
}
