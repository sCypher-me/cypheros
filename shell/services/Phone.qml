pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Celular via KDE Connect: bateria, tocar o celular, mandar arquivos e textos.
// No celular, instale o app "KDE Connect" e pareie pela Central › Celular.
Singleton {
    id: root
    property bool available: false
    property var devices: []          // [{ id, name, paired, reachable }]
    readonly property var current: devices.find(d => d.paired && d.reachable) ?? null
    property int battery: -1
    property bool charging: false

    function refresh() { if (available) list.running = true }
    function cli(args) { Quickshell.execDetached(["kdeconnect-cli"].concat(args)) }
    function ring() { if (current) cli(["-d", current.id, "--ring"]) }
    function ping() { if (current) cli(["-d", current.id, "--ping-msg", "Oi do CypherOS"]) }
    function share(path) { if (current) cli(["-d", current.id, "--share", path]) }
    function sendClipboard() {
        if (current) Quickshell.execDetached(["sh", "-c", "kdeconnect-cli -d \"$1\" --share-text \"$(wl-paste -n)\"", "sh", current.id])
    }
    function pair(id) { cli(["-d", id, "--pair"]); later.restart() }
    function unpair(id) { cli(["-d", id, "--unpair"]); later.restart() }
    function scan() { cli(["--refresh"]); later.restart() }

    Process {
        command: ["sh", "-c", "command -v kdeconnect-cli"]
        running: true
        onExited: code => { root.available = code === 0; root.refresh() }
    }
    Timer { interval: 30000; running: root.available; repeat: true; onTriggered: root.refresh() }
    Timer { id: later; interval: 2500; onTriggered: root.refresh() }

    Process {
        id: list
        command: ["kdeconnect-cli", "-l"]
        environment: ({ LC_ALL: "C" })
        stdout: StdioCollector {
            onStreamFinished: {
                const out = []
                for (const l of text.split("\n")) {
                    const m = l.match(/^- (.*): (\S+) \((.*)\)\s*$/)
                    if (!m) continue
                    out.push({ name: m[1], id: m[2], paired: m[3].includes("paired"), reachable: m[3].includes("reachable") })
                }
                root.devices = out
                if (root.current) bat.running = true
                else root.battery = -1
            }
        }
    }
    Process {
        id: bat
        command: ["sh", "-c", "p=/modules/kdeconnect/devices/$1/battery; i=org.kde.kdeconnect.device.battery;"
            + "busctl --user get-property org.kde.kdeconnect $p $i charge; busctl --user get-property org.kde.kdeconnect $p $i isCharging",
            "sh", root.current?.id ?? ""]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.trim().split("\n")
                const c = parseInt((l[0] ?? "").split(" ")[1])
                root.battery = isNaN(c) ? -1 : c
                root.charging = (l[1] ?? "").includes("true")
            }
        }
    }
}
