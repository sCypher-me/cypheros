import QtQuick
import qs.services

// Botão redondo/quadrado só com ícone.
Rectangle {
    id: root
    property string icon: "logo"
    property color iconColor: Theme.text
    property bool active: false
    property color activeColor: Theme.accent
    property real iconSize: 18 * Theme.s
    property string tooltip: ""
    signal clicked()

    implicitWidth: 40 * Theme.s
    implicitHeight: 40 * Theme.s
    radius: Theme.radiusSmall
    color: active ? Qt.alpha(activeColor, 0.18) : mouse.pressed ? Theme.pressed : mouse.containsMouse ? Theme.hover : Qt.rgba(1, 1, 1, 0.05)
    border.width: active ? 1 : 0
    border.color: Qt.alpha(activeColor, 0.5)

    Accessible.role: Accessible.Button
    Accessible.name: tooltip

    Icon {
        anchors.centerIn: parent
        name: root.icon
        size: root.iconSize
        color: root.active ? root.activeColor : root.iconColor
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
