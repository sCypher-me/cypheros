pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Atualizações: confere Arch, AUR e Flatpak a cada 2 horas, sem pedir senha.
Singleton {
    id: root
    property var items: []          // [{ name, from, to, source }]
    property bool checking: false
    property bool running: false     // atualizando agora, num terminal
    property bool snapshots: false   // btrfs + snapper: ponto de restauração automático
    property date lastCheck
    readonly property int count: items.length

    function check() {
        if (checking || running) return
        checking = true
        proc.running = true
    }
    function upgrade() {
        if (running) return
        Ui.closeAll()
        running = true
        term.running = true
    }

    Timer { interval: 2 * 60 * 60 * 1000; running: true; repeat: true; onTriggered: root.check() }
    Timer { interval: 90 * 1000; running: true; onTriggered: root.check() }   // logo depois de entrar

    Process {
        command: ["sh", "-c", "[ \"$(findmnt -no FSTYPE /)\" = btrfs ] && [ -f /etc/snapper/configs/root ]"]
        running: true
        onExited: code => root.snapshots = code === 0
    }

    Process {
        id: proc
        command: ["sh", "-c",
            "checkupdates --nocolor 2>/dev/null | sed 's/^/arch /';"
            + "if command -v paru >/dev/null; then paru -Qua 2>/dev/null | sed 's/^/aur /'; elif command -v yay >/dev/null; then yay -Qua 2>/dev/null | sed 's/^/aur /'; fi;"
            + "command -v flatpak >/dev/null && flatpak remote-ls --updates --app --columns=application,version 2>/dev/null | sed 's/^/flatpak /'; true"]
        environment: ({ LC_ALL: "C" })
        stdout: StdioCollector {
            onStreamFinished: {
                const out = []
                for (const l of text.split("\n")) {
                    const p = l.trim().split(/\s+/)
                    if (p.length < 2) continue
                    if (p[0] === "flatpak") out.push({ source: "Flatpak", name: p[1], from: "", to: p[2] ?? "" })
                    else out.push({ source: p[0] === "aur" ? "AUR" : "Arch", name: p[1], from: p[2] ?? "", to: p[4] ?? "" })
                }
                const before = root.items.length
                root.items = out
                root.lastCheck = new Date()
                if (out.length > before && out.length >= 10 && !Config.o.doNotDisturb)
                    Quickshell.execDetached(["notify-send", "-a", "Atualizações", out.length + " atualizações disponíveis", "Clique no ícone da barra para atualizar."])
            }
        }
        onExited: root.checking = false
    }

    Process {
        id: term
        command: ["sh", "-c", "t=cypher-term; command -v $t >/dev/null || t=foot; $t -e sh -c 'cypher atualizar; echo; read -p \"Enter para fechar...\" x'"]
        onExited: { root.running = false; root.items = []; root.check() }
    }
}
