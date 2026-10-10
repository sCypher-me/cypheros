pragma Singleton
import QtQuick
import Quickshell

// Tema por horário: um tema de dia, outro de noite, e luz noturna automática.
// Ligue em config.json › themeAuto (ou pela Central / cypher tema auto).
Singleton {
    id: root
    property string period: ""      // dia | noite

    function minutes(hhmm) { const [h, m] = (hhmm || "0:0").split(":").map(Number); return h * 60 + (m || 0) }
    function current() {
        const d = new Date(), now = d.getHours() * 60 + d.getMinutes()
        const day = minutes(Config.o.dayStart), night = minutes(Config.o.nightStart)
        return (day < night ? now >= day && now < night : !(now >= night && now < day)) ? "dia" : "noite"
    }
    function check() {
        if (!Config.o.themeAuto) { period = ""; return }
        const p = current()
        if (p === period) return
        period = p
        Config.o.theme = p === "dia" ? Config.o.themeDay : Config.o.themeNight
        Config.o.accent = ""; Config.o.accent2 = ""
        if (Config.o.nightLightAuto)
            Quickshell.execDetached(["sh", "-c", p === "noite" ? "pgrep -x hyprsunset || (hyprsunset -t 4500 &)" : "pkill -x hyprsunset"])
    }

    Timer { interval: 30000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.check() }
    Connections {
        target: Config.o
        function onThemeAutoChanged() { root.period = ""; root.check() }
        function onThemeDayChanged() { root.period = ""; root.check() }
        function onThemeNightChanged() { root.period = ""; root.check() }
        function onDayStartChanged() { root.period = ""; root.check() }
        function onNightStartChanged() { root.period = ""; root.check() }
    }
}
