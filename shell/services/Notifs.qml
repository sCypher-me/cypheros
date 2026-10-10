pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Servidor de notificações próprio do CypherOS (substitui mako/dunst).
Singleton {
    id: root
    readonly property var history: server.trackedNotifications.values
    readonly property int count: history.length
    property list<QtObject> popups: []

    function dismissPopup(n) { popups = popups.filter(p => p !== n) }
    function clearAll() {
        for (const n of history.slice()) n.dismiss()
        popups = []
    }

    NotificationServer {
        id: server
        keepOnReload: true
        actionsSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: n => {
            n.tracked = true
            const urgent = n.urgency === NotificationUrgency.Critical
            if (!Config.o.doNotDisturb || urgent) {
                root.popups = [n, ...root.popups].slice(0, 4)
                Sounds.play("notificacao")
            }
            n.closed.connect(() => root.dismissPopup(n))
        }
    }
}
