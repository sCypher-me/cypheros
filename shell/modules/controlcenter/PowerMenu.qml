import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components

// Menu de energia: aparece no centro com fundo escuro.
Item {
    anchors.fill: parent
    visible: opacity > 0
    opacity: Ui.powerOpen ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: Theme.durEnter } }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0.016, 0.024, 0.055, 0.6)
        MouseArea { anchors.fill: parent; onClicked: Ui.powerOpen = false }
    }

    Glass {
        level: 2
        anchors.centerIn: parent
        width: row.implicitWidth + 48 * Theme.s
        height: row.implicitHeight + 48 * Theme.s
        radius: 24 * Theme.s
        scale: Ui.powerOpen ? 1 : 0.94
        Behavior on scale { NumberAnimation { duration: 320; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easeEnter } }

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 14 * Theme.s
            Repeater {
                model: [
                    { icon: "lock", label: "Bloquear", run: () => Power.lock() },
                    { icon: "sleep", label: "Suspender", run: () => Power.suspend() },
                    { icon: "logout", label: "Sair", run: () => Power.logout() },
                    { icon: "restart", label: "Reiniciar", run: () => Power.reboot() },
                    { icon: "power", label: "Desligar", run: () => Power.poweroff() }
                ]
                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    width: 104 * Theme.s; height: 104 * Theme.s
                    radius: 20 * Theme.s
                    readonly property bool danger: index === 4
                    color: m.containsMouse ? (danger ? Qt.alpha(Theme.hot, 0.2) : Qt.alpha(Theme.accent, 0.14)) : Qt.rgba(1, 1, 1, 0.05)
                    border.width: m.containsMouse ? 1 : 0
                    border.color: danger ? Qt.alpha(Theme.hot, 0.5) : Qt.alpha(Theme.accent, 0.45)
                    Column {
                        anchors.centerIn: parent
                        spacing: 10 * Theme.s
                        Icon { anchors.horizontalCenter: parent.horizontalCenter; name: parent.parent.modelData.icon; size: 26 * Theme.s; color: parent.parent.danger ? Theme.hot : Theme.accent }
                        Label { anchors.horizontalCenter: parent.horizontalCenter; text: parent.parent.modelData.label }
                    }
                    MouseArea { id: m; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { Ui.closeAll(); parent.modelData.run() } }
                    Behavior on color { ColorAnimation { duration: Theme.durFast } }
                }
            }
        }
    }
}
