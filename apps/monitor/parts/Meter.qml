import QtQuick
import qs.services

// Barra fina de uso (0..1) com degradê e brilho suave.
Rectangle {
    id: root
    property real value: 0
    property color tint: Theme.accent
    property color tint2: Theme.accent2

    implicitHeight: 6 * Theme.s
    radius: height / 2
    color: Qt.rgba(1, 1, 1, 0.08)

    Rectangle {
        height: parent.height
        radius: parent.radius
        width: Math.max(height, parent.width * Math.max(0, Math.min(1, root.value)))
        visible: root.value > 0
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: root.tint }
            GradientStop { position: 1; color: root.tint2 }
        }
        Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
    }
}
