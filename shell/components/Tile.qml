import QtQuick
import QtQuick.Effects
import qs.services

// Bloco de atalho do painel (Wi-Fi, Bluetooth, Não perturbe...).
Rectangle {
    id: root
    property string icon: "wifi"
    property string title: ""
    property string subtitle: ""
    property bool on: false
    property color tint: Theme.accent
    signal clicked()
    signal rightClicked()

    implicitHeight: 62 * Theme.s
    radius: Theme.radiusSmall + 4
    color: on ? Qt.alpha(tint, 0.16) : mouse.containsMouse ? Theme.hover : Qt.rgba(1, 1, 1, 0.06)
    border.width: on ? 1 : 0
    border.color: Qt.alpha(tint, 0.45)

    RectangularShadow {
        z: -1
        anchors.fill: parent
        radius: parent.radius
        blur: 22
        visible: root.on
        color: Theme.glowColor(root.tint, 0.18)
    }

    Row {
        anchors { left: parent.left; leftMargin: 14 * Theme.s; verticalCenter: parent.verticalCenter }
        spacing: 12 * Theme.s
        Icon {
            anchors.verticalCenter: parent.verticalCenter
            name: root.icon
            color: root.on ? root.tint : Theme.muted
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            Label { text: root.title; font.weight: Font.DemiBold; width: root.width - 64 * Theme.s }
            Label { text: root.subtitle; kind: "muted"; visible: text !== ""; width: root.width - 64 * Theme.s }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: m => m.button === Qt.RightButton ? root.rightClicked() : root.clicked()
    }

    Behavior on color { ColorAnimation { duration: Theme.durFast } }
}
