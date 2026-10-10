import QtQuick
import QtQuick.Effects
import qs.services
import qs.components

// Item da barra lateral.
Rectangle {
    id: root
    property string icon: "apps"
    property string text: ""
    property string hint: ""
    property bool selected: false
    signal clicked()

    implicitHeight: 42 * Theme.s
    radius: Theme.radiusSmall
    color: selected ? Qt.alpha(Theme.accent, 0.13) : mouse.containsMouse ? Theme.hover : "transparent"
    border.width: selected ? 1 : 0
    border.color: Qt.alpha(Theme.accent, 0.35)

    Accessible.role: Accessible.PageTab
    Accessible.name: text

    // marcador luminoso do item ativo
    Rectangle {
        visible: root.selected
        anchors { left: parent.left; leftMargin: 4 * Theme.s; verticalCenter: parent.verticalCenter }
        width: 3; height: parent.height * 0.45; radius: 2
        color: Theme.accent
        RectangularShadow { z: -1; anchors.fill: parent; radius: 2; blur: 10; color: Theme.glowColor(Theme.accent, 0.7) }
    }

    Row {
        anchors { left: parent.left; leftMargin: 16 * Theme.s; verticalCenter: parent.verticalCenter }
        spacing: 12 * Theme.s
        Icon {
            anchors.verticalCenter: parent.verticalCenter
            name: root.icon
            size: 17 * Theme.s
            color: root.selected ? Theme.accent : Theme.muted
        }
        Label {
            anchors.verticalCenter: parent.verticalCenter
            text: root.text
            font.weight: root.selected ? Font.DemiBold : Font.Normal
            color: root.selected ? Theme.text : Qt.lighter(Theme.muted, 1.1)
        }
    }
    Label {
        anchors { right: parent.right; rightMargin: 12 * Theme.s; verticalCenter: parent.verticalCenter }
        text: root.hint
        kind: "mono"
        font.pixelSize: 11 * Theme.s
        color: Theme.muted
        opacity: mouse.containsMouse || root.selected ? 0.8 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.durFast } }
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
