pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Brilho da tela via brightnessctl.
Singleton {
    id: root
    property real value: 1
    property bool available: false

    function set(v) {
        v = Math.max(0.02, Math.min(1, v))
        value = v
        setter.command = ["brightnessctl", "-q", "set", Math.round(v * 100) + "%"]
        setter.running = true
    }
    function step(d) { set(value + d) }

    Process {
        id: reader
        command: ["brightnessctl", "-m"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(",")
                if (parts.length >= 5) {
                    root.available = true
                    root.value = parseInt(parts[2]) / parseInt(parts[4])
                }
            }
        }
    }
    Process { id: setter }
}
