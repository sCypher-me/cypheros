pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Histórico da área de transferência (cliphist).
Singleton {
    id: root
    property var items: []      // [{ id, text, image }]

    function refresh() { lister.running = true }
    function copy(item) { Quickshell.execDetached(["sh", "-c", "cliphist decode \"$1\" | wl-copy", "sh", item.id]) }
    function remove(item) {
        Quickshell.execDetached(["sh", "-c", "printf '%s' \"$1\" | cliphist delete", "sh", item.id + "\t" + item.raw])
        items = items.filter(i => i.id !== item.id)
    }
    function clear() { Quickshell.execDetached(["cliphist", "wipe"]); items = [] }

    Process {
        id: lister
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = []
                for (const line of text.split("\n")) {
                    const tab = line.indexOf("\t")
                    if (tab < 0) continue
                    const raw = line.slice(tab + 1)
                    const image = raw.startsWith("[[ binary data")
                    out.push({ id: line.slice(0, tab), raw, image, text: image ? "Imagem copiada" : raw.trim() })
                    if (out.length >= 80) break
                }
                root.items = out
            }
        }
    }
}
