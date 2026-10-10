pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Temas extras em arquivos JSON: os que vêm com o sistema (/usr/share/cypheros/temas)
// e os que você instalou da loja de temas (~/.config/cypheros/temas).
Singleton {
    id: root
    property var themes: ({})        // id → { name, author, bg, glass, ..., user: bool }

    function reload() { proc.running = true }
    Timer { interval: 15000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.reload() }

    Process {
        id: proc
        command: ["sh", "-c", "for f in /usr/share/cypheros/temas/*.json \"$HOME\"/.config/cypheros/temas/*.json; do [ -f \"$f\" ] || continue;"
            + " case \"$f\" in \"$HOME\"*) u=true;; *) u=false;; esac;"
            + " jq -c --arg id \"$(basename \"$f\" .json)\" --argjson u $u '. + {id: $id, user: $u}' \"$f\" 2>/dev/null; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = {}
                for (const l of text.split("\n")) {
                    try {
                        const t = JSON.parse(l)
                        if (t.id && /^#[0-9a-fA-F]{6}$/.test(t.bg ?? "") && /^#[0-9a-fA-F]{6}$/.test(t.accent ?? "")) out[t.id] = t
                    } catch (e) { }
                }
                if (JSON.stringify(out) !== JSON.stringify(root.themes)) root.themes = out
            }
        }
    }
}
