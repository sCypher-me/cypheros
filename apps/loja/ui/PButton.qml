import QtQuick
import QtQuick.Effects
import qs.services
import qs.components

// Botão de texto do Prisma. kind: primary (degradê com brilho) | ghost | danger
Rectangle {
    id: root
    property string text: ""
    property string icon: ""
    property string kind: "ghost"
    property bool big: false
    signal clicked()

    readonly property color fg: kind === "primary" ? Theme.inkOnAccent : kind === "danger" ? Qt.lighter(Theme.hot, 1.25) : Theme.text

    implicitHeight: (big ? 46 : 34) * Theme.s
    implicitWidth: row.implicitWidth + (big ? 36 : 24) * Theme.s
    radius: big ? Theme.radiusSmall + 2 : height / 2
    opacity: enabled ? 1 : 0.45
    color: kind === "primary" ? "transparent"
         : kind === "danger" ? Qt.alpha(Theme.hot, mouse.containsMouse ? 0.24 : 0.14)
         : mouse.pressed ? Theme.pressed : mouse.containsMouse ? Theme.hover : Qt.rgba(1, 1, 1, 0.06)
    border.width: kind === "primary" ? 0 : 1
    border.color: kind === "danger" ? Qt.alpha(Theme.hot, 0.4) : Theme.stroke
    scale: mouse.pressed ? 0.97 : 1

    Accessible.role: Accessible.Button
    Accessible.name: text

    RectangularShadow {
        visible: root.kind === "primary"
        anchors.fill: parent
        radius: root.radius
        blur: mouse.containsMouse ? 26 : 16
        color: Theme.glowColor(Theme.accent, mouse.containsMouse ? 0.45 : 0.28)
        Behavior on blur { NumberAnimation { duration: Theme.durFast } }
    }
    Rectangle {
        visible: root.kind === "primary"
        anchors.fill: parent
        radius: root.radius
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Theme.accent }
            GradientStop { position: 1; color: Theme.accent2 }
        }
        Rectangle { anchors.fill: parent; radius: parent.radius; color: "white"; opacity: mouse.pressed ? 0.12 : mouse.containsMouse ? 0.08 : 0 }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 7 * Theme.s
        Icon { visible: root.icon !== ""; name: root.icon || "logo"; size: (root.big ? 18 : 15) * Theme.s; color: root.fg; anchors.verticalCenter: parent.verticalCenter }
        Label {
            text: root.text
            color: root.fg
            font.pixelSize: (root.big ? 15 : 13) * Theme.s
            font.weight: Font.DemiBold
            anchors.verticalCenter: parent.verticalCenter
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
    Behavior on scale { NumberAnimation { duration: Theme.durFast } }
}
