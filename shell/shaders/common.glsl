// Trecho comum incluído em todos os wallpapers do CypherOS.
#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;
    vec2 resolution;
    vec4 bg;
    vec4 accent;
    vec4 accent2;
    vec4 hot;
    float grid;
    vec4 bands0;   // espectro da música (16 faixas, graves primeiro), 0 quando nada toca
    vec4 bands1;
    vec4 bands2;
    vec4 bands3;
};

float band(float x) {          // x 0..1 → valor da faixa, interpolado
    float arr[16] = float[16](bands0.x, bands0.y, bands0.z, bands0.w, bands1.x, bands1.y, bands1.z, bands1.w,
                              bands2.x, bands2.y, bands2.z, bands2.w, bands3.x, bands3.y, bands3.z, bands3.w);
    float f = clamp(x, 0.0, 1.0) * 15.0;
    int i = int(floor(f));
    return mix(arr[i], arr[min(i + 1, 15)], fract(f));
}
float bassLevel() { return (bands0.x + bands0.y + bands0.z + bands0.w) * 0.25; }

// Todos os wallpapers chamam isto no fim: brilho pulsa com os graves e um espectro suave sobe do rodapé.
vec3 musicReact(vec3 col) {
    vec2 uv = vec2(qt_TexCoord0.x, 1.0 - qt_TexCoord0.y);
    float bass = bassLevel();
    col *= 1.0 + bass * 0.22;
    float b = band(abs(uv.x - 0.5) * 2.0);
    float h = b * 0.22 + 0.0001;
    float rise = exp(-uv.y / h * 2.2) * b;
    col += mix(accent.rgb, accent2.rgb, uv.x) * rise * 0.45;
    return col;
}

float hash(vec2 p) { p = fract(p * vec2(123.34, 456.21)); p += dot(p, p + 45.32); return fract(p.x * p.y); }
float noise(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}
float fbm(vec2 p) {
    float v = 0.0, a = 0.5;
    for (int i = 0; i < 5; i++) { v += a * noise(p); p = p * 2.03 + vec2(1.7, 9.2); a *= 0.5; }
    return v;
}
float blob(vec2 uv, vec2 c, float r) { float d = length(uv - c); return exp(-d * d / (r * r)); }

// grade em perspectiva com linha do horizonte (a "assinatura" Neon, bem discreta)
vec3 horizonGrid(vec2 uv, float aspect, float t, float horizon) {
    vec3 col = vec3(0.0);
    float y = horizon - uv.y;               // abaixo do horizonte > 0
    if (y > 0.0 && grid > 0.5) {
        float z = 0.35 / y;
        vec2 g = vec2((uv.x - 0.5) * aspect * z * 2.0, z + t * 0.6);
        vec2 gf = abs(fract(g) - 0.5);
        float w = fwidth(g.y) * 1.2 + 0.004;
        float line = max(1.0 - smoothstep(0.0, fwidth(g.x) * 1.5, gf.x), 1.0 - smoothstep(0.0, w, gf.y));
        float fade = smoothstep(0.0, 0.05, y) * exp(-y * 4.5) * 0.9;
        col += mix(accent.rgb, accent2.rgb, uv.x) * line * fade * 0.22;
    }
    float glow = (exp(-abs(uv.y - horizon) * 160.0) * 0.55 + exp(-abs(uv.y - horizon) * 18.0) * 0.08) * (1.0 + bassLevel() * 2.0);
    float edge = smoothstep(0.0, 0.25, uv.x) * smoothstep(1.0, 0.75, uv.x);
    col += mix(accent.rgb, accent2.rgb, uv.x) * glow * edge;
    return col;
}
