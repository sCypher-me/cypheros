import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import qs.services
import qs.components

// Notificações que aparecem no canto da tela.
PanelWindow {
    id: win
    visible: Notifs.popups.length > 0
    color: "transparent"
    anchors { top: Config.o.barPosition !== "bottom"; bottom: Config.o.barPosition === "bottom"; right: true }
    margins { top: 8 * Theme.s; bottom: 8 * Theme.s; right: (Ui.controlOpen ? 424 : 16) * Theme.s }
    implicitWidth: 360 * Theme.s
    implicitHeight: Math.max(1, col.implicitHeight)
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0
    WlrLayershell.namespace: "cypheros-notifications"
    WlrLayershell.layer: WlrLayer.Overlay

    ColumnLayout {
        id: col
        width: parent.width
        spacing: 10 * Theme.s

        Repeater {
            model: Notifs.popups
            delegate: Item {
                id: slot
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: glass.height

                Glass {
                    id: glass
                    level: 1
                    radius: 16 * Theme.s
                    width: parent.width
                    height: card.implicitHeight
                    opacity: 0
                    y: 16
                    Component.onCompleted: { opacity = 1; y = 0 }
                    Behavior on opacity { NumberAnimation { duration: 420; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easeSpring } }
                    Behavior on y { NumberAnimation { duration: 420; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easeSpring } }

                    NotificationCard {
                        id: card
                        width: parent.width
                        notif: slot.modelData
                        popup: true
                        onClosed: Notifs.dismissPopup(slot.modelData)
                    }

                    // barra de tempo restante
                    Rectangle {
                        visible: !card.critical
                        anchors { left: parent.left; bottom: parent.bottom; leftMargin: 14 * Theme.s; bottomMargin: 6 * Theme.s }
                        height: 2
                        radius: 1
                        color: Qt.alpha(Theme.accent, 0.6)
                        width: (parent.width - 28 * Theme.s) * life.remaining
                    }

                    MouseArea {
                        id: hover
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton
                    }
                }

                QtObject {
                    id: life
                    property real remaining: 1
                }
                NumberAnimation {
                    target: life; property: "remaining"; from: 1; to: 0
                    duration: slot.modelData.expireTimeout > 0 ? slot.modelData.expireTimeout * 1000 : Config.o.notificationTimeout
                    running: !card.critical
                    paused: hover.containsMouse
                    onFinished: Notifs.dismissPopup(slot.modelData)
                }
            }
        }
    }
}
