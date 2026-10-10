.pragma library

// Formatação em pt-BR (vírgula decimal, unidades curtas).

function num(n, d) {
    return Number(n).toFixed(d === undefined ? 1 : d).replace(".", ",")
}

// bytes → "512 B", "1,4 MB"...
function bytes(n) {
    const u = ["B", "KB", "MB", "GB", "TB"]
    let i = 0
    n = Math.max(0, n || 0)
    while (n >= 1024 && i < u.length - 1) { n /= 1024; i++ }
    return (i === 0 ? Math.round(n) : num(n, n >= 100 ? 0 : 1)) + " " + u[i]
}

function rate(n) { return bytes(n) + "/s" }

function pct(v) { return Math.round(Math.max(0, v) * 100) + "%" }

// segundos → "3d 4h 12min"
function duration(s) {
    s = Math.floor(s || 0)
    const d = Math.floor(s / 86400), h = Math.floor((s % 86400) / 3600), m = Math.floor((s % 3600) / 60)
    if (d > 0) return d + "d " + h + "h " + m + "min"
    if (h > 0) return h + "h " + m + "min"
    return m + "min"
}

// cor do tema → texto CSS para o Canvas
function css(c, a) {
    return "rgba(" + Math.round(c.r * 255) + "," + Math.round(c.g * 255) + "," + Math.round(c.b * 255) + "," + (a === undefined ? c.a : a) + ")"
}
