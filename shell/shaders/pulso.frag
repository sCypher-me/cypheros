// Pulso: um anel de luz no centro que vira equalizador quando toca música. Feito para o modo musical.
void main() {
    vec2 uv = qt_TexCoord0;
    uv.y = 1.0 - uv.y;
    float aspect = resolution.x / max(resolution.y, 1.0);
    vec2 p = vec2((uv.x - 0.5) * aspect, uv.y - 0.5);
    float t = time;
    float bass = bassLevel();

    vec3 col = bg.rgb;
    // névoa de fundo
    float n = fbm(p * 1.6 + vec2(t * 0.02, -t * 0.015));
    col += mix(accent.rgb, accent2.rgb, n) * smoothstep(0.35, 0.85, n) * 0.12;
    col += accent2.rgb * blob(p, vec2(0.0), 0.7) * (0.10 + bass * 0.15);

    // anel: raio respira devagar e pulsa com o grave
    float r = length(p);
    float a = atan(p.y, p.x);
    float ang = abs(a) / 3.14159265;           // 0..1, espelhado (graves em cima)
    float amp = band(ang);
    float idle = 0.006 * sin(a * 6.0 + t * 0.8) + 0.006 * sin(t * 1.3);
    float R = 0.19 + bass * 0.03 + idle;

    // barras radiais (64 raios)
    float seg = fract(a / 6.2831853 * 64.0);
    float barMask = smoothstep(0.1, 0.25, seg) * smoothstep(0.9, 0.75, seg);
    float len = amp * 0.16;
    float inBar = step(R, r) * (1.0 - smoothstep(R + len, R + len + 0.004, r)) * barMask;
    vec3 ringCol = mix(accent.rgb, accent2.rgb, ang);
    float fadeOut = 1.0 - smoothstep(R, R + len + 0.004, r) * 0.7;   // barras somem para fora
    col += ringCol * inBar * fadeOut * (0.22 + amp * 0.3);

    // traço do anel e brilho
    float line = exp(-abs(r - R) * 260.0);
    float glow = exp(-abs(r - R) * 22.0) * (0.12 + bass * 0.35);
    col += ringCol * (line * 0.7 + glow);
    col += hot.rgb * exp(-abs(r - R - len) * 90.0) * amp * 0.25 * barMask;

    // centro escuro com logo-luz
    col = mix(col, bg.rgb * 0.8, smoothstep(R - 0.01, R - 0.12, r) * 0.7);

    // poeira subindo
    vec2 sp = vec2(p.x * 60.0, p.y * 60.0 - t * 0.6);
    float s = hash(floor(sp));
    float dot = smoothstep(0.12, 0.0, length(fract(sp) - 0.5));
    col += mix(accent.rgb, vec3(1.0), 0.5) * step(0.985, s) * dot * (0.3 + bass) * 0.5;

    col += horizonGrid(uv, aspect, time * 0.05, 0.18) * 0.6;
    col *= 1.0 - 0.35 * length(uv - 0.5);
    col = musicReact(col);
    fragColor = vec4(col, 1.0) * qt_Opacity;
}
