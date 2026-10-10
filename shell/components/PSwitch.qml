import QtQuick
import QtQuick.Effects
import qs.services

// Interruptor Prisma: trilho de vidro, ligado vira degradê com brilho.
Item {
    id: root
    property bool checked: false
    signal toggled(bool v)
    implicitWidth: 46 * Theme.s
    implicitHeight: 26 * Theme.s

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? "transparent" : Qt.rgba(1, 1, 1, 0.12)
        gradient: root.checked ? grad : null
        Gradient { id: grad; orientation: Gradient.Horizontal; GradientStop { position: 0; color: Theme.accent } GradientStop { position: 1; color: Theme.accent2 } }
        RectangularShadow { z: -1; anchors.fill: parent; radius: parent.radius; blur: 14; visible: root.checked; color: Theme.glowColor(Theme.accent, 0.35) }
    }
    Rectangle {
        width: parent.height - 6 * Theme.s; height: width; radius: width / 2
        anchors.verticalCenter: parent.verticalCenter
        x: root.checked ? parent.width - width - 3 * Theme.s : 3 * Theme.s
        color: root.checked ? Theme.inkOnAccent : Theme.text
        Behavior on x { NumberAnimation { duration: Theme.durFast + 60; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easeSpring } }
    }
    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.toggled(!root.checked) }
}
