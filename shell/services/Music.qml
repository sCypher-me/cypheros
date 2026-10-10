pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

// Lê o espectro do som (cava) para o wallpaper dançar com a música.
// Só roda quando algo está tocando e a opção wallpaperMusic está ligada.
Singleton {
    id: root
    property var bars: Array(16).fill(0)      // 0..1, graves à esquerda
    readonly property real bass: (bars[0] + bars[1] + bars[2] + bars[3]) / 4
    readonly property real mid: (bars[5] + bars[6] + bars[7] + bars[8] + bars[9]) / 5
    readonly property real treble: (bars[11] + bars[12] + bars[13] + bars[14]) / 4
    readonly property real level: bars.reduce((a, b) => a + b, 0) / 16

    readonly property bool playing: Mpris.players.values.some(p => p.isPlaying)
    readonly property bool wanted: Config.o.wallpaperMusic && Config.o.wallpaperMode === "shader" && playing && !Game.active

    function v4(i) { return Qt.vector4d(bars[i], bars[i + 1], bars[i + 2], bars[i + 3]) }

    onWantedChanged: if (!wanted) fade.start()
    Timer {
        id: fade
        interval: 16; repeat: true
        onTriggered: {
            const b = root.bars.map(v => v * 0.85)
            root.bars = b
            if (b.every(v => v < 0.01)) { root.bars = Array(16).fill(0); stop() }
        }
    }

    Process {
        running: root.wanted
        command: ["cava", "-p", "/usr/share/cypheros/cava.conf"]
        stdout: SplitParser {
            onRead: line => {
                const v = line.split(";").filter(s => s !== "").map(s => Math.min(1, parseInt(s) / 1000))
                if (v.length >= 16) root.bars = v.slice(0, 16)
            }
        }
    }
}
