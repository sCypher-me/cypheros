pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Rede via NetworkManager (nmcli).
Singleton {
    id: root
    property string type: "none"      // wifi | ethernet | none
    property string name: ""
    property int signal: 0
    property bool wifiEnabled: true
    readonly property bool connected: type !== "none"
    readonly property string icon: type === "ethernet" ? "ethernet" : type === "wifi" ? "wifi" : "wifi-off"
    readonly property string label: type === "none" ? "Desconectado" : name

    function toggleWifi() {
        toggler.command = ["nmcli", "radio", "wifi", wifiEnabled ? "off" : "on"]
        toggler.running = true
        wifiEnabled = !wifiEnabled
    }
    function refresh() { dev.running = true; radio.running = true }

    // lista de redes Wi-Fi: [{ ssid, signal, secure, active }]
    property var networks: []
    property bool scanning: false
    property string connectError: ""
    property string connecting: ""
    function scan() { if (!scanner.running) { scanning = true; scanner.running = true } }
    function connectTo(ssid, password) {
        connectError = ""
        connecting = ssid
        joiner.command = password ? ["nmcli", "dev", "wifi", "connect", ssid, "password", password] : ["nmcli", "dev", "wifi", "connect", ssid]
        joiner.running = true
    }

    Timer { interval: 8000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }

    Process {
        id: dev
        command: ["nmcli", "-t", "-f", "TYPE,STATE,CONNECTION", "device"]
        stdout: StdioCollector {
            onStreamFinished: {
                let t = "none", n = ""
                for (const line of text.trim().split("\n")) {
                    const [ty, st, ...rest] = line.split(":")
                    if (st !== "connected") continue
                    if (ty === "ethernet") { t = "ethernet"; n = rest.join(":"); break }
                    if (ty === "wifi") { t = "wifi"; n = rest.join(":") }
                }
                root.type = t
                root.name = n
                if (t === "wifi") sig.running = true
            }
        }
    }
    Process {
        id: sig
        command: ["nmcli", "-t", "-f", "ACTIVE,SIGNAL", "dev", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: {
                for (const line of text.trim().split("\n"))
                    if (line.startsWith("yes:")) root.signal = parseInt(line.split(":")[1])
            }
        }
    }
    Process {
        id: radio
        command: ["nmcli", "radio", "wifi"]
        stdout: StdioCollector { onStreamFinished: root.wifiEnabled = text.trim() === "enabled" }
    }
    Process { id: toggler; onExited: root.refresh() }
    Process {
        id: scanner
        command: ["nmcli", "-t", "-f", "IN-USE,SIGNAL,SECURITY,SSID", "dev", "wifi", "list", "--rescan", "auto"]
        stdout: StdioCollector {
            onStreamFinished: {
                const seen = {}
                const list = []
                for (const line of text.trim().split("\n")) {
                    if (!line) continue
                    // SSID pode ter ":" escapado como "\:"
                    const parts = line.replace(/\\:/g, "\u0001").split(":").map(p => p.replace(/\u0001/g, ":"))
                    const [inUse, sig, sec, ...rest] = parts
                    const ssid = rest.join(":")
                    if (!ssid || seen[ssid]) continue
                    seen[ssid] = true
                    list.push({ ssid, signal: parseInt(sig) || 0, secure: sec !== "" && sec !== "--", active: inUse === "*" })
                }
                list.sort((a, b) => (b.active - a.active) || (b.signal - a.signal))
                root.networks = list
                root.scanning = false
            }
        }
    }
    Process {
        id: joiner
        stderr: StdioCollector { id: joinErr }
        onExited: code => {
            if (code !== 0) root.connectError = joinErr.text.indexOf("Secrets") >= 0 || joinErr.text.indexOf("password") >= 0 ? "Senha incorreta" : "Não foi possível conectar"
            root.connecting = ""
            root.refresh()
            root.scan()
        }
    }
}
