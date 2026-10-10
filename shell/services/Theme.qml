pragma Singleton
import QtQuick
import Quickshell

// Tokens do sistema de design Prisma. Tudo na interface lê daqui.
Singleton {
    id: root

    readonly property var builtin: ({
        "prisma":     { name: "Prisma",     bg: "#070A14", glass: "#101426", text: "#EEF2FF", muted: "#A9B4CF", accent: "#38E1FF", accent2: "#A78BFA", hot: "#F472B6", ok: "#34D399" },
        "oceano":     { name: "Oceano",     bg: "#05101A", glass: "#0C1C2A", text: "#EAF6FF", muted: "#9FB7C9", accent: "#5EEAD4", accent2: "#60A5FA", hot: "#F472B6", ok: "#34D399" },
        "por-do-sol": { name: "Pôr do sol", bg: "#120A12", glass: "#1E1220", text: "#FFF1EE", muted: "#C9AFB4", accent: "#FB923C", accent2: "#F472B6", hot: "#FACC15", ok: "#34D399" },
        "grafite":    { name: "Grafite",    bg: "#0B0B0D", glass: "#17171B", text: "#F2F2F5", muted: "#A1A1AA", accent: "#E4E4E7", accent2: "#818CF8", hot: "#F87171", ok: "#4ADE80" }
    })
    // temas dos arquivos (comunidade) completam as cores que faltarem com as do Prisma
    readonly property var palettes: {
        const out = Object.assign({}, builtin)
        const files = ThemeFiles.themes
        for (const id in files) out[id] = Object.assign({}, builtin.prisma, files[id])
        return out
    }

    readonly property var p: palettes[Config.o.theme] ?? palettes["prisma"]

    readonly property color bg: p.bg
    readonly property color text: p.text
    readonly property color muted: p.muted
    readonly property color accent: Config.o.accent !== "" ? Config.o.accent : p.accent
    readonly property color accent2: Config.o.accent2 !== "" ? Config.o.accent2 : p.accent2
    readonly property color hot: p.hot
    readonly property color ok: p.ok
    readonly property color inkOnAccent: "#04121A"

    // Superfícies de vidro (o desfoque vem do Hyprland, via regra de camada)
    readonly property color glassBase: Qt.alpha(p.glass, Config.o.glassOpacity * 0.72)
    readonly property color glass: Qt.alpha(p.glass, Config.o.glassOpacity)
    readonly property color glassFocus: Qt.alpha(Qt.darker(p.glass, 1.15), Math.min(1, Config.o.glassOpacity + 0.14))
    readonly property color stroke: Qt.rgba(1, 1, 1, 0.10)
    readonly property color strokeStrong: Qt.rgba(1, 1, 1, 0.16)
    readonly property color hover: Qt.rgba(1, 1, 1, 0.07)
    readonly property color pressed: Qt.rgba(1, 1, 1, 0.12)

    // Medidas
    readonly property real s: Config.o.scale
    readonly property int radius: Config.o.radius * s
    readonly property int radiusSmall: Math.round(radius * 0.66)
    readonly property int gap: 12 * s
    readonly property int pad: 16 * s
    readonly property int barHeight: 46 * s

    // Fontes
    readonly property string fontDisplay: Config.o.fontDisplay
    readonly property string fontBody: Config.o.fontBody
    readonly property string fontMono: Config.o.fontMono
    readonly property int fs: 14 * s

    // Movimento (curvas da folha de estilo)
    readonly property int durEnter: 380
    readonly property int durExit: 260
    readonly property int durFast: 160
    readonly property var easeEnter: [0.2, 0.8, 0.2, 1, 1, 1]
    readonly property var easeSpring: [0.2, 0.9, 0.3, 1.2, 1, 1]

    function glowColor(c, a) { return Qt.alpha(c, Config.o.glow ? a : 0) }
}
