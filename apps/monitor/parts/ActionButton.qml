import QtQuick
import qs.services
import qs.components

// Botão com texto (e ícone opcional) usado nas ações do monitor.
Rectangle {
    id: root
    property string text: ""
    property string icon: ""
    property color tint: Theme.accent
    property bool filled: false
    signal clicked()

    implicitWidth: row.implicitWidth + 24 * Theme.s
    implicitHeight: 34 * Theme.s
    radius: Theme.radiusSmall
    opacity: enabled ? 1 : 0.4
    color: filled ? (mouse.containsMouse ? Qt.lighter(tint, 1.1) : tint)
                  : mouse.pressed ? Qt.alpha(tint, 0.28) : mouse.containsMouse ? Qt.alpha(tint, 0.2) : Qt.alpha(tint, 0.12)
    border.width: filled ? 0 : 1
    border.color: Qt.alpha(tint, 0.35)

    Accessible.role: Accessible.Button
    Accessible.name: text

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 7 * Theme.s
        Icon {
            visible: root.icon !== ""
            anchors.verticalCenter: parent.verticalCenter
            name: root.icon
            size: 15 * Theme.s
            color: root.filled ? Theme.inkOnAccent : root.tint
        }
        Label {
            anchors.verticalCenter: parent.verticalCenter
            text: root.text
            font.pixelSize: 13 * Theme.s
            font.weight: Font.DemiBold
            color: root.filled ? Theme.inkOnAccent : Qt.lighter(root.tint, 1.2)
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    Behavior on color { ColorAnimation { duration: Theme.durFast } }
}
