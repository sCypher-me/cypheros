pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Busca universal: arquivos da pasta pessoal e histórico de comandos do terminal.
Singleton {
    id: root
    property var files: []       // [path]
    property var history: []     // [comando]
    property string _q: ""
    readonly property string home: Quickshell.env("HOME")

    function query(q) {
        _q = q
        if (q.length < 3) { files = []; return }
        debounce.restart()
    }
    function historyMatches(q) {
        if (q.length < 2) return []
        q = q.toLowerCase()
        return history.filter(c => c.toLowerCase().includes(q)).slice(0, 5)
    }

    Timer {
        id: debounce
        interval: 220
        onTriggered: {
            finder.running = false
            finder.command = ["fd", "--max-results", "8", "--max-depth", "6", "--ignore-case", "--fixed-strings", root._q, root.home]
            finder.running = true
        }
    }
    Process {
        id: finder
        stdout: StdioCollector { onStreamFinished: root.files = text.split("\n").filter(l => l !== "") }
    }

    // histórico do zsh (carrega quando o lançador abre)
    function loadHistory() { hist.reload() }
    FileView {
        id: hist
        path: root.home + "/.zsh_history"
        onLoaded: {
            const seen = {}, out = []
            const lines = text().split("\n")
            for (let i = lines.length - 1; i >= 0 && out.length < 500; i--) {
                const c = lines[i].replace(/^: \d+:\d+;/, "").trim()
                if (c && !seen[c]) { seen[c] = true; out.push(c) }
            }
            root.history = out
        }
    }
}
