import QtQuick
import qs.services
import "fmt.js" as Fmt

// Gráfico de linha com área em degradê (cor → transparente) e linha com brilho.
// A cada amostra nova o traço desliza um passo para a esquerda.
Canvas {
    id: root
    property var series: []          // [{ data: [números], color: cor }]
    property real maxValue: 0        // 0 = escala automática
    property real minScale: 1        // piso da escala automática
    property int capacity: 60
    property bool grid: true
    property real shift: 0

    antialiasing: true
    renderStrategy: Canvas.Cooperative

    onSeriesChanged: slide.restart()
    onShiftChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    NumberAnimation {
        id: slide
        target: root; property: "shift"
        from: 1; to: 0
        duration: 700
        easing.type: Easing.OutCubic
    }

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        const w = width, h = height, pad = 4
        if (w <= 0 || h <= 0) return

        if (grid) {
            ctx.strokeStyle = "rgba(255,255,255,0.05)"
            ctx.lineWidth = 1
            for (let k = 1; k < 4; k++) {
                const y = Math.round(h * k / 4) + 0.5
                ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(w, y); ctx.stroke()
            }
        }

        let top = maxValue
        if (top <= 0) {
            top = minScale
            for (const s of series) for (const v of (s.data || [])) top = Math.max(top, v)
            top *= 1.15
        }
        const step = w / Math.max(1, capacity - 1)

        for (const s of series) {
            const d = s.data || []
            const n = d.length
            if (n < 2) continue
            const pts = []
            for (let i = 0; i < n; i++) {
                const v = Math.max(0, Math.min(1, d[i] / top))
                pts.push({ x: w - (n - 1 - i) * step + root.shift * step, y: h - pad - v * (h - 2 * pad) })
            }

            // curva suave passando pelos pontos médios
            const trace = () => {
                ctx.moveTo(pts[0].x, pts[0].y)
                for (let i = 1; i < n - 1; i++)
                    ctx.quadraticCurveTo(pts[i].x, pts[i].y, (pts[i].x + pts[i + 1].x) / 2, (pts[i].y + pts[i + 1].y) / 2)
                ctx.lineTo(pts[n - 1].x, pts[n - 1].y)
            }

            const g = ctx.createLinearGradient(0, 0, 0, h)
            g.addColorStop(0, Fmt.css(s.color, 0.34))
            g.addColorStop(1, Fmt.css(s.color, 0))
            ctx.beginPath()
            trace()
            ctx.lineTo(pts[n - 1].x, h)
            ctx.lineTo(pts[0].x, h)
            ctx.closePath()
            ctx.fillStyle = g
            ctx.fill()

            ctx.lineJoin = "round"
            ctx.lineCap = "round"
            if (Config.o.glow) {
                ctx.beginPath(); trace()
                ctx.strokeStyle = Fmt.css(s.color, 0.16)
                ctx.lineWidth = 7
                ctx.stroke()
            }
            ctx.beginPath(); trace()
            ctx.strokeStyle = Fmt.css(s.color, 1)
            ctx.lineWidth = 2
            ctx.stroke()

            // ponto na amostra mais recente
            const last = pts[n - 1]
            ctx.beginPath()
            ctx.arc(Math.min(last.x, w - 3), last.y, 3, 0, Math.PI * 2)
            ctx.fillStyle = Fmt.css(s.color, 1)
            ctx.fill()
        }
    }
}
