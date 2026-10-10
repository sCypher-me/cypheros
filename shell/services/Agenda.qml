pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Agenda simples: ~/.config/cypheros/agenda.json
Singleton {
    id: root
    property alias events: adapter.events   // [{ date: "2026-10-10", time: "14:00", title: "..." }]

    function key(d) { return Qt.formatDate(d, "yyyy-MM-dd") }
    function on(d) {
        const k = key(d)
        return events.filter(e => e.date === k).sort((a, b) => (a.time || "").localeCompare(b.time || ""))
    }
    function has(d) { const k = key(d); return events.some(e => e.date === k) }
    function add(d, time, title) {
        if (!title.trim()) return
        adapter.events = events.concat([{ date: key(d), time: time.trim(), title: title.trim() }])
    }
    function remove(ev) { adapter.events = events.filter(e => !(e.date === ev.date && e.time === ev.time && e.title === ev.title)) }
    readonly property var upcoming: {
        const today = key(new Date())
        return events.filter(e => e.date >= today).sort((a, b) => (a.date + a.time).localeCompare(b.date + b.time)).slice(0, 3)
    }

    FileView {
        path: Config.dir + "/agenda.json"
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: err => { if (err === FileViewError.FileNotFound) writeAdapter() }
        JsonAdapter {
            id: adapter
            property var events: []
        }
    }
}
