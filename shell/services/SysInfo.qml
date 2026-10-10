pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// CPU, memória, disco e tempo ligado.
Singleton {
    id: root
    property real cpu: 0
    property real memUsed: 0      // GB
    property real memTotal: 1
    property real disk: 0         // 0..1
    property string uptime: ""
    property var _lastCpu: null

    readonly property real mem: memUsed / memTotal

    Timer {
        interval: 2000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: { stat.reload(); meminfo.reload(); up.reload() }
    }
    Timer {
        interval: 60000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: df.running = true
    }

    FileView {
        id: stat
        path: "/proc/stat"
        onLoaded: {
            const v = text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number)
            const idle = v[3] + v[4], total = v.reduce((a, b) => a + b, 0)
            if (root._lastCpu) {
                const dt = total - root._lastCpu.total, di = idle - root._lastCpu.idle
                if (dt > 0) root.cpu = 1 - di / dt
            }
            root._lastCpu = { idle, total }
        }
    }
    FileView {
        id: meminfo
        path: "/proc/meminfo"
        onLoaded: {
            const m = {}
            for (const l of text().split("\n")) { const p = l.split(/:\s+/); if (p.length > 1) m[p[0]] = parseInt(p[1]) }
            root.memTotal = m.MemTotal / 1048576
            root.memUsed = (m.MemTotal - m.MemAvailable) / 1048576
        }
    }
    FileView {
        id: up
        path: "/proc/uptime"
        onLoaded: {
            const s = parseFloat(text().split(" ")[0])
            const h = Math.floor(s / 3600), min = Math.floor((s % 3600) / 60)
            root.uptime = h > 0 ? `${h}h ${min}min` : `${min}min`
        }
    }
    Process {
        id: df
        command: ["df", "--output=pcent", "/"]
        stdout: StdioCollector {
            onStreamFinished: root.disk = parseInt(text.trim().split("\n").pop()) / 100
        }
    }
}
