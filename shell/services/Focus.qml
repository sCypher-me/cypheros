pragma Singleton
import QtQuick
import Quickshell

// Modo foco: esconde barra e dock, silencia notificações e roda um Pomodoro.
Singleton {
    id: root
    property bool active: false
    property bool inBreak: false
    property int remaining: 0          // segundos
    property int rounds: 0
    property bool _dndBefore: false

    readonly property string label: {
        const m = Math.floor(remaining / 60), s = remaining % 60
        return (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s
    }

    function start() {
        if (active) return
        _dndBefore = Config.o.doNotDisturb
        Config.o.doNotDisturb = true
        inBreak = false
        rounds = 0
        remaining = Config.o.focusMinutes * 60
        active = true
        Sounds.play("foco")
    }
    function stop() {
        if (!active) return
        active = false
        Config.o.doNotDisturb = _dndBefore
        Sounds.play("desbloquear")
    }
    function toggle() { active ? stop() : start() }

    Timer {
        interval: 1000
        repeat: true
        running: root.active
        onTriggered: {
            if (--root.remaining > 0) return
            if (root.inBreak) {
                root.inBreak = false
                root.remaining = Config.o.focusMinutes * 60
                Quickshell.execDetached(["notify-send", "-u", "critical", "-a", "Modo foco", "De volta ao foco", Config.o.focusMinutes + " minutos de concentração."])
            } else {
                root.rounds++
                root.inBreak = true
                root.remaining = Config.o.breakMinutes * 60
                Quickshell.execDetached(["notify-send", "-u", "critical", "-a", "Modo foco", "Hora da pausa", "Você completou " + root.rounds + (root.rounds === 1 ? " ciclo." : " ciclos.") + " Descanse " + Config.o.breakMinutes + " minutos."])
            }
            Sounds.play("notificacao")
        }
    }
}
