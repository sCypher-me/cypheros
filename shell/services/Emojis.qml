pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Lista de emojis com nomes em português (/usr/share/cypheros/emojis.json).
Singleton {
    id: root
    property var all: []        // [[emoji, nome-pt, nome-en]]
    property var recent: []

    function search(q) {
        q = q.trim().toLowerCase()
        if (q === "") return recent.concat(all.filter(e => !recent.includes(e))).slice(0, 120)
        return all.filter(e => e[1].includes(q) || e[2].includes(q)).slice(0, 120)
    }
    function pick(e) {
        recent = [e].concat(recent.filter(r => r !== e)).slice(0, 16)
        Quickshell.execDetached(["wl-copy", e[0]])
        // digita direto no app aberto, se o wtype estiver instalado
        Quickshell.execDetached(["sh", "-c", "sleep 0.25; command -v wtype >/dev/null && wtype \"$1\"", "sh", e[0]])
    }

    FileView {
        path: "/usr/share/cypheros/emojis.json"
        onLoaded: { try { root.all = JSON.parse(text()) } catch (e) { } }
    }
}
