pragma Singleton
import QtQuick
import Quickshell
import qs.services

// Grava ~/.config/hypr/central.conf com tela, teclado e mouse escolhidos na Central e recarrega o Hyprland.
Singleton {
    id: root
    function build() {
        const o = Config.o
        let s = "# Gerado pela Central CypherOS. Mude pela Central; para ajustes manuais use usuario.conf.\n\n"
        const mons = o.monitors ?? {}
        for (const name of Object.keys(mons)) {
            const m = mons[name]
            s += "monitor = " + name + ", " + (m.mode || "preferred") + ", auto, " + (m.scale || 1) + "\n"
        }
        s += "\ninput {\n"
            + "    kb_layout = " + (o.kbLayout || "br") + "\n"
            + "    kb_variant = " + (o.kbVariant || "") + "\n"
            + "    sensitivity = " + Number(o.mouseSensitivity || 0).toFixed(2) + "\n"
            + "    touchpad {\n"
            + "        natural_scroll = " + (o.naturalScroll ? "true" : "false") + "\n"
            + "        tap-to-click = " + (o.tapToClick ? "true" : "false") + "\n"
            + "    }\n}\n"
        return s
    }
    function apply() { saver.restart() }
    Timer {
        id: saver
        interval: 500
        onTriggered: Quickshell.execDetached(["sh", "-c", "printf '%s' \"$1\" > \"$HOME/.config/hypr/central.conf\" && hyprctl reload >/dev/null", "sh", root.build()])
    }
}
