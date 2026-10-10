import QtQuick
import Quickshell
import Quickshell.Io

// Leitor do sistema: CPU, memória, rede e disco a cada segundo (histórico de 60 amostras),
// temperatura e GPU a cada 2 s, sistemas de arquivos a cada 10 s.
Item {
    id: root
    visible: false
    readonly property int cap: 60

    // Processador
    property string cpuModel: ""
    property real cpu: 0                // 0..1
    property var cores: []              // 0..1 por núcleo
    property var cpuHist: []

    // Memória (KiB)
    property real memTotal: 0
    property real memUsed: 0
    property real swapTotal: 0
    property real swapUsed: 0
    readonly property real mem: memTotal > 0 ? memUsed / memTotal : 0
    readonly property real swap: swapTotal > 0 ? swapUsed / swapTotal : 0
    property var memHist: []

    // Rede e disco (bytes/s)
    property real netDown: 0
    property real netUp: 0
    property var downHist: []
    property var upHist: []
    property real diskRead: 0
    property real diskWrite: 0
    property var readHist: []
    property var writeHist: []
    property var filesystems: []        // [{ target, size, used, pct }]

    // Temperatura (°C, -1 = indisponível) e GPU (0..100, -1 = sem suporte)
    property real temp: -1
    property var tempHist: []
    property string gpuPath: ""
    property real gpu: -1
    property var gpuHist: []

    property real uptime: 0             // segundos
    property var load: []

    // estado anterior para calcular as diferenças
    property var _cpu: null
    property var _net: null
    property var _disk: null

    function push(arr, v) {
        const a = arr.slice(-(cap - 1))
        a.push(v)
        return a
    }

    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            stat.reload(); meminfo.reload(); netdev.reload(); diskstats.reload()
            uptimeFile.reload(); loadavg.reload()
            if (root.gpuPath !== "") gpuFile.reload()
        }
    }
    Timer {
        interval: 2000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: thermal.running = true
    }
    Timer {
        interval: 10000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: df.running = true
    }

    FileView {
        id: cpuinfo
        path: "/proc/cpuinfo"
        onLoaded: {
            const m = text().match(/^(model name|Hardware|Processor)\s*:\s*(.+)$/m)
            root.cpuModel = m ? m[2].replace(/\s+/g, " ").trim() : "Processador"
        }
    }

    FileView {
        id: stat
        path: "/proc/stat"
        onLoaded: {
            const now = []
            for (const l of text().split("\n")) {
                if (!l.startsWith("cpu")) break
                // user nice system idle iowait irq softirq steal (guest já entra em user)
                const v = l.trim().split(/\s+/).slice(1, 9).map(Number)
                const idle = v[3] + (v[4] || 0)
                now.push({ idle: idle, total: v.reduce((a, b) => a + b, 0) })
            }
            const prev = root._cpu
            if (prev && prev.length === now.length) {
                const use = now.map((c, i) => {
                    const dt = c.total - prev[i].total, di = c.idle - prev[i].idle
                    return dt > 0 ? Math.max(0, Math.min(1, 1 - di / dt)) : 0
                })
                root.cpu = use[0]
                root.cores = use.slice(1)
                root.cpuHist = root.push(root.cpuHist, use[0])
            }
            root._cpu = now
        }
    }

    FileView {
        id: meminfo
        path: "/proc/meminfo"
        onLoaded: {
            const m = {}
            for (const l of text().split("\n")) {
                const p = l.split(/:\s+/)
                if (p.length > 1) m[p[0]] = parseInt(p[1])
            }
            root.memTotal = m.MemTotal || 0
            root.memUsed = (m.MemTotal || 0) - (m.MemAvailable ?? m.MemFree ?? 0)
            root.swapTotal = m.SwapTotal || 0
            root.swapUsed = (m.SwapTotal || 0) - (m.SwapFree || 0)
            root.memHist = root.push(root.memHist, root.mem)
        }
    }

    FileView {
        id: netdev
        path: "/proc/net/dev"
        onLoaded: {
            let rx = 0, tx = 0
            for (const l of text().split("\n").slice(2)) {
                const i = l.indexOf(":")
                if (i < 0) continue
                const name = l.slice(0, i).trim()
                if (name === "lo") continue
                const f = l.slice(i + 1).trim().split(/\s+/)
                rx += Number(f[0]) || 0
                tx += Number(f[8]) || 0
            }
            const t = Date.now(), prev = root._net
            if (prev) {
                const dt = (t - prev.t) / 1000
                if (dt > 0) {
                    root.netDown = Math.max(0, (rx - prev.rx) / dt)
                    root.netUp = Math.max(0, (tx - prev.tx) / dt)
                }
                root.downHist = root.push(root.downHist, root.netDown)
                root.upHist = root.push(root.upHist, root.netUp)
            }
            root._net = { t: t, rx: rx, tx: tx }
        }
    }

    FileView {
        id: diskstats
        path: "/proc/diskstats"
        onLoaded: {
            // só discos inteiros (sem partições): sda, vda, nvme0n1, mmcblk0...
            const whole = /^(sd[a-z]+|vd[a-z]+|xvd[a-z]+|hd[a-z]+|nvme\d+n\d+|mmcblk\d+)$/
            let rd = 0, wr = 0
            for (const l of text().split("\n")) {
                const f = l.trim().split(/\s+/)
                if (f.length < 10 || !whole.test(f[2])) continue
                rd += Number(f[5]) * 512      // setores lidos
                wr += Number(f[9]) * 512      // setores escritos
            }
            const t = Date.now(), prev = root._disk
            if (prev) {
                const dt = (t - prev.t) / 1000
                if (dt > 0) {
                    root.diskRead = Math.max(0, (rd - prev.rd) / dt)
                    root.diskWrite = Math.max(0, (wr - prev.wr) / dt)
                }
                root.readHist = root.push(root.readHist, root.diskRead)
                root.writeHist = root.push(root.writeHist, root.diskWrite)
            }
            root._disk = { t: t, rd: rd, wr: wr }
        }
    }

    FileView {
        id: uptimeFile
        path: "/proc/uptime"
        onLoaded: root.uptime = parseFloat(text().split(" ")[0]) || 0
    }

    FileView {
        id: loadavg
        path: "/proc/loadavg"
        onLoaded: root.load = text().trim().split(/\s+/).slice(0, 3).map(Number)
    }

    // GPU: procura uma vez o arquivo de uso (AMD/Intel expõem gpu_busy_percent)
    Process {
        running: true
        command: ["sh", "-c", "ls /sys/class/drm/card*/device/gpu_busy_percent 2>/dev/null | head -n1"]
        stdout: StdioCollector { onStreamFinished: root.gpuPath = text.trim() }
    }
    FileView {
        id: gpuFile
        path: root.gpuPath
        onLoaded: {
            const v = parseInt(text())
            if (isNaN(v)) return
            root.gpu = v
            root.gpuHist = root.push(root.gpuHist, v)
        }
    }

    // Temperatura: maior zona térmica; sem zonas, tenta o `sensors -j`
    Process {
        id: thermal
        command: ["sh", "-c", "t=$(cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null); "
            + "if [ -n \"$t\" ]; then echo \"$t\"; elif command -v sensors >/dev/null; then sensors -j 2>/dev/null; fi"]
        stdout: StdioCollector {
            onStreamFinished: {
                const s = text.trim()
                let max = -1
                if (s.startsWith("{")) {
                    const walk = o => {
                        for (const k in o) {
                            const v = o[k]
                            if (v !== null && typeof v === "object") walk(v)
                            else if (/^temp\d+_input$/.test(k) && v > 0 && v < 150) max = Math.max(max, v)
                        }
                    }
                    try { walk(JSON.parse(s)) } catch (e) {}
                } else {
                    for (const l of s.split("\n")) {
                        const v = parseInt(l) / 1000
                        if (v > 0 && v < 150) max = Math.max(max, v)
                    }
                }
                root.temp = max
                if (max >= 0) root.tempHist = root.push(root.tempHist, max)
            }
        }
    }

    Process {
        id: df
        command: ["df", "-h", "--output=target,size,used,pcent", "-x", "tmpfs", "-x", "devtmpfs", "-x", "efivarfs"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = []
                for (const l of text.trim().split("\n").slice(1)) {
                    const f = l.trim().split(/\s+/)
                    if (f.length < 4) continue
                    const pct = parseInt(f.pop()), used = f.pop(), size = f.pop()
                    out.push({ target: f.join(" "), size: size.replace(".", ","), used: used.replace(".", ","), pct: isNaN(pct) ? 0 : pct })
                }
                root.filesystems = out
            }
        }
    }
}
